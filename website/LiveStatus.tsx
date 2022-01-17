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
    name: "XDAI MAINNET",
    rpcUrl: "https://rpc.xdaichain.com",
    contractAddr: "0x8f562B0ADd56A9FaCd9E42A51D874BA17f616B27",
    explorerUrl:
      "https://blockscout.com/xdai/mainnet/address/0x8f562B0ADd56A9FaCd9E42A51D874BA17f616B27/logs",
    explorerText: "View contract on Blockscout",
  },
];

export default function LiveStatus() {
  const [chainId, setChainId] = useState("xdai");
  const chain = chains.find((c) => c.id === chainId);

  if (chain.contract == null) {
    chain.contract = new BtcMirrorContract(chain.rpcUrl, chain.contractAddr);
  }

  const [status, setStatus] = useState({
    chainId: "",
    latestBlocks: [] as { height: number; hash: string }[],
  });

  const numBlocksToShow = 5;

  useEffect(() => {
    (async () => {
      const latestHeight = await chain.contract.getLatestBlockHeight();
      const promises = [...Array(numBlocksToShow).keys()].map((i) =>
        chain.contract.getBlockHash(latestHeight - i)
      );
      const latestHashes = await Promise.all(promises);
      const latestBlocks = latestHashes.map((h, i) => ({
        height: latestHeight - i,
        hash: h,
      }));
      setStatus({ chainId, latestBlocks });
    })();
  }, []);

  return (
    <div>
      <div className="row">
        <a href={chain.explorerUrl}>{chain.explorerText}</a>
        <div>
          {chains.map((c) => {
            if (c.id === chainId) return <strong key={c.id}>{c.name}</strong>;
            return (
              <a key={c.id} onClick={() => setChainId(c.id)}>
                {c.name}
              </a>
            );
          })}
        </div>
      </div>
      <p>Latest Bitcoin blocks. Live data from contract:</p>
      {status.chainId === chainId &&
        status.latestBlocks.map((b) => (
          <div key={b.height} className="row">
            <div>{b.height}.</div>
            <div>{b.hash}</div>
          </div>
        ))}
      {status.chainId !== chainId &&
        [...Array(numBlocksToShow).keys()].map(() => <div>loading...</div>)}
    </div>
  );
}
