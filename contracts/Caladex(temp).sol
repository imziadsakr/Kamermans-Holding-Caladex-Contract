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
    address caller_address ;
    uint256 caller_value;
    mapping(address => mapping( bytes32 => uint256) ) public dex_balances;
    mapping(address => mapping( bytes32 => uint256) ) public order_balances;
    mapping(uint256 => Stake) public _stakes;
    mapping(uint256 => uint256) public stake_balances;
    uint256 public stakeCount;
    

    constructor() {
        caladex_address = address(0x871d1955BDe8706b0eb034718d94AAE6EdD1bcb5);
    }

    event StakeCount(uint256 count);

    function sendViaTransfer() public payable {
        // This function is no longer recommended for sending Ether.
    }

    function deposit(address _token, bytes32 symbol, uint256 amount) public payable{
        bytes32  eth_data = "ETH";
        caller_address = msg.sender;
        caller_value = msg.value;

        if(symbol == eth_data) {
            dex_balances[caller_address][symbol] += caller_value;
            payable(caladex_address).transfer(amount);
            return;
        }
        require(IERC20(_token).balanceOf(caller_address) >= amount, "underflow balance recipient");
        require(dex_balances[caller_address][symbol] + amount >= dex_balances[caller_address][symbol], "overflow balance recipient");
        require(IERC20(_token).transferFrom(caller_address, caladex_address, amount), "Failed to return tokens to the investor");
        
        dex_balances[caller_address][symbol] +=amount;
    }

    function withdraw(address _address, address token_address, bytes32 symbol, uint256 amount) public payable{
        bytes32  eth_data = "ETH";
        caller_address = msg.sender ;
        caller_value = msg.value ;

        if(symbol == eth_data) {
            require(dex_balances[_address][symbol] - amount <= dex_balances[_address][symbol], "underflow balance recipient");
            payable(_address).transfer(amount);
            dex_balances[caller_address][symbol] = dex_balances[caller_address][symbol] - amount;
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
}