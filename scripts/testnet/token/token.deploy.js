var Web3 = require("web3");
var Tx = require("ethereumjs-tx").Transaction; //引入以太坊js交易支持
const BigNumber = require('bignumber.js');

let env = require('../../../env.json');
let contracts = require('../contracts.json');

let json_rpc_url = env.json_rpc;
let chainId = env.chainId;

console.log(json_rpc_url);
web3 = new Web3(new Web3.providers.HttpProvider(json_rpc_url));

let PRIVATE_KEY = env.monsterGoOwnerPrivateKey;

let account = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);

console.log(account.address);

let swapRouterAddr = contracts.swaprouter_addr;
let busdAddr = contracts.busd_addr;

const sourceContract = require('../../../build/contracts/MonsterGoToken.json');

var contract = new web3.eth.Contract(sourceContract.abi, null, {
    from: account.address
});

let from = account.address;

let data = contract.deploy({
    data: sourceContract.bytecode,
    arguments: []
}).encodeABI();

//
async function main()
{
    let priv_key = PRIVATE_KEY;
    let gasPrice = new BigNumber(await web3.eth.getGasPrice());
    gasPrice = gasPrice.multipliedBy(1.05).integerValue().toString(10)
    let nonce = await web3.eth.getTransactionCount(from, "pending");
    console.log('nonce =>', nonce);

    var rawTx = {
        nonce: web3.utils.toHex(nonce),
        gasPrice: gasPrice,
        to: undefined,
        from: from,
        value: '0x00',
        data: data
    };

    // estimateGas
    rawTx.gas = new BigNumber(await web3.eth.estimateGas(rawTx))
      .multipliedBy(1.5)
      .integerValue();

    if (rawTx.gas.isLessThan(500000)) rawTx.gas = new BigNumber(500000);
    rawTx.gas = rawTx.gas.toString(10);
    console.log(rawTx);

    let encodedTransaction = await web3.eth.accounts.signTransaction(
      rawTx,
      priv_key,
    );

    let rawTransaction = encodedTransaction.rawTransaction;

    let receipt = await web3.eth.sendSignedTransaction(rawTransaction)
      .on('receipt', console.log);

    console.log('SMON createContractAddress =>', receipt.contractAddress.toLowerCase());
}

main().catch(e => console.error(e));
