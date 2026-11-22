// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @notice 本地替身，只给 forge test 用。
/// 它放在测试目录，不会被部署到 Lasna。
/// 它记录 subscribe / unsubscribe，并按测试需要返回 debt。
/// 通过 forge test 不能证明 Lasna 节点真的会来调用合约。
contract MockSystem {
    struct Criteria {
        address subscriber;
        uint256 chainId;
        address contractAddress;
        uint256 topic0;
        uint256 topic1;
        uint256 topic2;
        uint256 topic3;
    }

    Criteria public lastSubscribe;
    Criteria public lastUnsubscribe;
    uint256 public subscribeCount;
    uint256 public unsubscribeCount;
    mapping(address => uint256) public debt;
    mapping(address => uint256) public receivedFrom;

    function subscribe(
        uint256 chainId_,
        address contract_,
        uint256 topic0_,
        uint256 topic1_,
        uint256 topic2_,
        uint256 topic3_
    ) external {
        lastSubscribe = Criteria(msg.sender, chainId_, contract_, topic0_, topic1_, topic2_, topic3_);
        subscribeCount += 1;
    }

    function unsubscribe(
        uint256 chainId_,
        address contract_,
        uint256 topic0_,
        uint256 topic1_,
        uint256 topic2_,
        uint256 topic3_
    ) external {
        lastUnsubscribe = Criteria(msg.sender, chainId_, contract_, topic0_, topic1_, topic2_, topic3_);
        unsubscribeCount += 1;
    }

    function setDebt(address contract_, uint256 amount_) external {
        debt[contract_] = amount_;
    }

    receive() external payable {
        receivedFrom[msg.sender] += msg.value;
    }
}
