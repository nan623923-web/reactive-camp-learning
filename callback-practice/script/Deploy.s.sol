// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Script, console } from "forge-std/Script.sol";
import { IPayable } from "@reactive/src/interfaces/IPayable.sol";
import { CampOrigin } from "../src/CampOrigin.sol";
import { CampReactive } from "../src/CampReactive.sol";
import { CampCallback } from "../src/CampCallback.sol";

/// 官方 Deploy.s.sol 用 vm.startBroadcast(vm.envUint("PRIVATE_KEY"))。
/// 这里改成 vm.startBroadcast()，签名者来自命令行的 --account lasna。
/// 本文件不读取私钥。没有 --broadcast 时不会发送交易。

contract DeployOrigin is Script {
    function run() external {
        vm.startBroadcast();
        CampOrigin o = new CampOrigin();
        vm.stopBroadcast();
        console.log("ORIGIN_ADDR=", address(o));
    }
}

contract DeployReactive is Script {
    function run() external {
        uint256 originChain = vm.envUint("ORIGIN_CHAIN_ID");
        address originAddr = vm.envAddress("ORIGIN_ADDR");
        uint256 destChain = vm.envUint("DEST_CHAIN_ID");
        uint256 threshold = vm.envOr("THRESHOLD", uint256(100));
        uint256 limit = vm.envOr("LIMIT", uint256(5));
        uint256 fund = vm.envOr("REACTIVE_FUND", uint256(0.5 ether));
        uint256 topic0 = uint256(keccak256("Ping(address,uint256)"));

        vm.startBroadcast();
        CampReactive r = new CampReactive{ value: fund }(originChain, originAddr, topic0, destChain, threshold, limit);
        vm.stopBroadcast();
        console.log("REACTIVE_ADDR=", address(r));
    }
}

contract DeployCallback is Script {
    function run() external {
        address proxy = vm.envAddress("CALLBACK_PROXY");
        address reactive = vm.envAddress("REACTIVE_ADDR");
        uint256 fund = vm.envOr("CALLBACK_FUND", uint256(0.02 ether));

        vm.startBroadcast();
        CampCallback c = new CampCallback{ value: fund }(IPayable(payable(proxy)), reactive);
        vm.stopBroadcast();
        console.log("CALLBACK_ADDR=", address(c));
    }
}

contract SetRecipient is Script {
    function run() external {
        vm.startBroadcast();
        CampReactive(payable(vm.envAddress("REACTIVE_ADDR"))).setRecipient(vm.envAddress("CALLBACK_ADDR"));
        vm.stopBroadcast();
        console.log("recipient set");
    }
}

contract Ping is Script {
    function run() external {
        uint256 value = vm.envOr("PING_VALUE", uint256(500));
        vm.startBroadcast();
        CampOrigin(vm.envAddress("ORIGIN_ADDR")).ping(value);
        vm.stopBroadcast();
        console.log("pinged with value", value);
    }
}
