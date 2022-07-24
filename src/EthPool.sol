// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// import {ERC20} from "solmate/tokens/ERC20.sol"; // TODO figure out way to make vscode happy with this
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import "../lib/forge-std/src/Test.sol";

contract EthPool is ERC20 {
    using SafeTransferLib for address;

    address public immutable team;
    uint256 internal _ethBalance;

    constructor() ERC20("EthPool", "pETH", 18) {
        team = msg.sender;
    }

    error NotTeam();

    function fund() external payable {
        if (msg.sender != team) revert NotTeam();
        _ethBalance += msg.value;
    }

    function deposit() external payable {
        uint256 ethBalance = _ethBalance;
        uint256 totalShares = totalSupply;

        if (ethBalance == 0 || totalShares == 0) {
            _mint(msg.sender, msg.value);
        } else {
            uint256 sharesToMint = (totalShares * msg.value) / ethBalance;
            _mint(msg.sender, sharesToMint);
        }

        _ethBalance += msg.value;
    }

    function withdraw(uint256 shares) external payable {
        uint256 ethBalance = _ethBalance;
        uint256 totalShares = totalSupply;
        uint256 ethToSend = (ethBalance * shares) / totalShares;

        _ethBalance -= ethToSend;
        _burn(msg.sender, shares);

        msg.sender.safeTransferETH(ethToSend);
    }

    function getEthBalance() public view returns (uint256) {
        return _ethBalance;
    }
}
