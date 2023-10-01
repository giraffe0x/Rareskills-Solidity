Why does the SafeERC20 program exist and when should it be used?

SafeERC20 is a wrapper library around ERC20 calls that make safe the interaction with a ERC20 token. It was introduced to solve two issues with ERC20:
1) contracts that do not check the return value of the `transfer` or `transferFrom` may not catch a failed transfer.
2) some ERC20 implementations like USDT do not return a value from `transfer` or `transferFrom`. If the return value is
checked, it could lead to unexpected behaviour such as DOS.

SafeERC20 offers `safeTransfer` and `safeTransferFrom` functions which not only handle the standard ERC20 tokens but also accomodate non-standard ERC20 tokens like USDT. These “safe” functions make sure that in case the tokens we’re interacting with returns a boolean value (but only if it returns something), the transaction will be reverted.
