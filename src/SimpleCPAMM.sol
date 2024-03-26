// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Reference: Smart Contract Programmer
// https://www.youtube.com/watch?v=QNPyFs8Wybk - CPAMM math
// https://solidity-by-example.org/defi/constant-product-amm/ - Source code
contract SimpleCPAMM {
    error SimpleCPAMM__MustBeBalanceInAddLiquidity();
    error SimpleCPAMM__NeedMoreThanZero();
    error SimpleCPAMM__InvalidToken();

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveTokenA;
    uint256 public reserveTokenB;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function _mint(address _to, uint256 _amount) internal {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) internal {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint256 _reserveTokenA, uint256 _reserveTokenB) private {
        reserveTokenA = _reserveTokenA;
        reserveTokenB = _reserveTokenB;
    }

    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        if (_tokenIn != address(tokenA) && _tokenIn != address(tokenB)) {
            revert SimpleCPAMM__InvalidToken();
        }
        if (_amountIn == 0) {
            revert SimpleCPAMM__NeedMoreThanZero();
        }

        // Pull in token in
        bool istokenA = _tokenIn == address(tokenA);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) =
            istokenA ? (tokenA, tokenB, reserveTokenA, reserveTokenB) : (tokenB, tokenA, reserveTokenB, reserveTokenA);
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        /* Swap from token A to token B
        dx: Amount of token A in
        dy: Amount of token B out

        XY = K (1) // Before swap
        (X + dx)(Y - dy) = K // After swap
        <=> Y - dy = K / (X + dx)
        <=> Y - K / (X + dx) = dy
        <=> Y - XY / (X + dx) = dy // replace K = XY in (1)
        <=> (YX + Ydx - XY) / (X + dx) = dy
        <=> Ydx / (X + dx) = dy
        */
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

        /*
        How much dx, dy to add?

        XY = K
        (X + dx)(Y + dy) = K'
        with K <= K'

        No price change, before and after adding liquidity
        X / Y = (X + dx) / (Y + dy)

        X(Y + dy) = Y(X + dx)
        X * dy = Y * dx
        dy = (Y * dx) / X (1)
        dx = (X * dy) / Y (2)

        (1) (2) => X / Y = dx / dy (3)
        */

        if (reserveTokenA > 0 || reserveTokenB > 0) {
            if (reserveTokenA * _amountB != reserveTokenB * _amountA) {
                revert SimpleCPAMM__MustBeBalanceInAddLiquidity(); // x * dy = y * dx
            }
        }

        /*
        How much shares to mint?
        Increase in liquidity is proportional to increase in shares
        F(X, Y) = value of liquidity
        We will define F(X,Y) = sqrt(XY)

        L0 = Total liquidity before = F(X,Y) = sqrt(XY)
        L1 = Total liquidity after = F(X + dx, Y + dy) = sqrt((X + dx)(Y + dy))
        T = Total shares before
        s = shares to mint
        
        L1 / L0 = (T + s) / T
        --> Find s
        (L1 / L0)T = T + s
        (L1 / L0)T - T = s
        ( (L1 - L0)T ) / L0 = s (I)

        Claim
        (L1 - L0) / L0 = dx / X = dy / Y (II)

        Proof
        (L1 - L0) / L0 
        = ( sqrt((X + dx)(Y + dy)) - sqrt(XY) ) / sqrt(XY)
        = ( sqrt(XY + Xdy + dxY + dxdy) - sqrt(XY) ) / sqrt(XY)
        In (3) dx / dy = X / Y so replace dy = Ydx / X
        = ( sqrt(XY + X(Ydx / X) + dxY + dx(Ydx / X)) - sqrt(XY) ) / sqrt(XY)
        = ( sqrt(XY + Ydx + dxY + (dx^2)Y/X) - sqrt(XY) ) / sqrt(XY)
        = ( sqrt( (X + 2dx + (dx^2)/X)Y ) - sqrt(XY) ) / sqrt(XY)
        Multiply by sqrt(x) / sqrt(x)
        = ( sqrt( (X^2 + 2Xdx + (dx^2))Y ) - sqrt(X^2)sqrt(Y)) ) / sqrt(X^2)sqrt(Y)
        = ( (X + dx)sqrt(Y) - sqrt(Y)X ) / sqrt(Y)X
        = (sqrt(Y)X + sqrt(Y)dx - sqrt(Y)X) / sqrt(Y)X
        = dx / X

        Finally
        (L1 - L0) / L0 = dx / x = dy / y

        (I) + (II) => s = (dx / X)T = (dy / Y)T
        */
        // Mint shares
        if (totalSupply == 0) {
            shares = _sqrt(_amountA * _amountB);
        } else {
            shares = _min((_amountA * totalSupply) / reserveTokenA, (_amountB * totalSupply) / reserveTokenB); // (dx / X)T = (dy / Y)T
        }
        if (shares == 0) {
            revert SimpleCPAMM__NeedMoreThanZero();
        }
        _mint(msg.sender, shares);
        // Update reserves
        _update(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function removeLiquidity(uint256 _shares) external returns (uint256 amountA, uint256 amountB) {
        /*
        Withdraw tokens proportional to shares
        a = Amount out = F(dx, dy) = sqrt(dxdy)
        L = Total liquidity = F(X,Y) = sqrt(XY)
        s = Amount of shares to burn
        T = Total shares

        a/L = s/T -> Find a = L*(s/T)

        Claim 
        dx, dy = amount of liquidity to remove
        dx = X * (s / T)
        dy = Y * (s / T)

        Proof
        Let's find dx, dy such that
        a/L = s/T -> Find a = L*(s/T)

        sqrt(dxdy) = sqrt(XY)(s/T)
        Replace dy = Ydx/X
        sqrt(dxYdx/X) = sqrt(XY)(s/T)
        dx*sqrt(Y/X) = sqrt(XY)(s/T) (Pull out dx)
        dx = ( sqrt(XY)(s/T) ) / sqrt(Y/X)
           = ( sqrt(XY)(s/T) * sqrt(X) ) / sqrt(Y) (Divide both with sqrt(Y))
           = X(s/T)

        Likewise
        dy = Y(s / T)
        */
        // Calculate amountA and amountB to withdraw
        uint256 balanceOfTokenA = tokenA.balanceOf(address(this));
        uint256 balanceOfTokenB = tokenB.balanceOf(address(this));
        amountA = (_shares * balanceOfTokenA) / totalSupply;
        amountB = (_shares * balanceOfTokenB) / totalSupply;
        if (amountA == 0 || amountB == 0) {
            revert SimpleCPAMM__NeedMoreThanZero();
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
