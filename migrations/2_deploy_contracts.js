const TokenSaver = artifacts.require("TokenSaver");
const ERC20 = artifacts.require("ERC20");

const timeHelper = require("../test/utils/utils.js");

(async function() {
  await timeHelper.revertToSnapShot("0x1"); //revert time
})();

const getAccount = async i => {
  try {
    const myAccounts = await web3.eth.getAccounts();
    return myAccounts[i];
  } catch (err) {
    console.log(err);
  }
};

module.exports = async function(deployer) {
  deployer.deploy(
    TokenSaver,
    getAccount(0),
    getAccount(1),
    Math.floor(Date.now() / 1000) + 150000
  ); // Data shift
  console.log("TIME NOW:", (now = new Date()));
  deployer.deploy(ERC20, 10000);
};
