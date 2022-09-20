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

```
cd packages/submitter
npm ci
npm run submit-ropsten
```

You'll an address with a bit of xdai to pay transaction costs. Set `ETH_SUBMITTER_PRIVATE_KEY` accordingly.

You'll also need a free API key for [getblock.io](https://getblock.io). Set `GETBLOCK_API_KEY`.

### Run the website

```
cd packages/website
npm ci
npm start
```
