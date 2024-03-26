// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenAB.sol";

contract CPAMM {
    error CPAMM__MustBeBalanceInAddLiquidity();
    error CPAMM__NeedMoreThanZero();
    error CPAMM__InvalidToken();
    error CPAMM__InvalidAddress();
    error CPAMM__TransferFailed();

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    TokenAB public tokenAB;

    uint256 public reserveTokenA;
    uint256 public reserveTokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function _mint(address _to, uint256 _amount) internal {
        tokenAB.mint(_to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal {
        bool success = tokenAB.transferFrom(_from, address(this), _amount);
        if (!success) {
            revert CPAMM__TransferFailed();
        }
        tokenAB.burn(_amount);
    }

    function _update(uint256 _reserveTokenA, uint256 _reserveTokenB) private {
        reserveTokenA = _reserveTokenA;
        reserveTokenB = _reserveTokenB;
    }

    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        if (_tokenIn != address(tokenA) && _tokenIn != address(tokenB)) {
            revert CPAMM__InvalidToken();
        }
        if (_amountIn == 0) {
            revert CPAMM__NeedMoreThanZero();
        }

        // Pull in token in
        bool istokenA = _tokenIn == address(tokenA);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) =
            istokenA ? (tokenA, tokenB, reserveTokenA, reserveTokenB) : (tokenB, tokenA, reserveTokenB, reserveTokenA);
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        // Calculate token out (include fees), fee 0.3%
        uint256 amountInWithFee = (_amountIn * 997) / 1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee); //Ydx / (X + dx) = dy

        // Transfer token out to msg.sender
        tokenOut.transfer(msg.sender, amountOut);

        // Update the reserves
        _update(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function addLiquidity(uint256 _amountA, uint256 _amountB) external returns (uint256 shares) {
        // Pull in tokenA and tokenB
        tokenA.transferFrom(msg.sender, address(this), _amountA);
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        if (reserveTokenA > 0 || reserveTokenB > 0) {
            if (reserveTokenA * _amountB != reserveTokenB * _amountA) {
                revert CPAMM__MustBeBalanceInAddLiquidity(); // x * dy = y * dx
            }
        }

        // Mint shares
        if (address(tokenAB) == address(0)) {
            tokenAB = new TokenAB(address(this));
        }
        if (tokenAB.totalSupply() == 0) {
            shares = _sqrt(_amountA * _amountB);
        } else {
            shares = _min(
                (_amountA * tokenAB.totalSupply()) / reserveTokenA, (_amountB * tokenAB.totalSupply()) / reserveTokenB
            ); // (dx / X)T = (dy / Y)T
        }
        if (shares == 0) {
            revert CPAMM__NeedMoreThanZero();
        }
        _mint(msg.sender, shares);
        // Update reserves
        _update(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function removeLiquidity(uint256 _shares) external returns (uint256 amountA, uint256 amountB) {
        if (address(tokenAB) == address(0)) {
            revert CPAMM__InvalidAddress();
        }
        // Calculate amountA and amountB to withdraw
        uint256 balanceOfTokenA = tokenA.balanceOf(address(this));
        uint256 balanceOfTokenB = tokenB.balanceOf(address(this));
        amountA = (_shares * balanceOfTokenA) / tokenAB.totalSupply();
        amountB = (_shares * balanceOfTokenB) / tokenAB.totalSupply();
        if (amountA == 0 || amountB == 0) {
            revert CPAMM__NeedMoreThanZero();
        }
        // Burn shares
        _burn(msg.sender, _shares);
        // Update reserves
        _update(balanceOfTokenA - amountA, balanceOfTokenB - amountB);
        // Transfer tokens to msg.sender
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
