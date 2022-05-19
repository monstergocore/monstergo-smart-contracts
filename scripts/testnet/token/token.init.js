var Web3 = require("web3");
var Tx = require("ethereumjs-tx").Transaction; //引入以太坊js交易支持
const BigNumber = require('bignumber.js');
const path = require('path');
const fs = require('fs')

let env = require('../../../env.json');
let contracts = require('../contracts.json');

let json_rpc_url = env.json_rpc;
let chainId = env.chainId;
let gasPriceGwei = 10;

web3 = new Web3(new Web3.providers.HttpProvider(json_rpc_url));

let PRIVATE_KEY = env.monsterGoOwnerPrivateKey;

let account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);
let from = account.address;
console.log(account.address);

const sourceContract = require('../../../build/contracts/MonsterGoToken.json');

let contractAddress = contracts.monster_token_addr;

var contract = new web3.eth.Contract(sourceContract.abi, contractAddress);

async function main()
{

  let lp_wallet_addr = contracts.lp_wallet_addr;
  let game_wallet_addr = contracts.game_wallet_addr;
  let trade_wallet_addr = contracts.trade_wallet_addr;
  let dao_wallet_addr = contracts.dao_wallet_addr;

  const data = contract.methods.initToken(lp_wallet_addr, game_wallet_addr,
            trade_wallet_addr, dao_wallet_addr).encodeABI();

  await packTransaction(data, contractAddress);
}


async function packTransaction(data, to, value=0)
{
  let priv_key = PRIVATE_KEY;
  let gasPrice = new BigNumber(await web3.eth.getGasPrice());
  gasPrice = gasPrice.multipliedBy(1.05).integerValue().toString(10)
  let nonce = await web3.eth.getTransactionCount(from, "pending");

  var rawTx = {
      nonce: web3.utils.toHex(nonce),
      gasPrice: gasPrice,
      to: to,
      from: from,
      value: web3.utils.toHex(value),
      data: data
  };

  // estimateGas
  rawTx.gas = new BigNumber(await web3.eth.estimateGas(rawTx))
    .multipliedBy(1.5)
    .integerValue();

  if (rawTx.gas.isLessThan(500000)) rawTx.gas = new BigNumber(500000);
  rawTx.gas = rawTx.gas.toString(10);

  let encodedTransaction = await web3.eth.accounts.signTransaction(
    rawTx,
    priv_key,
  );

  let rawTransaction = encodedTransaction.rawTransaction;

  let receipt =  await web3.eth.sendSignedTransaction(rawTransaction)
        .on('receipt', console.log);
}

main().catch(e => console.error(e));
