.PHONY: test build deploy clean

# TOP-LEVEL COMMANDS

test:
	forge test --force

build: out/BtcMirror.sol/BtcMirror.json

deploy: out/deploy-zksync2

clean:
	rm -rf out

#  FILE GENERATORS

out/BtcMirror.sol/BtcMirror.json: src/*.sol
	forge build --force
	cp out/BtcMirror.sol/BtcMirror.json abi/

out/deploy-ropsten: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=$(ETH_RPC_URL_ROPSTEN) forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-ropsten

out/deploy-arbitrum: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=$(ETH_RPC_URL_ARBITRUM) forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-arbitrum

out/deploy-optimism: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=$(ETH_RPC_URL_OPTIMISM) forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-optimism

out/deploy-xdai: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=https://rpc.xdaichain.com/ forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-xdai

out/deploy-zksync2: out/BtcMirror.sol/BtcMirror.json
	ETH_RPC_URL=https://zksync2-testnet.zksync.dev forge create -vvv src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY) | tee out/deploy-zksync2

out/deploy-mainnet: out/BtcMirror.sol/BtcMirror.json
	forge create src/BtcMirror.sol:BtcMirror --private-key $(ETH_DEPLOYER_PRIVATE_KEY)