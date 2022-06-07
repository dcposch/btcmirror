import {
  createGetblockClient,
  getBlock,
  getBlockCount,
  getBlockHeader,
  getRawTransaction,
} from "./bitcoin-rpc-client";

import { getMerkleRoot, getProof } from "bitcoin-proof";

import { createHash } from "crypto";

async function main() {
  const btcRpc = createGetblockClient();
  console.log(`Connected to Bitcoin RPC: ${btcRpc["options"].url}`);

  const latestHeight = await getBlockCount(btcRpc);
  console.log(`Latest block height: ${latestHeight}`);

  const blockHash =
    "00000000000000000001059a330a05e66e4fa2d1a5adcd56d1bfefc5c114195d";
  const blockHeader = await getBlockHeader(btcRpc, blockHash);
  console.log(`Raw block 739000: ${blockHeader}`);

  const txId =
    "13cd6e3ae96a85bb567a681fbb339719d030cf7d8936cdfc6803069b42774052";
  const rawTx = await getRawTransaction(btcRpc, txId, blockHash);
  console.log(`Raw tx 739000 #2: ${rawTx}`);

  const { hash, height, merkleroot, tx } = await getBlock(btcRpc, blockHash);
  const calcRoot = getMerkleRoot(tx);
  console.log(`Block: ${hash} stated root ${merkleroot} recalc'd ${calcRoot}`);

  console.log("\n\nPROVING TX OFF-CHAIN.");
  const proof = getProof(tx, 1);
  console.log(`Proof block #${height} contains tx 1:${JSON.stringify(proof)}`);

  console.log("Verifying payment on-chain.");
  // TODO
}

main().then(() => console.log("done"));
