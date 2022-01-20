import * as React from "react";
import { useEffect, useState } from "react";
import BtcMirrorContract from "./BtcMirrorContract";

interface Chain {
  id: string;
  name: string;
  rpcUrl: string;
  contractAddr: string;
  explorerUrl: string;
  explorerText: string;
  contract?: BtcMirrorContract;
}

const chains: Chain[] = [
  {
    id: "xdai",
    name: "XDAI",
    rpcUrl: "https://rpc.xdaichain.com",
    contractAddr: "0x24e7091d7e01750f467d4272839acb6b5404dac5",
    explorerUrl:
      "https://blockscout.com/xdai/mainnet/address/0x24e7091d7e01750f467d4272839acb6b5404dac5/logs",
    explorerText: "View contract on Blockscout",
  },
  {
    id: "opt",
    name: "OPTIMISM",
    rpcUrl:
      "https://opt-mainnet.g.alchemy.com/v2/UIWZJo9n_JabdfySOspT_ZwZfExy8UUs",
    contractAddr: "0x69ee459ca98cbdecf9156b041ee1621513aef0c6",
    explorerUrl:
      "https://optimistic.etherscan.io/address/0x69ee459ca98cbdecf9156b041ee1621513aef0c6#events",
    explorerText: "View contract on Etherscan",
  },
];

export default function LiveStatus() {
  const [chainId, setChainId] = useState("opt");
  const chain = chains.find((c) => c.id === chainId);

  if (chain.contract == null) {
    chain.contract = new BtcMirrorContract(chain.rpcUrl, chain.contractAddr);
  }

  const [status, setStatus] = useState({
    chainId: "",
    latestHeight: 0,
    latestBlocks: [] as { height: number; hash: string }[],
  });

  const numBlocksToShow = 5;

  // Load latest blocks from contract periodically, and immediately if user
  // selects a different chain.
  useEffect(() => {
    if (chainId === status.chainId) return;
    (async () => {
      const cid = chainId;
      const latestHeight = await chain.contract.getLatestBlockHeight();
      const promises = [...Array(numBlocksToShow).keys()].map((i) =>
        chain.contract.getBlockHash(latestHeight - i)
      );
      const latestHashes = await Promise.all(promises);
      if (cid !== chainId) return; // stale, ignore
      const latestBlocks = latestHashes.map((h, i) => ({
        height: latestHeight - i,
        hash: h,
      }));
      setStatus({ chainId, latestBlocks, latestHeight });
    })();
  }, [chainId]);

  return (
    <div>
      <div className="row">
        <a href={chain.explorerUrl}>{chain.explorerText}</a>
        <div>
          {chains.map((c, i) => {
            const elem =
              c.id === chainId ? (
                <strong>{c.name}</strong>
              ) : (
                <button onClick={() => setChainId(c.id)}>{c.name}</button>
              );
            return <span key={c.id}>{elem} </span>;
          })}
        </div>
      </div>
      <p>
        Live data from contract.{" "}
        {status.chainId === chainId && (
          <em>Latest Bitcoin block: #{status.latestHeight}</em>
        )}
      </p>
      <p>
        <div>Latest block hashes:</div>
        {status.chainId === chainId &&
          status.latestBlocks.map((b, i) => {
            const dispHash = b.hash.replace("0x", "");
            if (i === 0) return <em key={b.height}>{dispHash}</em>;
            return <div key={b.height}>{dispHash}</div>;
          })}
        {status.chainId !== chainId &&
          [...Array(numBlocksToShow).keys()].map(() => <div>loading...</div>)}
      </p>
    </div>
  );
}
