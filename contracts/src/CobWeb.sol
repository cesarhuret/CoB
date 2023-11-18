// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import {IMessageRecipient} from "@hyperlane/v3/interfaces/IMessageRecipient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IChronicle} from "@chronicle/contracts/IChronicle.sol";
import {Utils} from "./utils.sol";
import "@hyperlane/v3/Mailbox.sol";

contract CobWebV3 is IMessageRecipient {
    using Utils for uint;

    struct Order {
        uint256 sourceId;
        address sender;
        uint256 amountIn;
        uint256 amountOut;
        address fromToken;
        address toToken;
        uint256 fromChain;
        uint256 toChain;
        uint256 deadline;
        uint256 maxSlippage;
        bool filled;
        address[] fillers;
        mapping(address => uint256) fills;
    }

    Order[] public pendingIncomingOrders;

    mapping(address => address) tokenToOracle;

    constructor(address mailbox, mapping(address => address) _tokenToOracle) {
        _mailbox = mailbox;
        tokenToOracle = _tokenToOracle;
    }

    address immutable _mailbox;

    IInterchainGasPaymaster igp =
        IInterchainGasPaymaster(0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a);

    // for access control on handle implementations
    modifier onlyMailbox() {
        require(msg.sender == _mailbox, "Only Mailbox");
        _;
    }

    function bridge(Order memory order) external overrides {
        if (order.fromToken != order.toToken) {
            // oracle provided rate
            order.amountOut = 0;
        } else {
            order.amountOut = order.amountIn;
        }

        order.filled = false;

        Order[] memory ordersToBroadcast;

        for (uint i = 0; i < pendingIncomingOrders.length; i++) {
            // uint256 deltaPriceSlippage = pendingIncomingOrders[i].am -
            //     order.maxSlippage;
            // MISSING: slippage check
            if (
                pendingIncomingOrders[i].fromToken == order.toToken &&
                pendingIncomingOrders[i].toToken == order.fromToken &&
                pendingIncomingOrders[i].fromChain == order.toChain &&
                pendingIncomingOrders[i].toChain == order.fromChain &&
                pendingIncomingOrders[i].filled == false &&
                pendingIncomingOrders.deadline < block.timestamp
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
                pendingIncomingOrders[i].fills[msg.sender] += deltaFilledIn;

                if (
                    pendingIncomingOrders[i].amountIn == 0 &&
                    pendingIncomingOrders[i].amountOut == 0
                ) {
                    pendingIncomingOrders[i].filled = true;
                    ordersToBroadcast.push(pendingIncomingOrders[i]);
                }
            }
        }

        if (!order.filled && order.amountIn != 0) {
            // we transfer our pending origin to the contract
            IERC20(order.fromToken).transferFrom(
                msg.sender,
                address(this),
                order.amountIn
            );
        }

        ordersToBroadcast.push(order);

        // broadcast orders
        _broadcast(ordersToBroadcast);
    }

    function _broadcast(Order[] memory orders) private returns (bytes32) {
        bytes32 messageId = IMailbox(_mailbox).dispatch(
            _destinationChainId,
            _addressToBytes32(_bridgeOnDestinationChain),
            bytes(abi.encode(orders))
        );

        igp.payForGas{value: msg.value}(
            messageId, // The ID of the message that was just dispatched
            _destinationChainId, // The destination domain of the message
            200000, // 100k gas to use in the recipient's handle function
            msg.sender // refunds go to msg.sender, who paid the msg.value
        );

        return messageId;
    }

    function defaultToBridge(uint256 orderSourceId) {
        if (
            pendingIncomingOrders[orderSourceId].filled == false &&
            pendingIncomingOrders[orderSourceId].deadline > block.timestamp
        ) {
            // we don't cob anymore and just bridge
        }
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external onlyMailbox {
        (orders) = abi.decode(_body, Order[]);

        // handle transfers for filled orders
        for (uint i = 0; i < orders.length; i++) {
            if (orders[i].filled == true) {
                // we transfer to the person who filled our order
                for (uint j = 0; j < orders[i].fillers.length; j++) {
                    if (orders[i].fills[orders[i].fillers[j]] > 0) {
                        IERC20(orders[i].fromToken).transfer(
                            orders[i].fillers[j],
                            orders[i].fills[orders[i].fillers[j]]
                        );
                    }

                    delete orders[i].fills[orders[i].fillers[j]];
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
        require(index < pendingIncomingOrders.length, "Index out of bounds");

        // Save the element to be moved to the end
        uint elementToMove = pendingIncomingOrders[index];

        // Shift elements after 'index' up by one position
        for (uint i = index; i < pendingIncomingOrders.length - 1; i++) {
            pendingIncomingOrders[i] = pendingIncomingOrders[i + 1];
        }

        // Set the last element to be the elementToMove
        pendingIncomingOrders[pendingIncomingOrders.length - 1] = elementToMove;

        // Remove the last element
        pendingIncomingOrders.pop();
    }
}
