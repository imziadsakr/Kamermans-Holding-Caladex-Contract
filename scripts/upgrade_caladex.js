// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { getBeaconProxyFactory } = require("@openzeppelin/hardhat-upgrades/dist/utils");
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  // const [owner] = await hre.ethers.getSigners();
  // console.log(owner);
  // const address = '0x8464135c8F25Da09e49BC8782676a84730C318bC';
  const Caladex = await hre.ethers.getContractFactory("Caladex");
  console.log('Upgrading Caladex...');
  const caladex = await hre.upgrades.upgradeProxy('0xBA3Dd48Fc30D3264f32BB66fE00571d1C74FA714', Caladex);
  console.log("Caladex upgraded:", caladex.address);
  // const caladex = await Caladex.attach(address);
  // console.log(caladex);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
