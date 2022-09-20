import { JsonRpcClient } from "./json-rpc";

export interface BitcoinJsonRpc {
  getblockcount: [];
  getblockhash: [number];
  getblockheader: [string, boolean];
  getblock: [string, number];
  getrawtransaction: [string, boolean, string];
  decoderawtransaction: [string, string];
}

export interface BlockJson {
  hash: string;
  height: number;
  merkleroot: string;
  nTx: number;
  tx: string[];
}

type BtcRpcClient = JsonRpcClient;

/**
 * Creates a Bitcoin client pointing to getblock.io
 */
export function createGetblockClient(
  apiKey: string,
  network: "testnet" | "mainnet"
) {
  if (!apiKey) throw new Error("Missing GetBlock API key");
  return new JsonRpcClient({
    url: `https://btc.getblock.io/${network}/`,
    headers: { "x-api-key": apiKey },
  });
}

export async function getBlockHash(
  rpc: BtcRpcClient,
  height: number
): Promise<string> {
  let res = await rpc.req("getblockhash", [height]);
  if (res.error) throw new Error("bad getblockhash: " + JSON.stringify(res));
  const blockHash = res.result as string;
  return blockHash;
}

export async function getBlockCount(rpc: BtcRpcClient) {
  const res = await rpc.req("getblockcount", []);
  if (res.error) throw new Error("bad getblockcount: " + JSON.stringify(res));
  return res.result as number;
}

export async function getBlockHeader(rpc: BtcRpcClient, blockHash: string) {
  const res = await rpc.req("getblockheader", [blockHash, false]);
  if (res.error) throw new Error("bad getblockheader: " + JSON.stringify(res));
  const headerHex = res.result as string;
  return headerHex;
}

export async function getBlock(
  rpc: BtcRpcClient,
  blockHash: string
): Promise<BlockJson> {
  const res = await rpc.req("getblock", [blockHash, 1]);
  if (res.error) throw new Error("bad getblock: " + JSON.stringify(res));
  return res.result as BlockJson;
}

export async function getRawTransaction(
  rpc: BtcRpcClient,
  txId: string,
  blockHash: string
): Promise<string> {
  const res = await rpc.req("getrawtransaction", [txId, false, blockHash]);
  if (res.error) throw new Error("bad getrawtx: " + JSON.stringify(res));
  const ret = res.result as string;
  return ret;
}
