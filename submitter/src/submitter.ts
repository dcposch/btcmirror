import { BigNumber, Contract, ethers, Wallet } from "ethers";
import {
  createGetblockClient,
  getBlockCount,
  getBlockHash,
  getBlockHeader,
} from "./bitcoin-rpc-client";

import btcMirrorAbiJson = require("../../abi/BtcMirror.json");

// we do NOT import '@eth-optimism/contracts'. that package has terrible
// dependency hygiene. you end up trying to node-gyp compile libusb, wtf.
// all we need is a plain ABI json and a contract address:
import optGPOAbi = require("../../abi/OptimismGasPriceOracle.json");
const optGPOAddr = "0x420000000000000000000000000000000000000F";

interface SubmitterArgs {
  /** Bitcoin Mirror contract address */
  contractAddr: string;
  /** Ethereum RPC URL */
  rpcUrl: string;
  /** Eth private key, hex. */
  privateKey: string;
  /** GetBlock Bitcoin API key. */
  getblockApiKey: string;
  /** Bitcoin network, testnet or mainnet */
  bitcoinNetwork: "testnet" | "mainnet";
}

const MAX_BTC_BLOCKS_PER_TX = 200; // Prove that many BTC txs at once.

export async function submit(args: SubmitterArgs) {
  console.log(`Running BtcMirror submitter ${JSON.stringify(args)}`);
  if (args.contractAddr == null) {
    throw new Error("BTCMIRROR_CONTRACT_ADDR required");
  } else if (args.rpcUrl == null) {
    throw new Error("ETH_RPC_URL required");
  } else if (args.privateKey == null) {
    throw new Error("ETH_SUBMITTER_PRIVATE_KEY required");
  }

  // first, get Ethereum BtcMirror latest block height
  console.log(`connecting to Ethereum JSON RPC ${args.rpcUrl}`);
  const ethProvider = new ethers.providers.JsonRpcProvider(args.rpcUrl);
  console.log(`connecting to BtcMirror contract ${args.contractAddr}`);

  const network = await ethProvider.getNetwork();
  const isL2Opt = network.chainId === 10;
  const isL2Zksync = args.rpcUrl.includes("zksync");
  const isL2 = isL2Opt || isL2Zksync;
  console.log(`Network: ${network.chainId} ${network.name} ${args.rpcUrl}`);
  if (isL2Opt) {
    // optimism. bail if the gas cost is too high
    const gasPriceOracle = new Contract(optGPOAddr, optGPOAbi, ethProvider);
    const l1BaseFeeRes = await gasPriceOracle.functions["l1BaseFee"]();
    const l1BaseFeeGwei = Math.round(l1BaseFeeRes[0] / 1e9);
    console.log(`optimism L1 basefee: ${l1BaseFeeGwei} gwei`);

    const maxBaseFee = 50;
    if (l1BaseFeeGwei > maxBaseFee) {
      console.log(`quitting, max base fee > ${maxBaseFee}`);
      return;
    }
  }

  // workaround forge bug https://github.com/gakonst/foundry/issues/457
  const brokenAbi = btcMirrorAbiJson.abi;
  const abi = brokenAbi.map((func) => Object.assign(func, { constant: null }));

  const contract = new Contract(args.contractAddr, abi, ethProvider);
  const latestHeightRes = await contract.functions["getLatestBlockHeight"]();
  const mirrorLatestHeight = (latestHeightRes[0] as BigNumber).toNumber();
  console.log("got BtcMirror latest block height: " + mirrorLatestHeight);

  // then, get Bitcoin latest block height
  const rpc = createGetblockClient(args.getblockApiKey, args.bitcoinNetwork);
  const btcLatestHeight = await getBlockCount(rpc);
  console.log("got BTC latest block height: " + btcLatestHeight);
  if (btcLatestHeight <= mirrorLatestHeight) {
    console.log("no new blocks");
    return;
  }
  if (isL2 && btcLatestHeight <= mirrorLatestHeight + 10) {
    // save gas
    console.log("not enough new blocks");
    return;
  }
  const targetHeight = Math.min(
    btcLatestHeight,
    mirrorLatestHeight + MAX_BTC_BLOCKS_PER_TX
  );

  // then, find the most common ancestor
  const prefetch = {};
  for (let height = mirrorLatestHeight + 1; height <= targetHeight; height++) {
    console.log(`prefetching ${height}...`);
    prefetch[height] = getBlockHash(rpc, height);
  }

  console.log("finding last common Bitcoin block headers");
  let lastCommonHeight: number;
  const btcHeightToHash = [];
  for (let height = targetHeight; ; height--) {
    const mirrorResult =
      height > mirrorLatestHeight
        ? ["n/a"]
        : await contract.functions["getBlockHash"](height);
    const mirrorHash = (mirrorResult[0] as string).replace("0x", "");
    const btcHash = await (prefetch[height] || getBlockHash(rpc, height));
    btcHeightToHash[height] = btcHash;
    console.log(`height ${height} btc ${btcHash} btcmirror ${mirrorHash}`);
    if (btcHash === mirrorHash) {
      lastCommonHeight = height;
      break;
    } else if (height === targetHeight - MAX_BTC_BLOCKS_PER_TX) {
      throw new Error("no common hash found. catastrophic reorg?");
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
  const headers = await Promise.all(promises);
  const headersHex = headers.join("");
  console.log(`got BTC block headers ${submitFromHeight}: ${headersHex}`);

  const nSubmit = targetHeight - submitFromHeight + 1;
  if (nSubmit === 0 || headersHex.length !== 160 * nSubmit) {
    console.log(JSON.stringify({ targetHeight, submitFromHeight, headersHex }));
    throw new Error("INVALID, exiting");
  }

  // finally, submit a transaction to update the BTCMirror
  console.log(`submitting BtcMirror ${submitFromHeight} ${headersHex}`);
  const ethWallet = new Wallet(args.privateKey, ethProvider);
  const contractWithSigner = contract.connect(ethWallet);
  const txOptions = { gasLimit: 100000 + 30000 * headers.length };
  const tx = await contractWithSigner.functions["submit"](
    submitFromHeight,
    Buffer.from(headersHex, "hex"),
    txOptions
  );

  while (true) {
    console.log(`Submitted ${tx.hash}, waiting for confirmation`);
    await sleep(1000);
    const receipt = await ethProvider.getTransactionReceipt(tx.hash);
    if (receipt == null) {
      console.log("Not yet confirmed");
      continue;
    }
    if (receipt.status === 1) {
      console.log("Transaction succeeded");
    } else {
      console.log("Transaction failed");
      console.log(receipt);
    }
    break;
  }
}

function sleep(time: number) {
  return new Promise((resolve) => setTimeout(resolve, time));
}
