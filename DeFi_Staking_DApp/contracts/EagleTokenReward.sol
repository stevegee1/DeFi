// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract EagleTokenReward is
    ERC20,
    ERC20Permit,
    ERC20Burnable,
    Ownable,
    AccessControl
{
    //type declaration
    using SafeERC20 for ERC20;
    using Math for uint256;
    using Math for uint32;

    //error declaration
    error EagleToken__notAllowed();

    //state variables
    mapping(address => uint256) private s_balances;
    uint256 private s_totalSupply;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor()
        ERC20("EagleToken", "EAG")
        ERC20Permit("EagleToken")
        Ownable(msg.sender)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    function mint(address to, uint amount) external {
        if (hasRole(MANAGER_ROLE, _msgSender())) {
            revert EagleToken__notAllowed();
        }
        (, s_totalSupply) = s_totalSupply.tryAdd(amount);
        (, s_balances[to]) = s_balances[to].tryAdd(amount);
        _mint(to, amount);
    }
    function safeEagleTransfer(address to, uint amount) external {
         if (hasRole(MANAGER_ROLE, _msgSender())) {
            revert EagleToken__notAllowed();
        }
        uint balance= balanceOf(address(this));
        if(amount > balance){
           transfer(to, balance);
        }else{
            transfer(to, amount);
        }
    }
}
