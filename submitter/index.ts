import { RpcClient } from "jsonrpc-ts";

import { BigNumber, Contract, ethers, Wallet } from "ethers";

import btcMirrorAbiJson = require("../abi/BtcMirror.json");

// we do NOT import '@eth-optimism/contracts'. that package has terrible
// dependency hygiene. you end up trying to node-gyp compile libusb, wtf.
// all we need is a plain ABI json and a contract address:
import optGPOAbi = require("../abi/OptimismGasPriceOracle.json");
const optGPOAddr = "0x420000000000000000000000000000000000000F";

const ethApi = process.env.ETH_RPC_URL;
const ethPK = process.env.ETH_SUBMITTER_PRIVATE_KEY;
const apiKey = process.env.GETBLOCK_API_KEY;
const btcMirrorContractAddr = process.argv[2];

interface BitcoinJsonRpc {
  getblockcount: [];
  getblockhash: [number];
  getblockheader: [string, boolean];
}
type BtcRpc = RpcClient<BitcoinJsonRpc>;

async function main() {
  if (btcMirrorContractAddr == null) {
    throw new Error("usage: npm start -- <BtcMirror contract address>");
  } else if (ethApi == null) {
    throw new Error("ETH_RPC_URL required");
  } else if (ethPK == null) {
    throw new Error("ETH_SUBMITTER_PRIVATE_KEY required");
  }

  // first, get Ethereum BtcMirror latest block height
  console.log(`connecting to Ethereum JSON RPC ${ethApi}`);
  const ethProvider = new ethers.providers.JsonRpcProvider(ethApi);
  console.log(`connecting to BtcMirror contract ${btcMirrorContractAddr}`);

  const network = await ethProvider.getNetwork();
  if (network.chainId === 10) {
    // optimism. bail if the gas cost is too high
    const gasPriceOracle = new Contract(optGPOAddr, optGPOAbi, ethProvider);
    const l1BaseFeeRes = await gasPriceOracle.functions["l1BaseFee"]();
    const l1BaseFeeGwei = Math.round(l1BaseFeeRes[0] / 1e9);
    console.log(`optimism L1 basefee: ${l1BaseFeeGwei} gwei`);

    const maxBaseFee = 100;
    if (l1BaseFeeGwei > maxBaseFee) {
      console.log(`quitting, max base fee > ${maxBaseFee}`);
      return;
    }
  }

  // workaround forge bug https://github.com/gakonst/foundry/issues/457
  const brokenAbi = btcMirrorAbiJson.abi;
  const abi = brokenAbi.map((func) => Object.assign(func, { constant: null }));

  const contract = new Contract(btcMirrorContractAddr, abi, ethProvider);
  const latestHeightRes = await contract.functions["getLatestBlockHeight"]();
  const mirrorLatestHeight = (latestHeightRes[0] as BigNumber).toNumber();
  console.log("got BtcMirror latest block height: " + mirrorLatestHeight);

  // then, get Bitcoin latest block height
  const rpc = createBitcoinRpc();
  const btcLatestHeight = await getLatestBlockHeight(rpc);
  console.log("got BTC latest block height: " + btcLatestHeight);
  if (btcLatestHeight <= mirrorLatestHeight) {
    console.log("no new blocks");
    return;
  }
  const targetHeight = Math.min(btcLatestHeight, mirrorLatestHeight + 20);

  // then, find the most common ancestor
  console.log("finding last common Bitcoin block headers");
  let lastCommonHeight;
  const btcHeightToHash = [];
  for (let height = targetHeight; ; height--) {
    const mirrorResult =
      height > mirrorLatestHeight
        ? ["n/a"]
        : await contract.functions["getBlockHash"](height);
    const mirrorHash = (mirrorResult[0] as string).replace("0x", "");
    const btcHash = await getHash(rpc, height);
    btcHeightToHash[height] = btcHash;
    console.log(`height ${height} btc ${btcHash} btcmirror ${mirrorHash}`);
    if (btcHash === mirrorHash) {
      lastCommonHeight = height;
      break;
    } else if (height === targetHeight - 50) {
      throw new Error("no common hash in last 50 blocks. catastrophic reorg?");
    }
  }
  const lcHash = btcHeightToHash[lastCommonHeight];
  console.log(`found common hash ${lastCommonHeight}: ${lcHash}`);

  // load block headers from last-common to target
  const submitFromHeight = lastCommonHeight + 1;
  const promises = [];
  for (let height = submitFromHeight; height <= targetHeight; height++) {
    const hash = btcHeightToHash[height];
    promises.push(getBlockHeader(rpc, hash));
  }
  const hashes = await Promise.all(promises);
  const headersHex = hashes.join("");
  console.log(`got BTC block headers ${submitFromHeight}: ${headersHex}`);

  const nSubmit = targetHeight - submitFromHeight + 1;
  if (nSubmit === 0 || headersHex.length !== 160 * nSubmit) {
    console.log(JSON.stringify({ targetHeight, submitFromHeight, headersHex }));
    throw new Error("INVALID, exiting");
  }

  // finally, submit a transaction to update the BTCMirror
  console.log(`submitting BtcMirror ${submitFromHeight} ${headersHex}`);
  const ethWallet = new Wallet(ethPK, ethProvider);
  const contractWithSigner = contract.connect(ethWallet);
  const txOptions = { gasLimit: 1000000 };
  const res = await contractWithSigner.functions["submit"](
    submitFromHeight,
    Buffer.from(headersHex, "hex"),
    txOptions
  );
  console.log("result", res);
}

function createBitcoinRpc() {
  if (apiKey == "") {
    throw new Error("need GETBLOCK_API_KEY");
  }

  return new RpcClient<BitcoinJsonRpc>({
    url: "https://btc.getblock.io/mainnet/",
    headers: { "x-api-key": apiKey },
  });
}

async function getHash(rpc: BtcRpc, height: number): Promise<string> {
  let res = await rpc.makeRequest({
    method: "getblockhash",
    params: [height],
    jsonrpc: "2.0",
  });
  if (res.status !== 200) throw new Error("bad getblockhash: " + res);
  const blockHash = res.data.result as string;
  return blockHash;
}

async function getLatestBlockHeight(rpc: BtcRpc) {
  const res = await rpc.makeRequest({
    method: "getblockcount",
    params: [],
    jsonrpc: "2.0",
  });
  if (res.status !== 200) throw new Error("bad getblockcount: " + res);
  return res.data.result as number;
}

async function getBlockHeader(rpc: BtcRpc, blockHash: string) {
  const res = await rpc.makeRequest({
    method: "getblockheader",
    params: [blockHash, false],
    jsonrpc: "2.0",
  });
  if (res.status !== 200) throw new Error("bad getblockheader: " + res);
  const headerHex = res.data.result as string;
  return headerHex;
}

main().then(() => console.log("done"));
