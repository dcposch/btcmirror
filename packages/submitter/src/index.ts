/**
 * Welcome to Cloudflare Workers! This is your first scheduled worker.
 *
 * - Run `wrangler dev --local` in your terminal to start a development server
 * - Run `curl "http://localhost:8787/cdn-cgi/mf/scheduled"` to trigger the scheduled event
 * - Go back to the console to see what your worker has logged
 * - Update the Cron trigger in wrangler.toml (see https://developers.cloudflare.com/workers/wrangler/configuration/#triggers)
 * - Run `wrangler publish --name my-worker` to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/runtime-apis/scheduled-event/
 */

import { ethers } from "ethers";
import { submit } from "./submitter";

export interface Env {
  // Example binding to KV. Learn more at https://developers.cloudflare.com/workers/runtime-apis/kv/
  // MY_KV_NAMESPACE: KVNamespace;
  //
  // Example binding to Durable Object. Learn more at https://developers.cloudflare.com/workers/runtime-apis/durable-objects/
  // MY_DURABLE_OBJECT: DurableObjectNamespace;
  //
  // Example binding to R2. Learn more at https://developers.cloudflare.com/workers/runtime-apis/r2/
  // MY_BUCKET: R2Bucket;

  BTCMIRROR_CONTRACT_ADDR: string;
  ETH_RPC_URL: string;
  ETH_SUBMITTER_PRIVATE_KEY: string;
  GETBLOCK_API_KEY: string;
  BITCOIN_NETWORK: "testnet" | "mainnet";
}

export default {
  async scheduled(
    controller: ScheduledController,
    env: Env,
    ctx: ExecutionContext
  ): Promise<void> {
    console.log("Running BtcMirror submitter...");
    await submit({
      contractAddr: env.BTCMIRROR_CONTRACT_ADDR,
      rpcUrl: env.ETH_RPC_URL,
      privateKey: env.ETH_SUBMITTER_PRIVATE_KEY,
      getblockApiKey: env.GETBLOCK_API_KEY,
      bitcoinNetwork: env.BITCOIN_NETWORK,
    });
    console.log("Done running BtcMirror submitter...");
  },
};
