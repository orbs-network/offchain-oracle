// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IOracle.sol";

interface IFluidDexReservesResolver {
    struct CollateralReserves {
        uint256 token0RealReserves;
        uint256 token1RealReserves;
        uint256 token0ImaginaryReserves;
        uint256 token1ImaginaryReserves;
    }

    struct DebtReserves {
        uint256 token0Debt;
        uint256 token1Debt;
        uint256 token0RealReserves;
        uint256 token1RealReserves;
        uint256 token0ImaginaryReserves;
        uint256 token1ImaginaryReserves;
    }

    function getTotalPools() external view returns (uint256);
    function getPoolAddress(uint256 poolId) external view returns (address);
    function getPoolTokens(address pool) external view returns (address token0, address token1);
    function getDexCollateralReserves(address dex) external view returns (CollateralReserves memory);
    function getDexDebtReserves(address dex) external view returns (DebtReserves memory);
}

interface IFluidDexT1 {
    function readFromStorage(bytes32 slot) external view returns (uint256);
}

contract FluidDexOracle is IOracle {
    using Math for uint256;

    IERC20 private constant _NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    uint256 private constant _PRICE_PRECISION = 1e27;
    uint256 private constant _PRICE_PRECISION_SQUARED = 1e54;
    uint256 private constant _RATE_PRECISION = 1e18;
    bytes32 private constant _DEX_VARIABLES_SLOT = bytes32(uint256(0));
    uint256 private constant _X40 = 0xffffffffff;
    uint256 private constant _DEFAULT_EXPONENT_SIZE = 8;
    uint256 private constant _DEFAULT_EXPONENT_MASK = 0xFF;

    IFluidDexReservesResolver public immutable RESOLVER;

    constructor(IFluidDexReservesResolver resolver) {
        require(address(resolver) != address(0), "resolver is zero");
        RESOLVER = resolver;
    }

    function getRate(
        IERC20 srcToken,
        IERC20 dstToken,
        IERC20 connector,
        uint256 /*thresholdFilter*/
    )
        external
        view
        override
        returns (uint256 rate, uint256 weight)
    {
        if (connector == _NONE) {
            (uint256 price1e27, uint256 w) = _getBestPrice(address(srcToken), address(dstToken));
            if (price1e27 == 0) revert PoolNotFound();
            rate = Math.mulDiv(price1e27, _RATE_PRECISION, _PRICE_PRECISION);
            weight = w;
            return (rate, weight);
        }

        (uint256 priceSrcConnector, uint256 weight0) = _getBestPrice(address(srcToken), address(connector));
        if (priceSrcConnector == 0) revert PoolWithConnectorNotFound();
        (uint256 priceConnectorDst, uint256 weight1) = _getBestPrice(address(connector), address(dstToken));
        if (priceConnectorDst == 0) revert PoolWithConnectorNotFound();

        rate = Math.mulDiv(priceSrcConnector, priceConnectorDst, 1e36);
        weight = Math.min(weight0, weight1);
    }

    function _getBestPrice(address tokenA, address tokenB) internal view returns (uint256 price1e27, uint256 weight) {
        uint256 totalPools = RESOLVER.getTotalPools();
        for (uint256 i = 1; i <= totalPools; i++) {
            address pool = RESOLVER.getPoolAddress(i);
            (address token0, address token1) = RESOLVER.getPoolTokens(pool);
            bool direct = token0 == tokenA && token1 == tokenB;
            bool inverse = token0 == tokenB && token1 == tokenA;
            if (!direct && !inverse) continue;

            uint256 poolPrice = _getPoolPrice(pool);
            if (poolPrice == 0) continue;

            price1e27 = direct ? poolPrice : _PRICE_PRECISION_SQUARED / poolPrice;
            weight = 1;
            return (price1e27, weight);
        }
    }

    function _getPoolPrice(address pool) internal view returns (uint256 price1by0) {
        uint256 dexVariables = IFluidDexT1(pool).readFromStorage(_DEX_VARIABLES_SLOT);
        uint256 packed = (dexVariables >> 41) & _X40;
        price1by0 = (packed >> _DEFAULT_EXPONENT_SIZE) << (packed & _DEFAULT_EXPONENT_MASK);
    }
}
