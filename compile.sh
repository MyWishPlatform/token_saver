#!/usr/bin/env bash
c-preprocessor --config c-preprocessor-config.json Template.sol TokenSaver.sol
mv TokenSaver.sol `pwd`/contracts
truffle compile 

