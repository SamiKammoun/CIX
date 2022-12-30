// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer, account1] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const CIX = await hre.ethers.getContractFactory("CIX");
  const cix = await CIX.deploy(deployer.address, deployer.address, deployer.address);

  await cix.deployed();
  console.log("Contract deployed, address: ", cix.address);

  const CIXBurner = await hre.ethers.getContractFactory("Burner");
  const cixBurner = await CIXBurner.deploy(cix.address);

  await cixBurner.deployed();

  console.log("Burner deployed, address: ", cixBurner.address);

  await cix.grantRole("0x0000000000000000000000000000000000000000000000000000000000000001", cixBurner.address);

  await cix.mint(cixBurner.address, "1000000000000000000000000000");
  await cixBurner.connect(account1).burn(cixBurner.address, "1000000000000000000000000000");

  console.log("Burner role granted to: ", cixBurner.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
