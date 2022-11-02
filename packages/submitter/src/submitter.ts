import { BigNumber, Contract, ethers, Wallet } from "ethers";
import {
  createGetblockClient,
  getBlockCount,
  getBlockHash,
  getBlockHeader,
  BtcRpcClient,
} from "./bitcoin-rpc-client";

import btcMirrorJson = require("../../contracts/out/BtcMirror.sol/BtcMirror.json");

// We do NOT import '@eth-optimism/contracts'. that package has terrible
// dependency hygiene. you end up trying to node-gyp compile libusb, wtf.
// all we need is a plain ABI json and a contract address:
import optGPOAbi = require("../abi/OptimismGasPriceOracle.json");
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
  /** When catching up, prove at most this many blocks per batch */
  maxBlocks: number;
}

const MAX_GAS_PRICE_OPT = 50; // Don't submit to Optimism during gas price spikes.

export async function submit(args: SubmitterArgs) {
  console.log(`Running BtcMirror submitter ${JSON.stringify(args)}`);
  if (args.contractAddr == null) {
    throw new Error("BTCMIRROR_CONTRACT_ADDR required");
  } else if (args.rpcUrl == null) {
    throw new Error("ETH_RPC_URL required");
  } else if (args.privateKey == null) {
    throw new Error("ETH_SUBMITTER_PRIVATE_KEY required");
  } else if (args.getblockApiKey == null) {
    throw new Error("GETBLOCK_API_KEY required");
  } else if (args.bitcoinNetwork == null) {
    throw new Error("BITCOIN_NETWORK required");
  } else if (!(args.maxBlocks > 0)) {
    throw new Error("MAX_BLOCKS_PER_BATCH required");
  }

  console.log(`connecting to Ethereum JSON RPC ${args.rpcUrl}`);
  const ethProvider = new ethers.providers.JsonRpcProvider({
    url: args.rpcUrl,
    skipFetchSetup: true,
  });
  const network = await ethProvider.getNetwork();
  const isL2Opt = network.chainId === 10;
  const isL2 = isL2Opt;
  console.log(`Network: ${network.chainId} ${network.name} ${args.rpcUrl}`);
  if (isL2Opt && (await getOptimismBasefee(ethProvider)) > MAX_GAS_PRICE_OPT) {
    console.log(`quitting, max base fee > ${MAX_GAS_PRICE_OPT}`);
    return;
  }

  // First, get Ethereum BtcMirror latest block height
  console.log(`connecting to BtcMirror contract ${args.contractAddr}`);
  const { abi } = btcMirrorJson;
  const contract = new Contract(args.contractAddr, abi, ethProvider);
  const latestHeightRes = await contract.functions["getLatestBlockHeight"]();
  const mirrorLatestHeight = (latestHeightRes[0] as BigNumber).toNumber();
  console.log("got BtcMirror latest block height: " + mirrorLatestHeight);

  // then, get Bitcoin latest block height
  const rpc = createGetblockClient(args.getblockApiKey, args.bitcoinNetwork);
  const btcTipHeight = await getBlockCount(rpc);
  console.log("got BTC latest block height: " + btcTipHeight);
  if (btcTipHeight <= mirrorLatestHeight) {
    console.log("no new blocks");
    return;
  } else if (isL2 && btcTipHeight <= mirrorLatestHeight + 6) {
    console.log("not enough new blocks"); // save gas, submit hourly
    return;
  }
  const targetHeight = Math.min(
    btcTipHeight,
    mirrorLatestHeight + args.maxBlocks
  );

  // walk backwards to the nearest common block. find which blocks to submit
  const { fromHeight, hashes } = await getBlockHashesToSubmit(
    contract,
    rpc,
    mirrorLatestHeight,
    targetHeight
  );
  const headers = await loadBlockHeaders(rpc, hashes);
  console.log(`Loaded BTC blocks ${fromHeight}-${targetHeight}`);
  if (headers.length !== targetHeight - fromHeight + 1) throw new Error("!#");

  // finally, submit a transaction to update the BTCMirror
  console.log(`Submitting ${headers.length} headers from #${fromHeight}`);
  const ethWallet = new Wallet(args.privateKey, ethProvider);
  const contractWithSigner = contract.connect(ethWallet);
  const gasLimit = 100000 + 30000 * headers.length;
  const tx = await contractWithSigner.functions["submit"](
    fromHeight,
    Buffer.from(headers.join(""), "hex"),
    { gasLimit }
  );

  await waitForConfirmation(tx.hash, ethProvider);
}

async function getOptimismBasefee(ethProvider: ethers.providers.Provider) {
  const gasPriceOracle = new Contract(optGPOAddr, optGPOAbi, ethProvider);
  const l1BaseFeeRes = await gasPriceOracle.functions["l1BaseFee"]();
  const l1BaseFeeGwei = Math.round(l1BaseFeeRes[0] / 1e9);
  console.log(`optimism L1 basefee: ${l1BaseFeeGwei} gwei`);
  return l1BaseFeeGwei;
}

/**
 * Figure out which blocks to submit. This is the most interesting logic in the
 * submitter; it walks backward to the most recent common ancestor.
 */
async function getBlockHashesToSubmit(
  contract: Contract,
  rpc: BtcRpcClient,
  mirrorHeight: number,
  targetHeight: number
): Promise<{
  fromHeight: number;
  hashes: string[];
}> {
  console.log("finding last common Bitcoin block");
  const hashes = [] as string[];
  const lch = await getLastCommonHeight(contract, rpc, mirrorHeight, hashes);

  const fromHeight = lch + 1;
  const promises = [] as Promise<string>[];
  for (let height = fromHeight; height <= targetHeight; height++) {
    promises.push(getBlockHash(rpc, height));
  }
  hashes.push(...(await Promise.all(promises)));

  return { fromHeight, hashes };
}

/**
 * Find the most recent common ancestor. This means a block both in canonical
 * Bitcoin chain and recognized by the mirror contract.
 */
async function getLastCommonHeight(
  contract: Contract,
  rpc: BtcRpcClient,
  mirrorLatestHeight: number,
  hashes: string[]
) {
  const maxReorg = 20;
  for (
    let height = mirrorLatestHeight;
    mirrorLatestHeight - maxReorg;
    height--
  ) {
    const mirrorResult = await contract.functions["getBlockHash"](height);
    const mirrorHash = (mirrorResult[0] as string).replace("0x", "");
    const btcHash = await getBlockHash(rpc, height);
    console.log(`height ${height} btc ${btcHash} btcmirror ${mirrorHash}`);
    if (btcHash === mirrorHash) {
      console.log(`found common hash ${height}: ${btcHash}`);
      return height;
    } else if (height === mirrorLatestHeight - maxReorg) {
      throw new Error(
        `no common hash found within ${maxReorg} blocks. catastrophic reorg?`
      );
    }
    hashes.unshift(btcHash);
  }
}

/**
 * Load block headers concurrently, given a list of hashes.
 */
async function loadBlockHeaders(
  rpc: BtcRpcClient,
  hashes: string[]
): Promise<string[]> {
  const promises = hashes.map((hash: string) => getBlockHeader(rpc, hash));
  return await Promise.all(promises);
}

async function waitForConfirmation(
  txHash: string,
  ethProvider: ethers.providers.JsonRpcProvider
) {
  while (true) {
    console.log(`Submitted ${txHash}, waiting for confirmation`);
    await sleep(1000);
    const receipt = await ethProvider.getTransactionReceipt(txHash);
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
