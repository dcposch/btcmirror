# Bitcoin Mirror

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

 This lets you prove that a BTC transaction executed. In other words, it lets you run Simple Payment Verification (SPV) of BTC transactions on Ethereum.

## Quick Start

### Run the submitter

```
cd submitter
npm ci
npm run submit-xdai
```

You'll an address with a bit of xdai to pay transaction costs. Set `ETH_SUBMITTER_PRIVATE_KEY` accordingly.

You'll also need a free API key for [getblock.io](https://getblock.io). Set `GETBLOCK_API_KEY`.

### To compile and test the contract

Install [Forge](https://github.com/gakonst/foundry#-foundry-). Then:

```
make test
```
