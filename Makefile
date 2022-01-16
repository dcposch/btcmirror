.PHONY: test build deploy deploy-main

# TOP-LEVEL COMMANDS

test:
	forge test --force

build: out/BtcMirror.sol/BtcMirror.json

deploy: out/deploy-ropsten

deploy-arb: out/deploy-arbitrum

deploy-xdai: out/deploy-xdai

deploy-main: out/deploy-mainnet

#  FILE GENERATORS

out/BtcMirror.sol/BtcMirror.json: src/*.sol
	forge build --force

out/deploy-ropsten: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=$(ETH_RPC_URL_ROPSTEN) forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-ropsten

out/deploy-arbitrum: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=$(ETH_RPC_URL_ARBITRUM) forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-arbitrum

out/deploy-optimism: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=$(ETH_RPC_URL_OPTIMISM) forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-optimism

out/deploy-xdai: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=https://rpc.xdaichain.com/ forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-xdai

out/deploy-mainnet: out/BtcMirror.sol/BtcMirror.json
	forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY)