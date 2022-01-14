.PHONY: test build deploy deploy-main

# TOP-LEVEL COMMANDS

test:
	forge test --force

build: out/BtcMirror.sol/BtcMirror.json

deploy: out/deploy-ropsten

deploy-main: out/deploy-mainnet

#  FILE GENERATORS

out/BtcMirror.sol/BtcMirror.json: src/*.sol
	forge build --force --optimize

out/deploy-ropsten: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=${ETH_RPC_URL_ROPSTEN} forge create src/BtcMirror.sol:BtcMirror --private-key ${ETH_DEPLOYER_PRIVATE_KEY} | tee out/deploy-ropsten

out/deploy-mainnet: build
	forge create src/BtcMirror.sol:BtcMirror --private-key ${ETH_DEPLOYER_PRIVATE_KEY}