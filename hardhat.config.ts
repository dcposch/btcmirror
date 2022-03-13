require("@matterlabs/hardhat-zksync-deploy");
require("@matterlabs/hardhat-zksync-solc");

const { subtask } = require("hardhat/config");
const {
  TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS,
} = require("hardhat/builtin-tasks/task-names");

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(
  async ({} = {}, {} = {}, runSuper: () => Promise<string[]>) => {
    const paths = await runSuper();
    return paths.filter((p) => !p.endsWith(".t.sol"));
  }
);

const ethRpcUrl = process.env["ETH_RPC_URL_GOERLI"];
if (!ethRpcUrl) throw new Error("Missing ETH_RPC_URL_GOERLI");

module.exports = {
  zksolc: {
    version: "0.1.0",
    compilerSource: "docker",
    settings: {
      optimizer: { enabled: true },
      experimental: { dockerImage: "matterlabs/zksolc" },
    },
  },
  zkSyncDeploy: {
    zkSyncNetwork: "https://zksync2-testnet.zksync.dev",
    ethNetwork: ethRpcUrl,
  },
  networks: {
    hardhat: { zksync: true },
  },
  solidity: {
    version: "0.8.12",
  },
  paths: {
    cache: "hh-cache",
    sources: "contracts",
  },
};
