# Bitcoin Mirror

**[bitcoinmirror.org](https://bitcoinmirror.org)**

```
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
```

## Bitcoin Mirror tracks Bitcoin on Ethereum

This lets you prove a Bitcoin payment. In other words, it's a Bitcoin light client that runs on the EVM.

## Quick Start

### Compile and test the contract

Install [Forge](https://getfoundry.sh/). Then:

```
cd packages/contracts
forge test -vv
```

### Run the submitter

Point Cloudflare Functions to your fork of the repo using `wrangler`.

The submitter will run automatically and reliably, on a schedule. See `wrangler.toml`.

You'll need to configure a few secrets, including `ETH_SUBMITTER_PRIVATE_KEY` and `ETH_RPC_URL`. You'll also need a free API key for [getblock.io](https://getblock.io). Set `GETBLOCK_API_KEY`.

### Run the website

```
cd packages/website
npm ci
npm start
```

### Deploy the contract

```
cd packages/contracts
forge script -f $RPC_URL --private-key $PK DeployBtcMirror -- true
```

Run with `false` for a deployment tracking the Bitcoin testnet rather than mainnet. Either way, `$RPC_URL` determines which Ethereum network you're deploying to.

Then, ensure `ETHERSCAN_API_KEY` is set, and run the following to verify.

```
forge script --verify DeployBtcMirror -- <true or false, as above>
```
