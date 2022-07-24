// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// import {ERC20} from "solmate/tokens/ERC20.sol"; // TODO figure out way to make vscode happy with this
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import "../lib/forge-std/src/Test.sol";

contract EthPool is ERC20 {
    using SafeTransferLib for address;

    address public immutable team;
    uint256 public ethBalance;

    constructor() ERC20("EthPool", "pETH", 18) {
        team = msg.sender;
    }

    error NotTeam();

    function fund() external payable {
        if (msg.sender != team) revert NotTeam();
        ethBalance += msg.value;
    }

    function deposit() external payable {
        uint256 totalEth = ethBalance;
        uint256 totalShares = totalSupply;

        if (totalEth == 0 || totalShares == 0) {
            _mint(msg.sender, msg.value);
        } else {
            uint256 sharesToMint = (totalShares * msg.value) / totalEth;
            _mint(msg.sender, sharesToMint);
        }

        ethBalance += msg.value;
    }

    function withdraw(uint256 shares) external payable {
        uint256 totalShares = totalSupply;
        uint256 totalEth = ethBalance;
        uint256 ethToSend = (totalEth * shares) / totalShares;

        ethBalance -= (ethBalance * shares) / totalShares;
        _burn(msg.sender, shares);

        msg.sender.safeTransferETH(ethToSend);
    }
}
