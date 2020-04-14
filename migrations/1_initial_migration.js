const TokenSaverTest = artifacts.require("./contracts/TokenSaverTest.sol");
const ERC20 = artifacts.require("./ERC20.sol");
const timeHelper = require('../test/utils/utils.js');

(async function () {
    await timeHelper.revertToSnapShot('0x1');                           //revert time
})()

const getAccount = async (i) => {
    try {
        const myAccounts = await web3.eth.getAccounts();
        return myAccounts[i];
    } catch (err) {
        console.log(err);
    }
}

module.exports = async function (deployer) {
    deployer.deploy(TokenSaverTest, getAccount(0), getAccount(1),
        Math.floor(Date.now() / 1000) + 150000, getAccount(6), false);   // Data shift (+150000)
    deployer.deploy(ERC20, 10000);
};


