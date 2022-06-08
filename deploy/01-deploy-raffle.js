const { network, ethers } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../helper-hardhat-config");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  let VRFCoordinatorV2Address;

  if (developmentChains.includes(network.name)) {
    const VRFCoordinatorV2Mock = await ethers.getContract(
      "VRFCoordinatorV2Mock"
    );
    VRFCoordinatorV2Address = VRFCoordinatorV2Mock.address;
  } else {
    VRFCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
  }
  const entranceFee = networkConfig[chainId]["entranceFee"];
  const gasLane = networkConfig[chainId]["gasLane"];
  const args = [VRFCoordinatorV2Address, entranceFee, gasLane];
  const raffle = await deploy("Raffle", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
};
