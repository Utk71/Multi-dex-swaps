// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDEXRouter {
    function exactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external payable returns (uint256 amountOut);
}

contract MultiDexSwap {
    address public owner;
    uint256 public slippageTolerance; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(uint256 _slippageTolerance) {
        owner = msg.sender;
        slippageTolerance = _slippageTolerance;
    }

    struct SwapOrder {
        string side; 
        address[] path; 
        uint256[] amounts; 
        address[] dexes; 
        uint24[] fees; 
    }

    function executeSwap(SwapOrder memory order) external payable onlyOwner {
        require(order.path.length == order.amounts.length + 1, "Invalid path length");
        for (uint256 i = 0; i < order.dexes.length; i++) {
            uint256 amountOutMinimum = calculateSlippage(order.amounts[i + 1], slippageTolerance);
            bool swapSuccess = swapOnDex(
                order.dexes[i],
                order.path[i],
                order.path[i + 1],
                order.fees[i],
                order.amounts[i],
                amountOutMinimum
            );
            require(swapSuccess, "Swap failed");
        }
    }
    function swapOnDex(
        address dexRouter,
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public returns (bool) {
        (bool success, bytes memory data) = dexRouter.call(
            abi.encodeWithSignature(
                "exactInputSingle(address,address,uint24,uint256,uint256,uint160)",
                tokenIn, tokenOut, fee, amountIn, amountOutMinimum, 0
            )
        );

        return success && (data.length == 0); 
    }
    function calculateSlippage(uint256 amount, uint256 _slippageTolerance) public pure returns (uint256) {
        return amount - (amount * _slippageTolerance / 10000); 
    }
    function getAmountOutWithSlippage(uint256 amount, uint256 _slippageTolerance) external pure returns (uint256) {
        return calculateSlippage(amount, _slippageTolerance);
    }
}
