import { BigNumber, Contract, ethers } from "ethers";
import btcMirrorAbiJson = require("../out/BtcMirror.sol/BtcMirror.json");

// workaround forge bug https://github.com/gakonst/foundry/issues/457
const brokenAbi = btcMirrorAbiJson.abi;
const abi = brokenAbi.map((func) => Object.assign(func, { constant: null }));

export default class BtcMirrorContract {
  contract: Contract;

  constructor(rpcUrl: string, contractAddr: string) {
    const ethProvider = new ethers.providers.JsonRpcProvider(rpcUrl);
    this.contract = new Contract(contractAddr, abi, ethProvider);
  }

  /** Returns hash of block n in current canonical Bitcoin chain. */
  async getBlockHash(blockHeight: number): Promise<string> {
    const result = await this.contract.functions["getBlockHash"](blockHeight);
    console.log("getBlockHash", result);
    const hash = result[0] as string;
    return hash;
  }

  /** Returns the number of blocks in the current canonical Bitcoin chain. */
  async getLatestBlockHeight(): Promise<number> {
    const result = await this.contract.functions["getLatestBlockHeight"]();
    console.log("getLatestBlockHeight", result);
    const height = (result[0] as BigNumber).toNumber();
    return height;
  }
}
