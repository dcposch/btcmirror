import * as React from "react";
import { CSSProperties, useEffect, useMemo, useState } from "react";
import ReactDOM from "react-dom";
import LiveStatus from "./LiveStatus";

ReactDOM.render(<App />, document.querySelector("#root"));

function App() {
  return (
    <main>
      <Header />
      <LiveStatus />
      <Docs />
    </main>
  );
}

function Header() {
  const headerText = `









BITCOIN                                                                   MIRROR
  `;

  const headerMirror = `
                                        #
                                       # #
                                      # # #
                                     # # # # 
                                    # # # # #
                                   # # # # # #
                                  # # # # # # # 
                                 # # # # # # # # 
                                # # # # # # # # # 
                               # # # # # # # # # #
                              # # # # # # # # # # #
                                   # # # # # # 
                               +        #        +
                                ++++         ++++
                                  ++++++ ++++++
                                    +++++++++
                                      +++++
                                        +
    `;

  // mirror effect
  const [loc, setLoc] = useState([0, 0]);
  const onMove = (ev: MouseEvent) => setLoc([ev.clientX, ev.clientY]);
  useEffect(() => document.addEventListener("mousemove", onMove), []);

  const percent =
    Math.exp(-(500 * 500) / Math.pow(loc[1] - loc[0] - 500, 2)) * 100;
  const gradientStops = [
    `#999 ${percent - 10}%`,
    `#bbb ${percent - 5}%`,
    `#fff ${percent + 0}%`,
    `#bbb ${percent + 5}%`,
    `#777 ${percent + 10}%`,
  ];
  const mirrorStyle: CSSProperties = {
    backgroundImage: `linear-gradient(45deg, ${gradientStops.join(", ")})`,
    backgroundClip: "text",
    WebkitBackgroundClip: "text",
    color: "transparent",
  };

  return (
    <header>
      <pre style={{ position: "absolute", top: 0 }}>{headerText}</pre>
      <pre style={mirrorStyle}>{headerMirror}</pre>
    </header>
  );
}

function Docs() {
  return (
    <article>
      <h2>## BtcMirror is a EVM contract that tracks Bitcoin</h2>
      <p>
        This lets you prove that a BTC transaction executed, on Ethereum. In
        other words, it lets other Ethereum contracts run Simple Payment
        Verification (SPV) of BTC transactions.
      </p>
      <p>
        Anyone can submit block headers to BtcMirror. The contract verifies
        proof-of-work, keeping only the longest chain it has seen. As long as
        50% of Bitcoin hash power is honest and at least one person is running
        the <a href="https://github.com/dcposch/btcmirror">submitter script</a>,
        the BtcMirror contract always reports the current canonical Bitcoin
        chain.
      </p>
      <p></p>
      <h2>## Example applications</h2>
      <ol>
        <li>
          Taking payment for Ethereum-based assets in Bitcoin. For example, you
          can deploy an ERC721 that will mint an NFT to anyone who can prove
          they've sent x BTC to y address.
        </li>
        <li>
          Trust-minimized BTC/ETH swaps. XYZ Inc deploys an exchange contract
          and holds Bitcoin. To trade ETH to BTC, you first send ETH to the
          smart contract; by default, you can withdraw it again a day later. To
          keep the ETH, XYZ Inc posts a proof that they've sent you the
          corresponding amount of BTC. The opposite direction is even cleaner.
          You send Bitcoin to XYZ Inc's addesss, then submit a proof to the
          exchange contract to claim ETH.
        </li>
        <li>
          Proof of burn. You burn 1 BTC. You post proof to a contract, which
          lets you mint 1 BBTC (burnt Bitcoin) on Ethereum.
        </li>
        <li>
          Bitcoin derivatives. For example, you can report the current Bitcoin
          hashrate without requiring a trusted oracle.
        </li>
        <li>
          Trust-minimized proof of reserve. Currently, contracts like WBTC use
          oracles to prove their Bitcoin reserves. You could avoid trusted
          oracles using a balance-tracking contract. Anyone can submit SPV
          proofs of transactions to or from a given Bitcoin reserve address. The
          contract calls BtcMirror to verify the tx proofs and sums all
          transactions it's seen to track the current balance.
        </li>
      </ol>
    </article>
  );
}
