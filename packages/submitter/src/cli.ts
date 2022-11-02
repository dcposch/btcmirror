import { submit } from "./submitter";

async function main() {
  const { env } = process;
  console.log("Running BtcMirror submitter...");
  await submit({
    contractAddr: env.BTCMIRROR_CONTRACT_ADDR,
    rpcUrl: env.ETH_RPC_URL,
    privateKey: env.ETH_SUBMITTER_PRIVATE_KEY,
    getblockApiKey: env.GETBLOCK_API_KEY,
    bitcoinNetwork: (env.BITCOIN_NETWORK || "mainnet") as "mainnet" | "testnet",
    maxBlocks: 200,
  });
}

main()
  .then(() => console.log("Done"))
  .catch((e) => console.error(e));
