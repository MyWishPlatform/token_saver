#!/usr/bin/env bash
./node_modules/.bin/c-preprocessor --config c-preprocessor-config.json TemplateForTest.sol TokenSaverTest.sol
./node_modules/.bin/c-preprocessor --config c-preprocessor-config.json TemplateForDeploy.sol TokenSaver.sol
rm -rf `pwd`/contracts/TokenSaverTest.sol
rm -rf `pwd`/contracts/TokenSaver.sol
mv TokenSaverTest.sol `pwd`/contracts
mv TokenSaver.sol `pwd`/contracts
rm -rf `pwd`/build/contracts/TokenSaverTest.json
rm -rf `pwd`/build/contracts/TokenSaver.json
./node_modules/.bin/truffle compile 
