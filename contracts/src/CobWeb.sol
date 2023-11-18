// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IMessageRecipient} from "@hyperlane/v3/interfaces/IMessageRecipient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IChronicle} from "@chronicle/contracts/IChronicle.sol";
import {IChronicle} from "@chronicle/contracts/IChronicle.sol";
import {Utils} from "./utils.sol";
import {ISelfKisser} from "./ISelfKisser.sol";
import {IInterchainGasPaymaster} from "@hyperlane/v3/interfaces/IInterchainGasPaymaster.sol";
import {IMailbox} from "@hyperlane/v3/interfaces/IMailbox.sol";

contract CobWeb is IMessageRecipient {
    using Utils for uint;

    struct Order {
        uint256 sourceId;
        address sender;
        uint256 amountIn;
        uint256 amountOut;
        address fromToken;
        address toToken;
        uint32 fromChain;
        uint32 toChain;
        uint256 deadline;
        uint256 maxSlippage;
        bool filled;
        address[] fillers;
        uint256[] fills;
    }

    Order[] public pendingIncomingOrders;
    Order[] private outgoing;

    mapping(address => address) tokenToOracle;

    uint256[] public chains;

    constructor(
        address mailbox,
        address selfKisser,
        address[] memory _tokens,
        address[] memory _oracles,
        uint256[] memory _chains
    ) {
        require(_tokens.length == _oracles.length, "Length mismatch");

        _mailbox = mailbox;
        chains = _chains;

        for (uint256 i = 0; i < _oracles.length; i++) {
            ISelfKisser(selfKisser).selfKiss(_oracles[i], address(this));
        }

        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenToOracle[_tokens[i]] = _oracles[i];
        }
    }

    address immutable _mailbox;

    IInterchainGasPaymaster igp =
        IInterchainGasPaymaster(0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a);

    // for access control on handle implementations
    modifier onlyMailbox() {
        require(msg.sender == _mailbox, "Only Mailbox");
        _;
    }

    function bridge(
        uint256 sourceId,
        uint256 amountIn,
        address fromToken,
        address toToken,
        uint32 fromChain,
        uint32 toChain,
        uint256 deadline,
        uint256 maxSlippage
    ) external {
        Order memory order = Order(
            sourceId,
            msg.sender,
            amountIn,
            amountIn,
            fromToken,
            toToken,
            fromChain,
            toChain,
            deadline,
            maxSlippage,
            false,
            new address[](0),
            new uint256[](0)
        );

        uint256 fromPrice = IChronicle(tokenToOracle[order.fromToken]).read();
        uint256 toPrice = IChronicle(tokenToOracle[order.toToken]).read();

        if (order.fromToken != order.toToken) {
            // oracle provided rate
            order.amountOut = (fromPrice * order.amountIn) / toPrice;
        }

        for (uint256 k = 0; k < chains.length; k++) {
            Order[] memory ordersToBroadcast;

            for (uint i = 0; i < pendingIncomingOrders.length; i++) {
                uint256 newAmountOut = (pendingIncomingOrders[i].amountIn *
                    fromPrice) / toPrice;

                if ((pendingIncomingOrders[i].amountOut > newAmountOut)) {
                    uint256 slippage = pendingIncomingOrders[i].amountOut -
                        newAmountOut;
                    if (slippage > pendingIncomingOrders[i].maxSlippage) {
                        // we don't fill this order
                        continue;
                    }
                }

                if (
                    pendingIncomingOrders[i].fromToken == order.toToken &&
                    pendingIncomingOrders[i].toToken == order.fromToken &&
                    pendingIncomingOrders[i].fromChain == order.toChain &&
                    pendingIncomingOrders[i].toChain == order.fromChain &&
                    pendingIncomingOrders[i].filled == false &&
                    pendingIncomingOrders[i].deadline < block.timestamp &&
                    pendingIncomingOrders[i].fromChain == chains[k]
                ) {
                    uint256 deltaFilledIn = Utils.min(
                        order.amountIn,
                        pendingIncomingOrders[i].amountOut
                    );

                    uint256 deltaFilledOut = Utils.min(
                        order.amountOut,
                        pendingIncomingOrders[i].amountIn
                    );

                    // we fill whatever we can
                    IERC20(order.fromToken).transferFrom(
                        msg.sender,
                        pendingIncomingOrders[i].sender,
                        deltaFilledIn
                    );

                    order.amountIn -= deltaFilledIn;
                    order.amountOut -= deltaFilledOut;

                    pendingIncomingOrders[i].fillers.push(msg.sender);
                    pendingIncomingOrders[i].fills.push(deltaFilledIn);

                    if (
                        pendingIncomingOrders[i].amountIn == 0 &&
                        pendingIncomingOrders[i].amountOut == 0
                    ) {
                        pendingIncomingOrders[i].filled = true;
                        ordersToBroadcast[
                            ordersToBroadcast.length
                        ] = pendingIncomingOrders[i];
                    }
                }
            }

            if (order.toChain == chains[k]) {
                if (!order.filled && order.amountIn != 0) {
                    // we transfer our pending origin to the contract
                    IERC20(order.fromToken).transferFrom(
                        msg.sender,
                        address(this),
                        order.amountIn
                    );
                }

                ordersToBroadcast[ordersToBroadcast.length] = order;

                // broadcast orders
            }
            if (ordersToBroadcast.length > 0) {
                _broadcast(ordersToBroadcast);
            }
        }
    }

    function _broadcast(Order[] memory orders) private returns (bytes32) {
        uint256 quote = IMailbox(_mailbox).quoteDispatch(
            orders[0].toChain,
            _addressToBytes32(address(this)),
            bytes(abi.encode(orders))
        );
        bytes32 messageId = IMailbox(_mailbox).dispatch{value: quote}(
            orders[0].toChain,
            _addressToBytes32(address(this)),
            bytes(abi.encode(orders))
        );

        return messageId;
    }

    function defaultToBridge(uint256 orderSourceId) public view {
        if (
            pendingIncomingOrders[orderSourceId].filled == false &&
            pendingIncomingOrders[orderSourceId].deadline > block.timestamp
        ) {
            // we don't cob anymore and just bridge
            // swap token with 1inch
            // bridge with Hyperlane(?)
        }
    }

    function handle(
        uint32 _origin,
        bytes32,
        bytes calldata _body
    ) external payable override onlyMailbox {
        Order[] memory orders = abi.decode(_body, (Order[]));

        // handle transfers for filled orders
        for (uint i = 0; i < orders.length; i++) {
            if (orders[i].filled == true && orders[i].toChain == _origin) {
                // we transfer to the person who filled our order
                for (uint j = 0; j < orders[i].fillers.length; j++) {
                    if (orders[i].fills[j] > 0) {
                        IERC20(orders[i].fromToken).transfer(
                            orders[i].fillers[j],
                            orders[i].fills[j]
                        );
                    }

                    delete orders[i].fills[j];
                    // deleting so that in case we have multiple fills from the same address
                    // we don't send them the same amount twice
                    // the fillers array might have duplicates
                }

                removePendingOrder(orders[i].sourceId);
            } else {
                orders[i].sourceId = pendingIncomingOrders.length;
                pendingIncomingOrders.push(orders[i]);
            }
        }
    }

    function removePendingOrder(uint256 sourceId) public {
        require(sourceId < pendingIncomingOrders.length, "Index out of bounds");

        // Save the element to be moved to the end
        Order storage elementToMove = pendingIncomingOrders[sourceId];

        // Shift elements after 'sourceId' up by one position
        for (uint i = sourceId; i < pendingIncomingOrders.length - 1; i++) {
            pendingIncomingOrders[i] = pendingIncomingOrders[i + 1];
        }

        // Set the last element to be the elementToMove
        pendingIncomingOrders[pendingIncomingOrders.length - 1] = elementToMove;

        // Remove the last element
        pendingIncomingOrders.pop();
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
