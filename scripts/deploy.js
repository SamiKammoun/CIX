// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const CIX = await hre.ethers.getContractFactory("CIX");
  const cix = await CIX.deploy(
    "0x3aaE94c45CA9B9020bC405Bc1a4D76aB9Bf1908F",
    "0x3aaE94c45CA9B9020bC405Bc1a4D76aB9Bf1908F",
    "0x3aaE94c45CA9B9020bC405Bc1a4D76aB9Bf1908F"
  );

  await cix.deployed();

  console.log("Contract deployed, address: ", cix.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
