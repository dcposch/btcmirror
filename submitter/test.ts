import {
  createGetblockClient,
  getBlock,
  getBlockCount,
  getRawTransaction,
} from "./bitcoin-rpc-client";

import { getMerkleRoot, getProof } from "bitcoin-proof";

async function main() {
  const btcRpc = createGetblockClient();
  console.log(`Connected to Bitcoin RPC: ${btcRpc["options"].url}`);

  const latestHeight = await getBlockCount(btcRpc);
  console.log(`Latest block height: ${latestHeight}`);

  const blockHash =
    "00000000000000000002d52d9816a419b45f1f0efe9a9df4f7b64161e508323d";
  const txId =
    "3667d5beede7d89e41b0ec456f99c93d6cc5e5caff4c4a5f993caea477b4b9b9";
  const rawTx = await getRawTransaction(btcRpc, txId, blockHash);
  console.log(`Raw tx 736000 #2: ${rawTx}`);

  // const bh = "000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506";
  const bh = "00000000000080b66c911bd5ba14a74260057311eaeb1982802f7010f1a9f090";
  const { hash, height, merkleroot, tx } = await getBlock(btcRpc, bh);
  const calcRoot = getMerkleRoot(tx);
  console.log(`Block: ${hash} stated root ${merkleroot} recalc'd ${calcRoot}`);

  console.log("\n\nPROVING TX OFF-CHAIN.");
  const proof = getProof(tx, 1);
  console.log(`Proof block #${height} contains tx 1:${JSON.stringify(proof)}`);

  console.log("VERIFYING ON-CHAIN.");
  // TODO
}

main().then(() => console.log("done"));
