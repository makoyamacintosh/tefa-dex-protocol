// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Pool {
    address public token0;
    address public token1;

    uint256 public reserve0;
    uint256 public reserve1;

    constructor(address _token0, address _token1) {
        require(_token0 != _token1, "Same token");
        token0 = _token0;
        token1 = _token1;
    }

    // ----------------------------
    // ADD LIQUIDITY
    // ----------------------------
    function addLiquidity(uint256 amount0, uint256 amount1) external {
        require(amount0 > 0 && amount1 > 0, "Invalid amounts");

        // Transfer tokens from user → pool
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        reserve0 += amount0;
        reserve1 += amount1;
    }

    // ----------------------------
    // PRICE FUNCTION (AMM)
    // ----------------------------
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountIn > 0, "Invalid input");
        require(reserveIn > 0 && reserveOut > 0, "No liquidity");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }

    // ----------------------------
    // SWAP
    // ----------------------------
    function swap(address tokenIn, uint256 amountIn)
        external
        returns (uint256 amountOut)
    {
        require(tokenIn == token0 || tokenIn == token1, "Invalid token");

        if (tokenIn == token0) {
            // user sends token0
            IERC20(token0).transferFrom(msg.sender, address(this), amountIn);

            amountOut = getAmountOut(amountIn, reserve0, reserve1);

            require(reserve1 >= amountOut, "Insufficient liquidity");

            reserve0 += amountIn;
            reserve1 -= amountOut;

            // send token1 to user
            IERC20(token1).transfer(msg.sender, amountOut);
        } else {
            // user sends token1
            IERC20(token1).transferFrom(msg.sender, address(this), amountIn);

            amountOut = getAmountOut(amountIn, reserve1, reserve0);

            require(reserve0 >= amountOut, "Insufficient liquidity");

            reserve1 += amountIn;
            reserve0 -= amountOut;

            // send token0 to user
            IERC20(token0).transfer(msg.sender, amountOut);
        }
    }
}
