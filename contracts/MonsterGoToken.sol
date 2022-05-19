pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonsterGoToken is ERC20, Ownable {

    uint256 public total = 1000000000 * 1e18;

    address public burnAddr = address(0x000000000000000000000000000000000000dEaD);
    bool public isInit = false;

    constructor()
        ERC20("MonsterGo", "MG")
    public {

    }

    function initToken(address _lpOwner,
                address _gameOwner,
                address _tradeOwner,
                address _daoOwner) external onlyOwner {
          require(!isInit, "inited");
          isInit = true;
          _mint(burnAddr, total.mul(15).div(100));
          _mint(_lpOwner, total.mul(50).div(100));
          _mint(_gameOwner, total.mul(20).div(100));
          _mint(_tradeOwner, total.mul(10).div(100));
          _mint(_daoOwner, total.mul(5).div(100));
    }
}
