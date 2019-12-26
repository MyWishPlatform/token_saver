#!/usr/bin/env bash
c-preprocessor --config c-preprocessor-config.json TestTemplate.js mainTest.js
mv mainTest.js `pwd`/test
truffle test
