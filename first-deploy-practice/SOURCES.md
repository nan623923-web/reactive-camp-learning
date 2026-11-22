# 钉住的来源

核对日期：2026-11-22。下面的文件是按这些提交下载的独立副本，练习目录里没有官方仓库的 git checkout。

## 练习合约

- 仓库：<https://github.com/Reactive-Network/reactive-smart-contract-demos>
- 分支 `omni` 头提交：`d1d854b4d8ded359d73dcd85cda882ec5c9aab49`（2026-06-11，`added pause/resume, updated readme`）
- 文件：<https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/d1d854b4d8ded359d73dcd85cda882ec5c9aab49/src/micro-demos/Xfers.sol>
- 说明：<https://github.com/Reactive-Network/reactive-smart-contract-demos/blob/d1d854b4d8ded359d73dcd85cda882ec5c9aab49/src/micro-demos/XFERS.md>
- 本地副本：`src/Xfers.sol`
- sha256：`ac65ccf89ceef832acf92a41f77654d717a953c613e40829f7543e24f92cb78e`

`src/Xfers.sol` 与该提交的官方文件一致。本练习没有加目标链回调，也没有加新的业务功能。

## 编译所依赖的库

官方 `remappings.txt` 把 `@reactive/` 指到 `lib/reactive-lib-omni`。demos 仓库在上面那个提交里，子模块指针是：

- 仓库：<https://github.com/Reactive-Network/reactive-lib-omni>
- 提交：`3ade0dcf1d27e67e5783ef807e73a1b9e0c0cce8`（2026-05-21，`Initial implementation.`）

只复制了 Xfers 编译要用的 7 个文件：

| 本地文件 | sha256 |
| --- | --- |
| `lib/reactive-lib-omni/src/base/AbstractPayer.sol` | `95cc4bd413abbdd8ffa9e4d5e79d065738edd76c3a64d91e718cb74facc1fcf8` |
| `lib/reactive-lib-omni/src/base/AbstractReactive.sol` | `7959c24d24212a3bf2c28cb81d17c0f6e4afd7b686afca651458f454c3d5955b` |
| `lib/reactive-lib-omni/src/interfaces/IPayable.sol` | `a252de80e36106b3282639b0332ab3b2b3ec9c5988c1c50143fcaae23243af0b` |
| `lib/reactive-lib-omni/src/interfaces/IPayer.sol` | `f2cecd6b908e6309d0e05659813880f1b39f776ad2405442da4f23e417bb5803` |
| `lib/reactive-lib-omni/src/interfaces/IReactive.sol` | `be393dff0a45cf3573baa65445863efebbec6f57386dbbfd7b2f6eecd5b1f7b7` |
| `lib/reactive-lib-omni/src/interfaces/ISubscriptionService.sol` | `37dd66df40359371790c3ae94a5578747cdaf61d9a9a8a3cbb2e10c5abf2e1d2` |
| `lib/reactive-lib-omni/src/interfaces/ISystemContract.sol` | `d225610b491235444336626c65c2ab8b29f356d9e562edfbe7beac66e06f015c` |

没有复制 `AbstractCallback.sol`。这个练习不部署回调接收合约。

## 测试库

- 仓库：<https://github.com/foundry-rs/forge-std>
- 2026-11-22 用 Foundry 1.9.0 的 `forge init` 解析到的默认分支提交：`15b2df92a05d4d2f76a06653872fefb287e0e01c`（2026-11-12，`chore: sync Vm interface cheatcodes (#948)`）
- `package.json` 版本号：`1.17.0`
- 这个提交没有对应 `v1.9.x` 标签。`forge-std` 的 `v1.9.7` 是 2025-04 的旧标签，和 Foundry 1.9.0 不是同一个东西。
- 本地只放入该提交的 `src/`、两份许可证、`README.md` 和 `package.json`。`Test.sol` 的 sha256：`6ac6a04a9723f3b51a86fcd0c4cf02e8011f112df052a8eea8e986d85b0bb3d7`

## 费用相关的系统合约源码

- 经济说明：<https://dev.reactive.network/economy>
- 反应合约说明：<https://dev.reactive.network/reactive-contracts>
- 系统合约仓库 `main`：<https://github.com/Reactive-Network/system-smart-contracts/commit/72710d2b5f4e15e445da782aaef9f8bae59f4af9>（2026-10-29）
- 扣费实现：<https://github.com/Reactive-Network/system-smart-contracts/blob/72710d2b5f4e15e445da782aaef9f8bae59f4af9/src/omni/base/AbstractProxiedPayableBridge.sol> 里的 `_charge`、`_deposit`、`depositTo`
- `trigger`：同仓库 `src/omni/SystemContract.sol`
- 合约里的 `pay()`：上面的 `AbstractPayer.sol`

## 2026-11-22 只读链上参数

只调用了公开的 `eth_chainId` 和 `eth_call`。没有查钱包余额，没有签名，没有发交易。

RPC：<https://lasna-rpc.rnk.dev/>

| 读取 | 结果 |
| --- | --- |
| `cast chain-id` | `5318007` |
| 系统合约 `_gasPriceCoeffPer1000()` | `1000`（系数 = 1000 / 1000 = 1） |
| 系统合约 `_extraGas()` | `100000` |
| 系统合约 `_maxChargeGas()` | `50000` |

系统合约地址：`0x8888888888888888888888888888888888888888`

这些数和 2026-11-20 的学习笔记一致，也和源码默认值一致。管理员以后可以改，真正部署前再读一次。

## 编译器

本机核对时使用的是 Foundry `forge 1.9.0`，提交 `6056c5845d34205a83cf7108042adb137325c9df`，构建时间 2026-11-02。

`foundry.toml` 把 solc 钉在 `0.8.29`，优化器打开，`optimizer_runs = 200`。官方 demos 的 `foundry.toml` 还打开了 `via_ir`。本练习关掉 `via_ir`，避免第一次编译过慢。逻辑与官方 `Xfers.sol` 相同，字节码不追求和官方 via_ir 构建逐字相同。
