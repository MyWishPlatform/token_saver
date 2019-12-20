#!/usr/bin/env bash
./node_modules/.bin/c-preprocessor --config c-preprocessor-config.json Template.sol TokenSaver.sol
cp -f TokenSaver.sol `pwd`/contracts
./node_modules/.bin/truffle compile

