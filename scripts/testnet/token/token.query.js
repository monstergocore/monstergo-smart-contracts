var Web3 = require("web3");
var Tx = require("ethereumjs-tx").Transaction; //引入以太坊js交易支持

let env = require('../../../env.json');
let contracts = require('../contracts.json');

let json_rpc_url = env.json_rpc;
let chainId = env.chainId;

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
  let name = await contract.methods.name().call();
  console.log('name =>', name.toString());
  let symbol = await contract.methods.symbol().call();
  console.log('symbol =>', symbol.toString());

  let decimals = await contract.methods.decimals().call();
  console.log('decimals =>', decimals.toString());

  let totalSupply = await contract.methods.totalSupply().call();
  console.log('totalSupply=>', totalSupply / 10 ** decimals);

  let lp_wallet_addr = contracts.lp_wallet_addr;
  let game_wallet_addr = contracts.game_wallet_addr;
  let trade_wallet_addr = contracts.trade_wallet_addr;
  let dao_wallet_addr = contracts.dao_wallet_addr;
  let burn_addr = contracts.burn_addr;

  let LPAddrBalance = await contract.methods.balanceOf(lp_wallet_addr).call();
  console.log('LPAddrBalance =>', LPAddrBalance.toString() / 10 ** decimals);
  let gameAddrBalance = await contract.methods.balanceOf(game_wallet_addr).call();
  console.log('gameAddrBalance =>', gameAddrBalance.toString() / 10 ** decimals);
  let tradeAddrBalance = await contract.methods.balanceOf(trade_wallet_addr).call();
  console.log('tradeAddrBalance =>', tradeAddrBalance.toString() / 10 ** decimals);
  let daoAddrBalance = await contract.methods.balanceOf(dao_wallet_addr).call();
  console.log('daoAddrBalance =>', daoAddrBalance.toString() / 10 ** decimals);
  let burnAddrBalance = await contract.methods.balanceOf(burn_addr).call();
  console.log('burnAddrBalance =>', burnAddrBalance.toString() / 10 ** decimals);

}

main().catch(e => console.error(e));
