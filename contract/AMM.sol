// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
// import "math.sol";
// import "hardhat/console.sol";

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    function mint(uint amount) external;
    function burn(uint amount) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Amm {
    uint public samuraiCoinTotalSupply;
    uint public commandoCoinTotalSupply;
    uint public lpTokenTotalSupply;
    uint public dexFeePercent = 2;
    address[] public lpProviders;
    uint private product;
    uint private temp;
    address samuraiCoinAddress;
    address commandoCoinAddress;
    address lpTokenAddress;
    address public owner;
    uint private lp_index;


    constructor(address _samuraiCoinAddress, address _commandoCoinAddress, address _lpTokenAddress) {
        samuraiCoinAddress = address(_samuraiCoinAddress);
        commandoCoinAddress = address(_commandoCoinAddress);
        lpTokenAddress = address(_lpTokenAddress);
        owner = (msg.sender);
    }
    
    function swap(address tokenA, address tokenB, uint amount) public {
        require((tokenA == samuraiCoinAddress) || (tokenA == commandoCoinAddress), "token A is neither Commando coin nor Warrior coin");
        require((tokenB == samuraiCoinAddress) || (tokenB == commandoCoinAddress), "token B is neither Commando coin nor Warrior coin");
        IERC20 tokA = IERC20(tokenA);
        IERC20 tokB = IERC20(tokenB);
        uint dexFee = dexFeePercent * amount; // calculated in units of token A
        uint _amount = amount - dexFee/100;
        tokA.transferFrom(msg.sender, address(this), dexFee/100);
        product = samuraiCoinTotalSupply * commandoCoinTotalSupply;
        if (tokenA == samuraiCoinAddress) {
            samuraiCoinTotalSupply = samuraiCoinTotalSupply + _amount + dexFee/100;
            temp = commandoCoinTotalSupply - (product/samuraiCoinTotalSupply);
            require(tokA.balanceOf(msg.sender) >= amount, "You have insufficient funds");
            tokA.transferFrom(msg.sender, address(this), _amount);
            require(tokB.balanceOf(address(this)) >= temp, "AMM contract does not have sufficient liquidity");
            tokB.transfer(msg.sender, temp);
            commandoCoinTotalSupply = commandoCoinTotalSupply - temp;
        } 
        else if (tokenA == commandoCoinAddress) {
            commandoCoinTotalSupply = commandoCoinTotalSupply + _amount + dexFee/100;
            temp = samuraiCoinTotalSupply - (product/commandoCoinTotalSupply);
            require(tokA.balanceOf(msg.sender) >= amount, "You have insufficient funds");
            tokA.transferFrom(msg.sender, address(this), _amount);
            require(tokB.balanceOf(address(this)) >= temp, "AMM contract does not have sufficient liquidity");
            tokB.transfer(msg.sender, temp);
            samuraiCoinTotalSupply = samuraiCoinTotalSupply - temp;
        }
    }

    function removeLiquidity(uint _ghiCoinAmount) public payable  {
        //check needs to be added that this is only called by an external lp provider
        IERC20 samuraiCoin = IERC20(samuraiCoinAddress);
        IERC20 commandoCoin = IERC20(commandoCoinAddress);
        IERC20 lpToken = IERC20(lpTokenAddress);
        require(lpToken.balanceOf(msg.sender) >= _ghiCoinAmount, "You have insufficient funds");
        lpToken.transferFrom(msg.sender, address(this), _ghiCoinAmount);
        lpToken.burn(_ghiCoinAmount);
        uint percent = (_ghiCoinAmount*100)/lpTokenTotalSupply;
        lpTokenTotalSupply -= _ghiCoinAmount;
        uint samuraiCoinTransferAmount = (percent * samuraiCoinTotalSupply)/100;
        uint commandoCoinTransferAmount = (percent * commandoCoinTotalSupply)/100;
        samuraiCoin.transfer(msg.sender, samuraiCoinTransferAmount); //need to check logic once
        commandoCoin.transfer(msg.sender, commandoCoinTransferAmount);
        samuraiCoinTotalSupply -= samuraiCoinTransferAmount;
        commandoCoinTotalSupply -= commandoCoinTransferAmount;
        product = samuraiCoinTotalSupply * commandoCoinTotalSupply;
        // if(lpToken.balanceOf(msg.sender)==0){
        //     lp_index = indexOf(lpProviders, msg.sender);
        //     delete lpProviders[lp_index];
        // }
    }

    function addLiquidity(uint _samuraiCoinAmount, uint _commandoCoinAmount) public payable {
        IERC20 samuraiCoin = IERC20(samuraiCoinAddress);
        IERC20 commandoCoin = IERC20(commandoCoinAddress);
        require(samuraiCoin.allowance(msg.sender, address(this))>=_samuraiCoinAmount, "Please approve before adding liquidity");
        require(samuraiCoin.balanceOf(msg.sender) >= _samuraiCoinAmount, "You have insufficient funds");
        samuraiCoin.transferFrom(msg.sender, address(this), _samuraiCoinAmount);
        require(commandoCoin.allowance(msg.sender, address(this))>=_commandoCoinAmount, "Please approve before adding liquidity");
        require(commandoCoin.balanceOf(msg.sender) >= _commandoCoinAmount, "You have insufficient funds");
        commandoCoin.transferFrom(msg.sender, address(this), _commandoCoinAmount);
        samuraiCoinTotalSupply += _samuraiCoinAmount;
        commandoCoinTotalSupply += _commandoCoinAmount;
        IERC20 lpToken = IERC20(lpTokenAddress);
        lpToken.mint(sqrt(_samuraiCoinAmount * _commandoCoinAmount)); // need to provide access to amm contract to mint lp token
        lpTokenTotalSupply+= sqrt(_samuraiCoinAmount * _commandoCoinAmount);
        lpToken.transfer(msg.sender, sqrt(_samuraiCoinAmount * _commandoCoinAmount));
        product = samuraiCoinTotalSupply * commandoCoinTotalSupply;
        lpProviders.push(msg.sender);
    }

    function getSwappedAmount(address tokenA, uint amountA) external view returns (uint amountB) {
        require(tokenA == address(samuraiCoinAddress) || tokenA == address(commandoCoinAddress), "Token to be swapped is neither Commando coin neither Warrior coin");
        uint amountAfterFee = (amountA * 997)/1000;

        if (tokenA == samuraiCoinAddress) {
            uint newsamuraiCoinTotalSupply = samuraiCoinTotalSupply + amountAfterFee;
            return commandoCoinTotalSupply - (product/newsamuraiCoinTotalSupply);
        } else if (tokenA == commandoCoinAddress) {
            uint newcommandoCoinTotalSupply = commandoCoinTotalSupply + amountAfterFee;
            return samuraiCoinTotalSupply - (product/newcommandoCoinTotalSupply);
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

    function indexOf(address[] memory arr, address searchFor) private pure returns (uint256) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
        return i;
      }
    }
    revert("Not Found");
  }

}
