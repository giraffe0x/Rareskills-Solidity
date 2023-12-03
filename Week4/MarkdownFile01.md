
Document true and false positives that you discovered with the tools

## False positives
1. UntrustedEscrow.deposit(uint256) (contracts/Week1/UntrustedEscrow.sol#29-36) uses arbitrary from in transferFrom: IERC20(token).safeTransferFrom(buyer,address(this),amount) (contracts/Week1/UntrustedEscrow.sol#33)

Issue: Detect when msg.sender is not used as from in transferFrom.

2. UniswapV2Pair.flashLoan(IERC3156FlashBorrower,address,uint256,bytes) (contracts/Week3/UniswapV2Pair.sol#292-319) uses arbitrary from in transferFrom: SafeTransferLib.safeTransferFrom(token,address(receiver),address(this),amount + fee) (contracts/Week3/UniswapV2Pair.sol#314)

Issue: Detect when msg.sender is not used as from in transferFrom.

## True positives
Nil
