const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CIX", function () {
  it("Deployment should assign contract creator as owner", async function () {
    const [account0, account1, account2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("CIX");
    const cix = await Contract.deploy();
    expect(await cix.owner()).to.equal(account0.address);
  });
  it("Should mint tokens", async () => {
    const Contract = await ethers.getContractFactory("CIX");
    const cix = await Contract.deploy();
    expect((await cix.totalSupply()).toString()).to.equal("2400000000000000000000000000");
  });
  it("Should be able to transfer ownership", async () => {
    const [account0, account1, account2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("CIX");
    const cix = await Contract.deploy();
    await cix.transferOwnership(account1.address);
    expect(await cix.owner()).to.equal(account1.address);
  });
});
