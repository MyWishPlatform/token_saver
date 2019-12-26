#!/usr/bin/env bash
c-preprocessor --config c-preprocessor-config.json TemplateForTest.sol TokenSaverTest.sol
c-preprocessor --config c-preprocessor-config.json TemplateForDeploy.sol TokenSaver.sol
mv TokenSaverTest.sol `pwd`/contracts
mv TokenSaver.sol `pwd`/contracts
rm -rf `pwd`/build/contracts/TokenSaverTest.json
rm -rf `pwd`/build/contracts/TokenSaver.json
truffle compile 
