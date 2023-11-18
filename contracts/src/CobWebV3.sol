// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@hyperlane/v3/Mailbox.sol";

contract CobWebV3 {
    struct Order {
        address sender;
        uint256 amount;
        address fromToken;
        address toToken;
        uint256 chainId;
        uint256 deadline;
    }

    Order[] public pendingIncomingOrders;

    address immutable _mailbox;

    IInterchainGasPaymaster igp =
        IInterchainGasPaymaster(0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a);

    // for access control on handle implementations
    modifier onlyMailbox() {
        require(msg.sender == _mailbox);
        _;
    }

    /**
     * @notice Dispatches a message to the destination domain & recipient.
     * @param _originInputToken Domain of destination chain
     * @param _originOutputToken Domain of destination chain
     * @param _destOutputToken Domain of destination chain
     * @param _amountToPayInOutputToken Domain of destination chain
     * @param _destinationChainId Address of recipient on destination chain as bytes32
     * @param _bridgeOnDestinationChain Raw bytes content of message body
     * @param _destinationChainRecipient the address of person we are sending tokens to on the destination chain
     * @return The message ID inserted into the Mailbox's merkle tree
     */
    function bridge(
        address _originInputToken,
        address _originOutputToken,
        address _destOutputToken,
        uint256 _amountToPayInOutputToken,
        uint32 _destinationChainId,
        address _bridgeOnDestinationChain,
        address _destinationChainRecipient
    ) external payable returns (bytes32) {
        uint256 inputTokenPrice = tokenPrices[_originInputToken];

        uint256 outputTokenPrice = tokenPrices[_originOutputToken];

        uint256 amountOfInputToken = (_amountToPayInOutputToken *
            outputTokenPrice) / inputTokenPrice;

        bytes32 messageId = IMailbox(_mailbox).dispatch(
            _destinationChainId,
            _addressToBytes32(_bridgeOnDestinationChain),
            bytes(
                abi.encode(
                    _destOutputToken,
                    _amountToPayInOutputToken,
                    _destinationChainRecipient
                )
            )
        );

        igp.payForGas{value: msg.value}(
            messageId, // The ID of the message that was just dispatched
            _destinationChainId, // The destination domain of the message
            500000, // 100k gas to use in the recipient's handle function
            msg.sender // refunds go to msg.sender, who paid the msg.value
        );

        deposit(_originInputToken, amountOfInputToken);

        return messageId;
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external onlyMailbox {
        (address outputToken, uint256 amount, address recipient) = abi.decode(
            _body,
            (address, uint256, address)
        );

        // handle transfer to recipient
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
