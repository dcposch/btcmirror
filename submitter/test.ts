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
    //    "00000000000000000002d52d9816a419b45f1f0efe9a9df4f7b64161e508323d";
    "000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506";
  const blockHeader = await getBlockHeader(btcRpc, blockHash);
  console.log(`Raw block 736000: ${blockHeader}`);

  const txId =
    "3667d5beede7d89e41b0ec456f99c93d6cc5e5caff4c4a5f993caea477b4b9b9";
  const rawTx = await getRawTransaction(btcRpc, txId, blockHash);
  console.log(`Raw tx 736000 #2: ${rawTx}`);

  // For segwit, need to use the old tx serialization format.
  // let buf = createHash("sha256").update(Buffer.from(rawTx, "hex")).digest();
  // buf = createHash("sha256").update(buf).digest();
  // console.log(`Reconstructed txid: ${buf.toString("hex")}`);

  // const bh = "00000000000000000002d52d9816a419b45f1f0efe9a9df4f7b64161e508323d";
  const bh = "000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506";
  // const bh = "00000000000080b66c911bd5ba14a74260057311eaeb1982802f7010f1a9f090";
  const { hash, height, merkleroot, tx } = await getBlock(btcRpc, bh);
  const calcRoot = getMerkleRoot(tx);
  console.log(`Block: ${hash} stated root ${merkleroot} recalc'd ${calcRoot}`);

  console.log("\n\nPROVING TX OFF-CHAIN.");
  const proof = getProof(tx, 1);
  console.log(`Proof block #${height} contains tx 1:${JSON.stringify(proof)}`);

  console.log("Verifying payment on-chain.");
  // TODO
}

main().then(() => console.log("done"));
