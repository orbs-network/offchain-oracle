// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./OracleBase.sol";
import "../interfaces/IUniswapV2Pair.sol";

interface IV2FactoryLookup {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract V2FactoryLookupOracle is OracleBase {
    address public immutable FACTORY;

    constructor(address _factory) {
        FACTORY = _factory;
    }

    function _getBalances(IERC20 srcToken, IERC20 dstToken)
        internal
        view
        override
        returns (uint256 srcBalance, uint256 dstBalance)
    {
        (IERC20 token0, IERC20 token1) = srcToken < dstToken ? (srcToken, dstToken) : (dstToken, srcToken);
        address pair = IV2FactoryLookup(FACTORY).getPair(address(token0), address(token1));
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (srcBalance, dstBalance) = srcToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
