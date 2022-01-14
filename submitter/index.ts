import { RpcClient } from "jsonrpc-ts";

const apiKey = process.env.GETBLOCK_API_KEY;

interface BitcoinJsonRpc {
  getblockhash: [number];
  getblockheader: [string, boolean];
}
type Rpc = RpcClient<BitcoinJsonRpc>;

async function main() {
  console.log("fetching Bitcoin block headers");
  const rpc = createRpc();

  const blockHeight = 718116;
  let blockHeaders = "";
  for (let i = blockHeight; i < blockHeight + 5; i++) {
    const hex = await getBlockHeader(rpc, i);
    console.log("got block: " + hex);
    blockHeaders += hex;
  }
  console.log(blockHeaders);
}

function createRpc() {
  if (apiKey == "") {
    throw new Error("need GETBLOCK_API_KEY");
  }

  return new RpcClient<BitcoinJsonRpc>({
    url: "https://btc.getblock.io/mainnet/",
    headers: { "x-api-key": apiKey },
  });
}

async function getBlockHeader(rpc: Rpc, blockHeight: number) {
  let res = await rpc.makeRequest({
    method: "getblockhash",
    params: [blockHeight],
    jsonrpc: "2.0",
  });
  if (res.status !== 200) throw new Error("bad getblockhash: " + res);
  const blockHash = res.data.result as string;

  res = await rpc.makeRequest({
    method: "getblockheader",
    params: [blockHash, false],
    jsonrpc: "2.0",
  });
  if (res.status !== 200) throw new Error("bad getblockheader: " + res);
  const headerHex = res.data.result as string;
  return headerHex;
}

main().then(() => console.log("done"));
