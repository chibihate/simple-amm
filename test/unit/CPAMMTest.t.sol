// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CPAMM} from "../../src/CPAMM.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployCPAMM} from "../../script/DeployCPAMM.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract CPAMMTest is Test {
    CPAMM amm;
    HelperConfig config;
    DeployCPAMM deployer;

    address tokenA;
    address tokenB;

    address public USER = makeAddr("user");
    uint256 public constant STARTING_ERC20_BALANCE = 100 ether;
    uint256 public constant AMOUNT_ADD_LIQUIDITY = 10 ether;

    function setUp() public {
        deployer = new DeployCPAMM();
        (amm, config) = deployer.run();
        (tokenA, tokenB,) = config.activeNetworkConfig();
        ERC20Mock(tokenA).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(tokenB).mint(USER, STARTING_ERC20_BALANCE);
    }

    function testAddLiquidityWithInitial2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        uint256 actualShares = amm.addLiquidity(1, 1);
        vm.stopPrank();

        uint256 expectedShares = 1;
        uint256 expectedReserveTokenA = 1;
        uint256 expectedReverveTokenB = 1;
        uint256 expectedBalanceOfUser = 1;
        uint256 expectedTotalSupply = 1;
        assertEq(expectedShares, actualShares);
        assertEq(expectedReserveTokenA, amm.reserveTokenA());
        assertEq(expectedReverveTokenB, amm.reserveTokenB());
        assertEq(expectedBalanceOfUser, amm.tokenAB().balanceOf(USER));
        assertEq(expectedTotalSupply, amm.tokenAB().totalSupply());
    }

    function testAddLiquidityWithTotalSupplyIsNotZero2() public {
        vm.startPrank(USER);
        // Add liquidity first time
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        uint256 amountTokenA = 2 ether;
        uint256 amountTokenB = 8 ether;
        amm.addLiquidity(amountTokenA, amountTokenB);
        uint256 initTotalShares = amm.tokenAB().totalSupply();

        // Add liquidity second time
        uint256 amountOfTokenA = 0.25 ether;
        uint256 amountOfTokenB = 1 ether;
        uint256 actualSharesAfterAddLiquidity = amm.addLiquidity(amountOfTokenA, amountOfTokenB);
        vm.stopPrank();
        // (dx / X)T = (dy / Y)T
        uint256 sharesTokenA = amountOfTokenA * initTotalShares / amountTokenA;
        uint256 sharesTokenB = amountOfTokenB * initTotalShares / amountTokenB;
        uint256 expectedSharesAfterAddLiquidity = sharesTokenA > sharesTokenB ? sharesTokenB : sharesTokenA;
        assertEq(expectedSharesAfterAddLiquidity, actualSharesAfterAddLiquidity);
        assertEq(initTotalShares + actualSharesAfterAddLiquidity, amm.tokenAB().totalSupply());
        assertEq(amountTokenA + amountOfTokenA, amm.reserveTokenA());
        assertEq(amountTokenB + amountOfTokenB, amm.reserveTokenB());
    }

    function testAddNotBalanceInAddLiquidity2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        amm.addLiquidity(1 ether, 1 ether);
        vm.expectRevert(CPAMM.CPAMM__MustBeBalanceInAddLiquidity.selector);
        amm.addLiquidity(1 ether, 2 ether);
        vm.stopPrank();
    }

    function testAddLiquidityWithZero2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        vm.expectRevert(CPAMM.CPAMM__NeedMoreThanZero.selector);
        amm.addLiquidity(0, 0);
        vm.stopPrank();
    }

    function testRemoveLiquidityWithWithdrawAllShares2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        uint256 shares = amm.addLiquidity(1 ether, 1 ether);

        amm.tokenAB().approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        (uint256 amountTokenA, uint256 amountTokenB) = amm.removeLiquidity(shares / 2);
        assertEq(0.5 ether, amountTokenA);
        assertEq(0.5 ether, amountTokenB);
        assertEq(amm.tokenAB().totalSupply(), shares / 2);
        vm.stopPrank();
    }

    function testRemoveLiquidityWithWithdrawZeroShare2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        amm.addLiquidity(1 ether, 1 ether);
        vm.expectRevert(CPAMM.CPAMM__NeedMoreThanZero.selector);
        amm.removeLiquidity(0);
        vm.stopPrank();
    }

    function testSwapWithInvalidToken2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        amm.addLiquidity(1 ether, 1 ether);

        ERC20Mock tokenC = new ERC20Mock();
        ERC20Mock(tokenC).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(tokenC).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        vm.expectRevert(CPAMM.CPAMM__InvalidToken.selector);
        amm.swap(address(tokenC), AMOUNT_ADD_LIQUIDITY);
        vm.stopPrank();
    }

    function testSwapWithZeroAmount2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        amm.addLiquidity(0.5 ether, 0.5 ether);

        vm.expectRevert(CPAMM.CPAMM__NeedMoreThanZero.selector);
        amm.swap(tokenA, 0);
        vm.stopPrank();
    }

    function testSwap2() public {
        vm.startPrank(USER);
        ERC20Mock(tokenA).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        ERC20Mock(tokenB).approve(address(amm), AMOUNT_ADD_LIQUIDITY);
        amm.addLiquidity(5 ether, 5 ether);
        uint256 reserveTokenA = amm.reserveTokenA();
        uint256 reserveTokenB = amm.reserveTokenB();
        uint256 amountIn = 1 ether;
        // fee 0.3%
        uint256 amountInIncludeFee = amountIn * 997 / 1000;

        uint256 actualAmountOut = amm.swap(tokenA, amountIn);
        // Ydx / (X + dx) = dy
        uint256 expectedAmountOut = (reserveTokenB * amountInIncludeFee) / (reserveTokenA + amountInIncludeFee);
        vm.stopPrank();
        assertEq(expectedAmountOut, actualAmountOut);
    }
}
