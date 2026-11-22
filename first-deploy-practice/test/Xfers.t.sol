// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Xfers} from "../src/Xfers.sol";
import {IReactive} from "@reactive/src/interfaces/IReactive.sol";
import {AbstractPayer} from "@reactive/src/base/AbstractPayer.sol";
import {MockSystem} from "./MockSystem.sol";

/// @notice 离线测试官方 Xfers 的监听、计数和满额退订。
/// vm.prank 只能在本地假装调用者是系统合约。这不是 Lasna 上的 react 交易。
contract XfersTest is Test {
    address internal constant SYSTEM = 0x8888888888888888888888888888888888888888;
    uint256 internal constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 internal constant TRANSFER_TOPIC_0 =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    uint256 internal constant REACTIVE_IGNORE =
        0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    MockSystem internal mock;
    Xfers internal xfers;
    address internal owner = address(0xA11CE);

    function setUp() public {
        MockSystem implementation = new MockSystem();
        vm.etch(SYSTEM, address(implementation).code);
        mock = MockSystem(payable(SYSTEM));

        vm.deal(address(this), 1 ether);
        vm.deal(owner, 1 ether);
        vm.prank(owner);
        xfers = new Xfers{value: 0.1 ether}(2);
    }

    function test_transferTopicIsTheErc20Signature() public pure {
        assertEq(TRANSFER_TOPIC_0, uint256(keccak256("Transfer(address,address,uint256)")));
    }

    function test_constructorSubscribesAndKeepsTheDeployValueAsBalance() public view {
        assertEq(xfers._OWNER(), owner);
        assertEq(xfers._limit(), 2);
        assertEq(address(xfers).balance, 0.1 ether);
        assertEq(mock.subscribeCount(), 1);
        assertEq(mock.unsubscribeCount(), 0);
        assertEq(mock.receivedFrom(address(xfers)), 0);

        (
            address subscriber,
            uint256 chainId,
            address contractAddress,
            uint256 topic0,
            uint256 topic1,
            uint256 topic2,
            uint256 topic3
        ) = mock.lastSubscribe();
        assertEq(subscriber, address(xfers));
        assertEq(chainId, SEPOLIA_CHAIN_ID);
        assertEq(contractAddress, address(0));
        assertEq(topic0, TRANSFER_TOPIC_0);
        assertEq(topic1, REACTIVE_IGNORE);
        assertEq(topic2, REACTIVE_IGNORE);
        assertEq(topic3, REACTIVE_IGNORE);
    }

    function test_reactRejectsCallerOtherThanSystem() public {
        vm.expectRevert(
            abi.encodeWithSelector(AbstractPayer.NotAuthorized.selector, address(this), SYSTEM)
        );
        xfers.react(_log(address(0x111), 1, 1));
    }

    function test_countsTwoTransfersThenUnsubscribes() public {
        address tokenA = 0x10279e6333f9d0EE103F4715b8aaEA75BE61464C;
        address tokenB = address(0x2222);

        vm.prank(SYSTEM);
        xfers.react(_log(tokenA, 5, 11));

        assertEq(xfers._turnovers(tokenA), 5);
        assertEq(xfers._limit(), 1);
        assertEq(xfers._lastTxHash(), 11);
        assertEq(xfers._lastReactBlockNumber(), block.number);
        assertEq(mock.unsubscribeCount(), 0);

        vm.prank(SYSTEM);
        xfers.react(_log(tokenB, 7, 22));

        assertEq(xfers._turnovers(tokenA), 5);
        assertEq(xfers._turnovers(tokenB), 7);
        assertEq(xfers._limit(), 0);
        assertEq(xfers._lastTxHash(), 22);
        assertEq(mock.unsubscribeCount(), 1);

        (address subscriber, uint256 chainId, address contractAddress, uint256 topic0,,,) = mock.lastUnsubscribe();
        assertEq(subscriber, address(xfers));
        assertEq(chainId, SEPOLIA_CHAIN_ID);
        assertEq(contractAddress, address(0));
        assertEq(topic0, TRANSFER_TOPIC_0);
    }

    function test_opcodeOtherThanThreeDoesNotCount() public {
        IReactive.LogRecord memory log_ = _log(address(0x111), 9, 33);
        log_.opCode = 1;

        vm.prank(SYSTEM);
        xfers.react(log_);

        assertEq(xfers._limit(), 2);
        assertEq(xfers._turnovers(address(0x111)), 0);
        assertEq(xfers._lastTxHash(), 0);
        assertEq(mock.unsubscribeCount(), 0);
    }

    function test_reactItselfDoesNotCheckTopic0() public {
        // 官方 react() 只判断 opCode == 3。
        // Transfer 的筛选发生在订阅条件里，不在这个函数里。
        IReactive.LogRecord memory log_ = _log(address(0x111), 4, 44);
        log_.topic0 = 0x1234;

        vm.prank(SYSTEM);
        xfers.react(log_);

        assertEq(xfers._turnovers(address(0x111)), 4);
        assertEq(xfers._limit(), 1);
    }

    function test_furtherReactAfterLimitUnderflows() public {
        vm.prank(SYSTEM);
        xfers.react(_log(address(0x111), 1, 1));
        vm.prank(SYSTEM);
        xfers.react(_log(address(0x111), 1, 2));

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(SYSTEM);
        xfers.react(_log(address(0x111), 1, 3));
    }

    function test_updateLimitRejectsNonOwner() public {
        vm.expectRevert();
        xfers.updateLimit(3);
    }

    function test_ownerZeroLimitUnsubscribesWithoutCoveringDebt() public {
        mock.setDebt(address(xfers), 0.01 ether);

        vm.prank(owner);
        xfers.updateLimit(0);

        assertEq(xfers._limit(), 0);
        assertEq(mock.unsubscribeCount(), 1);
        assertEq(mock.subscribeCount(), 1);
        assertEq(mock.receivedFrom(address(xfers)), 0);
        assertEq(address(xfers).balance, 0.1 ether);
    }

    function test_ownerNonZeroLimitSendsDebtAmountToSystem() public {
        mock.setDebt(address(xfers), 0.04 ether);

        vm.prank(owner);
        xfers.updateLimit(5);

        assertEq(xfers._limit(), 5);
        assertEq(mock.receivedFrom(address(xfers)), 0.04 ether);
        assertEq(address(xfers).balance, 0.06 ether);
        assertEq(mock.subscribeCount(), 2);
    }

    function test_paySendsBalanceOnlyWhenSystemCalls() public {
        vm.expectRevert(abi.encodeWithSelector(AbstractPayer.NotAuthorized.selector, address(0xB0B), SYSTEM));
        vm.prank(address(0xB0B));
        xfers.pay(1);

        vm.prank(SYSTEM);
        xfers.pay(0.03 ether);

        assertEq(address(xfers).balance, 0.07 ether);
        assertEq(mock.receivedFrom(address(xfers)), 0.03 ether);

        vm.expectRevert(abi.encodeWithSelector(AbstractPayer.InsufficientFunds.selector, 1 ether, 0.07 ether));
        vm.prank(SYSTEM);
        xfers.pay(1 ether);
    }

    function test_directTransferStaysInTheContract() public {
        (bool ok,) = address(xfers).call{value: 0.5 ether}("");
        assertTrue(ok);
        assertEq(address(xfers).balance, 0.6 ether);
        assertEq(mock.receivedFrom(address(xfers)), 0);
    }

    function _log(address token, uint256 amount, uint256 txHash)
        internal
        pure
        returns (IReactive.LogRecord memory log_)
    {
        log_.chainId = SEPOLIA_CHAIN_ID;
        log_.contractAddress = token;
        log_.topic0 = TRANSFER_TOPIC_0;
        log_.topic1 = uint256(uint160(address(0xBEEF)));
        log_.topic2 = uint256(uint160(address(0xCAFE)));
        log_.data = abi.encode(amount);
        log_.blockNumber = 10_896_802;
        log_.opCode = 3;
        log_.txHash = txHash;
        log_.logIndex = 1;
    }
}
