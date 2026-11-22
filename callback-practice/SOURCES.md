# 钉住的来源

核对日期：2026-11-22。文件是按提交下载的副本，不是在学习者机器上 clone 仓库。

## 课程模板

- 仓库：<https://github.com/ethpanda-org/reactive-builder-camp>
- `main` 提交：`87675f45bdaf7b944028bd6231e463f869b453c8`（2026-11-09，`Add backup group contact QR`）
- 目录：<https://github.com/ethpanda-org/reactive-builder-camp/tree/87675f45bdaf7b944028bd6231e463f869b453c8/starter>
- 说明：<https://github.com/ethpanda-org/reactive-builder-camp/blob/87675f45bdaf7b944028bd6231e463f869b453c8/starter/README.md>
- 速查表：<https://github.com/ethpanda-org/reactive-builder-camp/blob/87675f45bdaf7b944028bd6231e463f869b453c8/docs/cheatsheet.md>
- 当前代理表：<https://dev.reactive.network/origins-and-destinations>

与该提交一致、未改逻辑的文件：

| 文件 | sha256 |
| --- | --- |
| `src/CampOrigin.sol` | `e6d2a47e520bbaf85937dcaa3fce3919795dbc95bc78822d192ea81e59bac242` |
| `src/CampReactive.sol` | `79a874c5dd16ff498ef8363e2579f1f9a297090137de50893500ec769a8ceab8` |
| `src/CampCallback.sol` | `3bb1c4bd0781bbfb90102a565d05ba0b68f5b662eec0a46933dbfd67ff3226fc` |
| `test/Camp.t.sol` | `a23bda8be74991cdd055dfef43b009c400adcfdc78aa410e143abbe27c0afdd7` |

`script/Deploy.s.sol` 只改了签名方式：官方是 `vm.startBroadcast(vm.envUint("PRIVATE_KEY"))`，这里是 `vm.startBroadcast()`，配合 `--account lasna`。五个部署步骤、默认金额、阈值和次数没有改。

`script/verify.sh` 改为读取没有密钥的 `env.public`，并且只做 `cast` 查询。

官方 `.env.example` 含 `PRIVATE_KEY=`。本目录不收录那个文件。

## 依赖

- `reactive-lib-omni` 标签 `v0.1.0`，提交 `3ade0dcf1d27e67e5783ef807e73a1b9e0c0cce8`。`foundry.lock` 只钉住这一项。比上一个练习多复制了 `AbstractCallback.sol`，sha256 `f8166bb9db209a4acdf7414e44be310f035c372a0193b171e39ce6d4e34eb658`。
- `forge-std`：课程仓库里 vendored 的 `package.json` 版本是 `1.17.0`，其 `Test.sol` sha256 与提交 `15b2df92a05d4d2f76a06653872fefb287e0e01c` 的文件相同：`6ac6a04a9723f3b51a86fcd0c4cf02e8011f112df052a8eea8e986d85b0bb3d7`。

## 2026-11-22 只读核对

没有签名，没有发交易。

| 读取 | 结果 |
| --- | --- |
| Lasna 钱包 `0xfc118609d291391df2eA4975d39866256d47f5AA` | `0.887844499999378445` lREACT |
| Sepolia 同一地址 | `0.039962792499603120` ETH |
| Sepolia Callback Proxy `0xAa14d9Cd0f788Ca23d11805986C1d8bd035D23b4` 代码大小 | 218 字节 |
| 已部署 Xfers `0x298c78B4d1F0ecAb2b4cD2D477a1abCD4C2d32e6` 的 `_limit()` | 0 |
| 该 Xfers 合约余额 | `0.0441384` lREACT |

编译器：Foundry `forge 1.9.0`，solc `0.8.29`，`evm_version = cancun`，与官方 `foundry.toml` 一致。
