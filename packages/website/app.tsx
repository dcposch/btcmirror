import * as React from "react";
import { CSSProperties, useEffect, useState } from "react";
import { render } from "react-dom";
import LiveStatus from "./LiveStatus";

render(<App />, document.querySelector("#root"));

function App() {
  return (
    <main>
      <Header />
      <br />
      <br />
      <LiveStatus />
      <Docs />
      <br />
      <br />
    </main>
  );
}

function Header() {
  const headerText = `









BITCOIN                                                   MIRROR
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
  const [loc, setLoc] = useState(-900);
  useEffect(() => {
    const onScroll = () => setLoc(Math.min(-900 + window.scrollY * 6, 0));
    window.addEventListener("scroll", onScroll);
  }, []);

  const percent = Math.exp(-(500 * 500) / (loc * loc)) * 100;
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
    <div className="hero">
      <pre style={{ position: "absolute", top: 0, textSizeAdjust: "none" }}>
        {headerText}
      </pre>
      <pre style={mirrorStyle}>{headerMirror}</pre>
    </div>
  );
}

function Docs() {
  return (
    <div className="docs">
      <h2>## BtcMirror is a Ethereum contract that tracks Bitcoin</h2>
      <p>
        This lets you prove that a BTC transaction executed, on Ethereum. In
        other words, it lets other Ethereum contracts run Simple Payment
        Verification (SPV) on BTC transactions.
      </p>
      <p>
        Anyone can submit block headers to BtcMirror. The contract verifies
        proof-of-work, keeping only the longest chain it has seen. As long as
        50% of Bitcoin hash power is honest and at least one person is running
        the <a href="https://github.com/dcposch/btcmirror">submitter script</a>,
        the BtcMirror contract always reports the current canonical Bitcoin
        chain.
      </p>
      <h2>## Example applications</h2>
      <p>
        <ol>
          <li>
            <em>Payment for Ethereum-based assets in Bitcoin.</em> For example,
            you can deploy an ERC721 that will mint an NFT to anyone who can
            prove they've sent x BTC to y address.
          </li>
          <li>
            <em>Trust-minimized BTC/ETH swaps.</em> Bob deploys an exchange
            contract and holds Bitcoin. To trade ETH to BTC, you first send ETH
            to the smart contract. By default, you can take it back a day later.
            To keep the ETH, Bob posts a proof that he's sent you the
            corresponding amount of BTC. The opposite direction is even easier.
            You send Bitcoin to Bob's address, then submit a proof to the
            exchange contract to claim ETH.
          </li>
          <li>
            <em>Proof of burn.</em> You burn 1 BTC. You post proof to a
            contract, which lets you mint 1 BBTC (burnt Bitcoin) on Ethereum 😈
          </li>
          <li>
            <em>Trust-minimized proof of reserve.</em> Currently, contracts like
            WBTC use oracles to prove their Bitcoin reserves. You could avoid
            trusted oracles using a balance-tracking contract. Anyone can submit
            SPV proofs of transactions to or from a given Bitcoin reserve
            address. The contract calls BtcMirror to verify the tx proofs and
            sums all transactions it's seen to track the current balance.
          </li>
        </ol>
      </p>
      <br />
      <div className="row">
        <div>
          🛠 built with <a href="https://github.com/gakonst/foundry">forge</a>{" "}
          and <a href="https://esbuild.github.io/">esbuild</a>
        </div>
        <a href="https://github.com/dcposch/btcmirror">view on Github</a>
      </div>
    </div>
  );
}
