#!/usr/bin/env bash
# 只读核对。不签名，不发送交易。
# 现在不要运行。三个地址都填进 env.public 之后，再在聊天里确认。
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -n "${PRIVATE_KEY:-}" || -n "${MNEMONIC:-}" ]]; then
  echo "停止：当前环境里有私钥或助记词变量。请关掉那个终端后再做只读查询。"
  exit 1
fi

if [[ ! -f env.public ]]; then
  echo "还没有 env.public。部署完成并单独确认后，再由 env.public.example 复制。"
  exit 1
fi

if grep -E -q '^[[:space:]]*(PRIVATE_KEY|MNEMONIC|SECRET)=' env.public; then
  echo "停止：env.public 里出现了密钥字段。这个文件只能放地址和 RPC。"
  exit 1
fi

set -a
# shellcheck disable=SC1091
source env.public
set +a

: "${SEPOLIA_RPC_URL:?}"
: "${LASNA_RPC_URL:?}"
: "${ORIGIN_CHAIN_ID:?}"
: "${DEST_CHAIN_ID:?}"
: "${CALLBACK_PROXY:?}"
: "${ORIGIN_ADDR:?}"
: "${REACTIVE_ADDR:?}"
: "${CALLBACK_ADDR:?}"

echo "== 1) 源链 CampOrigin ($ORIGIN_CHAIN_ID) $ORIGIN_ADDR"
echo "   最近的 Ping 事件 (topic0 = $(cast keccak 'Ping(address,uint256)')):"
cast logs --rpc-url "$SEPOLIA_RPC_URL" --from-block "$(( $(cast block-number --rpc-url "$SEPOLIA_RPC_URL") - 5000 ))" \
  --address "$ORIGIN_ADDR" "Ping(address indexed who, uint256 value)" | grep -E "transactionHash|blockNumber" | tail -4 || true

echo "== 2) Lasna CampReactive $REACTIVE_ADDR"
echo "   lastTxHash    : $(cast to-hex "$(cast call --rpc-url "$LASNA_RPC_URL" "$REACTIVE_ADDR" 'lastTxHash()(uint256)' | awk '{print $1}')")"
echo "   lastReactBlock: $(cast call --rpc-url "$LASNA_RPC_URL" "$REACTIVE_ADDR" 'lastReactBlock()(uint256)')"
echo "   remaining     : $(cast call --rpc-url "$LASNA_RPC_URL" "$REACTIVE_ADDR" 'remaining()(uint256)')"
echo "   balance       : $(cast balance --rpc-url "$LASNA_RPC_URL" "$REACTIVE_ADDR" -e) lREACT"
echo "   debt          : $(cast call --rpc-url "$LASNA_RPC_URL" 0x8888888888888888888888888888888888888888 'debt(address)(uint256)' "$REACTIVE_ADDR")"
echo "   浏览器: https://lasna.reactscan.net/address/$REACTIVE_ADDR"

echo "== 3) 目标链 CampCallback ($DEST_CHAIN_ID) $CALLBACK_ADDR"
echo "   count         : $(cast call --rpc-url "$SEPOLIA_RPC_URL" "$CALLBACK_ADDR" 'count()(uint256)')"
echo "   lastValue     : $(cast call --rpc-url "$SEPOLIA_RPC_URL" "$CALLBACK_ADDR" 'lastValue()(uint256)')"
echo "   balance       : $(cast balance --rpc-url "$SEPOLIA_RPC_URL" "$CALLBACK_ADDR" -e) ETH"
echo "   proxy debt    : $(cast call --rpc-url "$SEPOLIA_RPC_URL" "$CALLBACK_PROXY" 'debt(address)(uint256)' "$CALLBACK_ADDR")"
echo "   最近的 Handled 事件:"
cast logs --rpc-url "$SEPOLIA_RPC_URL" --from-block "$(( $(cast block-number --rpc-url "$SEPOLIA_RPC_URL") - 5000 ))" \
  --address "$CALLBACK_ADDR" "Handled(address indexed reactive, uint256 indexed originChainId, uint256 originTxHash, uint256 value, uint256 count)" | grep -E "transactionHash|blockNumber" | tail -4 || true
