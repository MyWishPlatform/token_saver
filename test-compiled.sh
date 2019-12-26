#!/usr/bin/env bash
c-preprocessor --config c-preprocessor-config.json TestTemplate.js mainTest.js
ganache-cli &
mv mainTest.js `pwd`/test
truffle test
lsof -i :8545 -sTCP:LISTEN |awk 'NR > 1 {print $2}'  |xargs kill -15
