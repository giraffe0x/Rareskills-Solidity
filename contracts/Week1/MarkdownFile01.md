1. What problems ERC777 and ERC1363 solves?

ERC20's `approval` and `transfer` requires two transactions (gas to be paid twice) and is poor UX.
ERC777 solves this through the use of approved 'operators' who can send tokens on user's behalf.
ERC1363 solves this through the use of callback which allows the recipient to `transfer` upon `approval` in one tx.


2. Why was ERC1363 introduced, and what issues are there with ERC777?

There is no way to execute code after a ERC-20 transfer or approval (i.e. making a payment), so to make an action it is required to send another transaction and pay GAS twice.

Issues: ERC777 hooks introduce a reentrancy risk. The tokensToSend hook is called before the actual transfer of tokens, which hands execution over to the sender contract. This sender contract may be malicious and take advantage of state changes that have happened (e.g. ETH already transferred but ERC777 token not yet transferred).
