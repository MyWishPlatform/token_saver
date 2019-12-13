const TokenSaver = artifacts.require("./TokenSaver.sol");
const ERC20 = artifacts.require("./ERC20.sol");

const timeHelper = require('../test/utils/utils.js');

(async function () {
    await timeHelper.revertToSnapShot('0x1');                        //Revert local ganache time
    console.log("Main Address:", await getAccount(0));
    console.log("Reserve Address:", await getAccount(1));
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

    deployer.deploy(TokenSaver, getAccount(0), getAccount(1),
    Math.floor(Date.now() / 1000) + 141000);
    console.log('TIME NOW:', Math.floor(Date.now() / 1000) + 144000);
    console.log('TIME NOW:', now = new Date());
    deployer.deploy(ERC20, 10000);

};


