// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Caladex is Ownable{

    struct Stake{
        uint256 id;
        address staker;
        address token;
        uint256 amount;
        string created_at;
        uint expiration;
        uint estApy;
        bool isCommitted;
    }
    
    address public caladex_address;
    mapping(address => mapping( bytes32 => uint256) ) public dex_balances;
    mapping(address => mapping( bytes32 => uint256) ) public order_balances;
    mapping(uint256 => Stake) public _stakes;
    mapping(uint256 => uint256) public stake_balances;
    uint256 public stakeCount;

    constructor() {
        caladex_address = address(0x3eF06B33a583e1CA5c10a7CaeAe42427938a8F06);
    }

    event StakeCount(uint256 count);

    function sendViaTransfer() public payable {
        // This function is no longer recommended for sending Ether.
    }

    function deposit(address _token, bytes32 symbol, uint256 amount) public payable{
        bytes32  eth_data = "ETH";
        if(symbol == eth_data) {
            dex_balances[msg.sender][symbol] += msg.value;
            payable(caladex_address).transfer(amount);
            return;
        }
        require(IERC20(_token).balanceOf(msg.sender) >= amount, "underflow balance recipient");
        require(dex_balances[msg.sender][symbol] + amount >= dex_balances[msg.sender][symbol], "overflow balance recipient");
        require(IERC20(_token).transferFrom(msg.sender, caladex_address, amount), "Failed to return tokens to the investor");
        dex_balances[msg.sender][symbol] +=amount;
    }

    function withdraw(address _address, address token_address, bytes32 symbol, uint256 amount) public payable{
        bytes32  eth_data = "ETH";
        if(symbol == eth_data) {
            require(dex_balances[_address][symbol] - amount <= dex_balances[_address][symbol], "underflow balance recipient");
            payable(_address).transfer(amount);
            dex_balances[msg.sender][symbol] = dex_balances[msg.sender][symbol] - amount;
            return;
        }
        require(IERC20(token_address).approve(caladex_address, amount), "Failed to return tokens to the investor");
        require(IERC20(token_address).transferFrom(caladex_address, address(this), amount), "Failed to return tokens to the investor");
        uint256 balanceRecipient = IERC20(token_address).balanceOf(_address);

        require(balanceRecipient + amount >= balanceRecipient, "overflow balance recipient");
        require(dex_balances[_address][symbol] - amount <= dex_balances[_address][symbol], "underflow balance recipient");
        dex_balances[_address][symbol] = dex_balances[_address][symbol] - amount;
        require(IERC20(token_address).transfer(_address, amount), "Failed to return tokens to the investor");
    }

    function getBalance(address _address, bytes32 symbol) public view returns (uint256) {
        return dex_balances[_address][symbol];
    }

    function getOrderBalance(address _address, bytes32 symbol) public view returns (uint256) {
        return order_balances[_address][symbol];
    }

    function addStake(address _staker, address _token, bytes32 symbol,uint256 _amount, string memory _created_at, uint _expiration, uint _estApy) public onlyOwner {
        require(dex_balances[_staker][symbol] >= _amount, "underflow balance recipient");
        require(stake_balances[stakeCount] + _amount >= stake_balances[stakeCount], "overflow balance recipient");

        dex_balances[_staker][symbol] -= _amount;
        stake_balances[stakeCount] += _amount;

        Stake memory to = Stake(stakeCount, _staker, _token, _amount, _created_at, _expiration, _estApy, true);
        _stakes[stakeCount] = to;
        emit StakeCount(stakeCount);
        stakeCount++;
    }

    function unStake(address _address, bytes32 symbol, uint256 index, uint expired) public onlyOwner {
        require(_stakes[index].isCommitted == true, "already unstaked");
        require(stake_balances[index] > 0, "underflow balance recipient");

        _stakes[index].isCommitted = false;
        if(expired < _stakes[index].expiration) {
            dex_balances[_address][symbol] +=  _stakes[index].amount;
        } else {
            uint256 fee = _stakes[index].amount * _stakes[index].estApy * expired / 10000 / 365;
            dex_balances[_address][symbol] += (fee + _stakes[index].amount);
        }
    }

    function orderListing(address _address, bytes32 _symbol, uint256 _amount) public onlyOwner {
        require(dex_balances[_address][_symbol] >= _amount, "underflow balance recipient");
        require(order_balances[_address][_symbol] + _amount >= order_balances[_address][_symbol], "overflow balance recipient");

        dex_balances[_address][_symbol] -= _amount;
        order_balances[_address][_symbol] += _amount;
    }
    
    function cancelOrder(address _address, bytes32 _symbol, uint256 _amount) public onlyOwner {
        require(dex_balances[_address][_symbol] + _amount >= dex_balances[_address][_symbol], "overflow balance recipient");
        require(order_balances[_address][_symbol] >= _amount, "underflow balance recipient");

        dex_balances[_address][_symbol] += _amount;
        order_balances[_address][_symbol] -= _amount;
    }

    function limitExchange(address _address0, bytes32 _symbol0, uint256 _amount0, address _address1, bytes32 _symbol1, uint256 _amount1) public onlyOwner {
        require(dex_balances[_address0][_symbol0] >= _amount0, "underflow first balance recipient");
        require(order_balances[_address1][_symbol1] >= _amount1, "underflow second balance recipient");

        require(dex_balances[_address0][_symbol1] + _amount1 >= dex_balances[_address0][_symbol1], "overflow first balance recipient");
        require(dex_balances[_address1][_symbol0] + _amount0 >= dex_balances[_address1][_symbol0], "overflow second balance recipient");

        dex_balances[_address0][_symbol0] -= _amount0;
        dex_balances[_address0][_symbol1] += _amount1;
       
        dex_balances[_address1][_symbol0] += _amount0;
        order_balances[_address1][_symbol1] -= _amount1;

    }

    function marketExchange(address _address0, bytes32 _symbol0, uint256 _amount0, address _address1, bytes32 _symbol1, uint256 _amount1) public onlyOwner {
        require(dex_balances[_address0][_symbol0] >= _amount0, "underflow first balance recipient");
        require(dex_balances[_address1][_symbol1] >= _amount1, "underflow second balance recipient");

        require(dex_balances[_address0][_symbol1] + _amount1 >= dex_balances[_address0][_symbol1], "overflow first balance recipient");
        require(dex_balances[_address1][_symbol0] + _amount0 >= dex_balances[_address1][_symbol0], "overflow second balance recipient");

        dex_balances[_address0][_symbol0] -= _amount0;
        dex_balances[_address0][_symbol1] += _amount1;

        dex_balances[_address1][_symbol0] += _amount0;
        dex_balances[_address1][_symbol1] -= _amount1;

    }
}