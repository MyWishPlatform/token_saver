const assertRevert = require('./utils/assertRevert').assertRevert;
const timeHelper = require('./utils/utils.js');
const TokenSaver = artifacts.require("./TokenSaver.sol");
const ERC20 = artifacts.require("./ERC20.sol");

const totalERC20Contracts = 1;                                        // number of ERC20 tokens to create

contract('TokenSaver/ERC20', async (accounts) => {

    let tokenSaverAddress;
    let reserveAddress;
    let instanceERC20 = [];
    let instance;
    let blockNumber;

    beforeEach(async () => {
        instance = await TokenSaver.deployed();
    });

    console.log('\n------------------------------ERC20-Deployment-------------------------------------');
    for (let i = 0; i < totalERC20Contracts; i++) {

        it('ERC20 №' + i + ' Deployed', async () => {
            instanceERC20[i] = await ERC20.new(10000, { from: accounts[0] });
            await console.log('---------------------------------------------------');
            console.log("ERC20 №" + i + " address:", instanceERC20[i].address);
            assert.notEqual(instanceERC20[i].address, '',"No instance detected");
        })

        it('ERC20 №' + i + ' should have 10000 tokens on main balance', async () => {
            let balance = await instanceERC20[i].balanceOf(accounts[0], { from: accounts[0] }, function (error, result) {
                if (!error) {
                    console.log("Main Address Balance:", result);
                }
            });
            assert.equal(balance, 10000, "Initial balance is incorrect");
        })
    }

    it('Correct number of ERC20 instances (should be ' + totalERC20Contracts + ')', async () => {
        assert.equal(instanceERC20.length, totalERC20Contracts, "Total number of instances is incorrect");
    })

    it('TokenSaver deployed', async () => {
        tokenSaverAddress = TokenSaver.address;
        console.log('\n----------------------------TokenSaver-Deployment----------------------------------\n');
        console.log("Token Saver Address: ", TokenSaver.address);
        console.log("Hash: ", TokenSaver.transactionHash);
        blockNumber = await web3.eth.getBlockNumber(function (error, result) {
            if (!error)
                console.log("Block number => ", result)
            web3.eth.getBlock(result, (error, block) => {
                console.log("Block Time => ", block.timestamp);
                const date = new Date(block.timestamp * 1000);
                console.log(date.toUTCString());
            });
        });
        assert.notEqual(instance.address, '', "Deployment error");
    })

    it('Valid timestamp', async () => {
        const stamp = await instance.endTimestamp.call(web3.eth.accounts[0]);
        assert(stamp > Math.floor(Date.now() / 1000), "Time should be greater than now");
    })

    it('Valid main address', async () => {
        await instance.owner.call(web3.eth.accounts[0]).then(function (result) {
            assert.equal(result, accounts[0], "Invalid address");
        })
    })

    it('Valid reserve address', async () => {
        await instance.reserveAddress.call(web3.eth.accounts[0]).then(function (result) {
            reserveAddress = result;
            assert.equal(result, accounts[1], "Invalid address");
        })
    })

    for (let i = 0; i < totalERC20Contracts; i++) {
        it('Grant allowance to TokenSaver (should be 5000)', async () => {
            console.log('TOKEN №' + i + ':', instanceERC20[i].address)
            await instanceERC20[i].approve(tokenSaverAddress, 5000, { from: accounts[0] });
            await instanceERC20[i].allowance.call(accounts[0], tokenSaverAddress, {
                from: accounts[0],
                gas: 5000000
            }, function (error, result) {
                if (!error) {
                    console.log('Allowance:', result);
                    console.log('------------------------------------------------------');
                    assert(result > 0, "Not approved");
                }
            })
        })
    }

    it('Add token types to Saver from incorrect address (should revert)', async () => {
        for (let i = 0; i < instanceERC20.length; i++) {
            await assertRevert(instance.addTokenType(instanceERC20[i].address, { from: accounts[3] })
                , "Execution succeeded")
        }
    })

    it('Add token types to Saver (from backend)', async () => {
        for (let i = 0; i < instanceERC20.length; i++) {
            await instance.addTokenType(instanceERC20[i].address, { from: accounts[0] }).then(function (result) {
                console.log('Add Token №' + i + ': Success!');
                assert.equal(result.receipt.status, true, "Token type has been rejected");
            })
        }
    })

    let eventList;
    it('All token instances have been added', async () => {
        const EXPECTED_AMOUNT = totalERC20Contracts;
        const options = { fromBlock: blockNumber, toBlock: 'latest' }

        eventList = await instance.getPastEvents('TokensToSave', options);
        console.log('TYPES ADDED:', eventList.length)
        assert.equal(eventList.length, EXPECTED_AMOUNT, "Incorrect amount");
    })

    it('Try to add token that has been added before (should revert)', async () => {
        await assertRevert(instance.addTokenType(instanceERC20[0].address, { from: accounts[0] })
            , "Token has been added")
    })

    it('Check if total amount of token types is not exceeded', async () => {
        const EXPECTED_AMOUNT = 30;
        assert(eventList.length <= EXPECTED_AMOUNT, "More than 30");
    })

    it('Transfer 500 tokens to Saver', async () => {
        for (let i = 0; i < instanceERC20.length; i++) {
            await instanceERC20[i].transfer(tokenSaverAddress, 500, { from: accounts[0] }).then(function (error, result) {
            })
            await instanceERC20[i].balanceOf(tokenSaverAddress, { from: accounts[0] }, function (error, result) {
                if (!error) {
                    console.log("TokenSaver balance №" + i + ":", result);
                    assert.equal(result, 500, "Failed to transfer tokens");
                }
            });
        }
    })

    it('Execute token transfer before the correct date (should revert) ', async () => {
        await instance.endTimestamp.call(web3.eth.accounts[0]).then(function (result) {
            const date = new Date(result * 1000);
            console.log('EXECUTION DATE IN CONTRACT:', date.toUTCString());
        })
        await assertRevert(web3.eth.sendTransaction({
            from: accounts[0],
            to: TokenSaver.address,
            gas: 6000000
        }), "Execution succeeded");

    })

    it('Execute token transfer at correct time', async () => {
        let now = new Date();
        advancement = 86400 * 10 // 10 Days
        await timeHelper.advanceTimeAndBlock(advancement);
        await web3.eth.sendTransaction({
            from: accounts[0],
            to: TokenSaver.address,
            gas: 6000000
        }).then(function (result) {
            if (result) {
                console.log('------------------------------------------------------------------------');
                console.log("Token transfer succeeded!");
                console.log("GAS USED:", result.gasUsed);
                assert.notEqual(result.transactionHash, '', "Failed to save tokens");
                console.log('------------------------------------------------------------------------');
            }
        });
    })

    for (let i = 0; i < totalERC20Contracts; i++) {
        it('Check balances of reserve address (should have 5500)', async () => {
            await instanceERC20[0].balanceOf(reserveAddress, { from: accounts[0] }, function (error, result) {
                if (!error) {
                    console.log("Reserve address balance №" + i + " (" + instanceERC20[i].address + "): ", result);
                    assert.equal(result, 5500, "Failed to save tokens");
                }
            });
        })
    }

    it('Try to destroy contract from incorrect address (should revert)', async () => {
        console.log('------------------------------------------------------------------------');
        await assertRevert(instance.selfdestruction({ from: accounts[3] }).then(function (error, result) { })
            , "Execution succeeded")
    })

    it('Self destruction done!', async () => {
        await instance.selfdestruction({ from: accounts[0] }).then(function (error, result) { })

        const EXPECTED = true;
        const options = { fromBlock: blockNumber, toBlock: 'latest' }
        const event = await instance.getPastEvents('SelfdestructionEvent', options);
        assert.equal(event[0].returnValues._status, EXPECTED, "");
    })

})
