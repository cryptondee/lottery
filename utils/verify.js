//verify contract to etherscan
const { run } = require("hardhat");

const verify = async (contractAddress, args) => {
  console.log("Verifying contract");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    e.message.toLowerCase().includes("already verified")
      ? console.log("Already verified")
      : console.log(e);
  }
};

module.exports = { verify };
