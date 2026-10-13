#!/usr/bin/env node
// Child1: compile with the WASM (solc-js) build of 0.6.12 and dump deployed bytecode.
const fs = require('fs');
const soljson = require('/tmp/opencode/soljson-v0.6.12.js');

const srcPath = process.argv[2];
const outPath = process.argv[3];
const text = fs.readFileSync(srcPath, 'utf8');

const input = {
  language: 'Solidity',
  sources: { 'BentoBoxFlat.sol': { content: text } },
  settings: {
    optimizer: { enabled: true, runs: 999999 },
    metadata: { bytecodeHash: 'ipfs' },
    outputSelection: { '*': { '*': ['evm.deployedBytecode.object', 'evm.deployedBytecode.immutableReferences', 'evm.bytecode.object'] } }
  }
};

const compile = soljson.cwrap('solidity_compile', 'string', ['string', 'number']);
const out = JSON.parse(compile(JSON.stringify(input), 0));
const errs = (out.errors || []).filter(e => e.severity === 'error');
if (errs.length) { console.error('solc errors', errs.map(e => e.formattedMessage).join('\n').slice(0, 800)); process.exit(1); }
const art = out.contracts['BentoBoxFlat.sol']['BentoBoxV1'];
fs.writeFileSync(outPath, JSON.stringify({ deployed: art.evm.deployedBytecode.object, creation: art.evm.bytecode.object, imm: art.evm.deployedBytecode.immutableReferences }, null, 1));
console.log('wasm compiled; deployed bytes:', art.evm.deployedBytecode.object.length / 2);
