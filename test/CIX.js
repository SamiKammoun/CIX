const { expect } = require("chai");
const { ethers } = require("hardhat");

const ADMIN = ethers.utils.formatBytes32String(0x0000000000000000000000000000000000000000000000000000000000000000);
const MINTER = ethers.utils.formatBytes32String(0x0000000000000000000000000000000000000000000000000000000000000002);
const BURNER = ethers.utils.formatBytes32String(0x0000000000000000000000000000000000000000000000000000000000000001);

const deploy = async () => {
  //getting accounts
  const [admin, minter, burner] = await ethers.getSigners();
  //deploying contract
  const Contract = await ethers.getContractFactory("CIX");
  const cix = await Contract.deploy(admin.address, minter.address, burner.address);
  return { admin, minter, burner, cix };
};

describe("CIX", function () {
  it("Deployment should assign contract creator as admin", async function () {
    const { admin, minter, burner, cix } = await deploy();

    expect(await cix.hasRole(ADMIN, admin.address)).to.equal(true);
  });

  it("total supply should be set to 2,4 billion", async () => {
    const { admin, minter, burner, cix } = await deploy();

    expect((await cix.totalSupply()).toString()).to.equal("2400000000000000000000000000");
  });

  it("Only minter should be able to mint", async () => {
    const { admin, minter, burner, cix } = await deploy();

    //trying to mint with admin or burner
    await expect(cix.connect(burner).mint(burner.address, "3333")).to.be.reverted;
    await expect(cix.connect(admin).mint(admin.address, "3333")).to.be.reverted;

    //minting as minter
    await expect(cix.connect(minter).mint(minter.address, "3333")).to.not.be.reverted;
    expect((await cix.totalSupply()).toString()).to.equal("2400000000000000000000003333");
  });

  it("Only burner should be able to burn", async () => {
    const { admin, minter, burner, cix } = await deploy();

    //making transfer to bypass _burn reverts
    await cix.connect(admin).transfer(minter.address, "3333");
    await cix.connect(admin).transfer(burner.address, "400000000000000000000000000");

    //trying to burn as admin or minter
    await expect(cix.connect(admin).burn(admin.address, "3333")).to.be.reverted;
    await expect(cix.connect(minter).burn(minter.address, "3333")).to.be.reverted;

    //burning as burner
    await expect(cix.connect(burner).burn(burner.address, "400000000000000000000000000")).to.not.be.reverted;
    expect((await cix.totalSupply()).toString()).to.equal("2000000000000000000000000000");
  });

  it("Should be able to grant and revoke Administratorship", async () => {
    const { admin, minter, burner, cix } = await deploy();
    const account3 = (await ethers.getSigners())[3];

    //granting admin permissions to account3
    await cix.connect(admin).grantRole(ADMIN, account3.address);
    expect(await cix.hasRole(ADMIN, account3.address)).to.equal(true);

    //revoking own admin permission for admin
    await cix.connect(admin).revokeRole(ADMIN, admin.address);
    expect(await cix.hasRole(ADMIN, admin.address)).to.equal(false);
  });

  it("only Admin can revoke permissions of burner and minter", async () => {
    const { admin, minter, burner, cix } = await deploy();

    //admin revokes minter permission for minter
    expect(async () => await cix.connect(admin).revokeRole(MINTER, minter.address)).to.change(
      async () => await cix.hasRole(MINTER, minter.address)
    );

    //admin revokes burner permission for burner
    expect(async () => await cix.connect(admin).revokeRole(BURNER, burner.address)).to.change(
      async () => await cix.hasRole(BURNER, burner.address)
    );

    //minter cannot revoke burner's permission
    expect(async () => await cix.connect(minter).revokeRole(BURNER, burner.address)).to.be.reverted;

    //burner cannot revoke minter's permission
    expect(async () => await cix.connect(burner).revokeRole(MINTER, minter.address)).to.be.reverted;
  });

  it("Should be able to renounce own permission", async () => {
    const { admin, minter, burner, cix } = await deploy();

    //minter renounces his own permission
    expect(async () => await cix.connect(minter).renounceRole(MINTER, minter.address)).to.change(
      async () => await cix.hasRole(MINTER, minter.address)
    );

    //burner renounces his own permission
    expect(async () => await cix.connect(burner).renounceRole(BURNER, burner.address)).to.change(
      async () => await cix.hasRole(BURNER, burner.address)
    );
  });
});
