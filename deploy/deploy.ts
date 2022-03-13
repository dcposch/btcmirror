import { utils, Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import fs from "fs";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Deploying to zkSync2`);

  // Initialize the wallet.
  const deployerPK = process.env["ETH_DEPLOYER_PRIVATE_KEY"];
  if (!deployerPK) throw new Error("Missing ETH_DEPLOYER_PRIVATE_KEY");
  const wallet = new Wallet(deployerPK);

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("BtcMirror");
  let l2Balance = await printBalances(deployer);

  // Deposit some funds to L2 in order to be able to perform L2 transactions.
  const depositAmount = ethers.utils.parseEther("0.001");
  if (l2Balance.lt(depositAmount)) {
    console.log("Depositing to L2...");
    const depositHandle = await deployer.zkWallet.deposit({
      to: deployer.zkWallet.address,
      token: utils.ETH_ADDRESS,
      amount: depositAmount,
    });
    await depositHandle.wait();
    l2Balance = await printBalances(deployer);
  }
  if (l2Balance.lt(depositAmount)) {
    console.log("❌ deployer balance insufficient");
    return;
  }
  console.log("✅ deployer balance looks good");

  // Deploy the contract.
  const contract = await deployer.deploy(artifact, []);
  console.log(`✅  ${artifact.contractName} deployed to ${contract.address}`);

  const outputFile = "out/deploy-zksync2";
  fs.writeFileSync(outputFile, contract.address + "\n");
  console.log(`✅  wrote ${outputFile}`);
}

async function printBalances(deployer: Deployer) {
  const l2Balance = await deployer.zkWallet.getBalance();
  const l1Balance = await deployer.zkWallet.getBalanceL1();
  console.log(`Deployer L1 bal: ${ethers.utils.formatEther(l1Balance)} ETH`);
  console.log(`Deployer L2 bal: ${ethers.utils.formatEther(l2Balance)} ETH`);
  return l2Balance;
}
