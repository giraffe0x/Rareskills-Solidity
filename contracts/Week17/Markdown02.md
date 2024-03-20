- [ ]  When a contract calls another call via call, delegatecall, or staticcall, how is information passed between them? Where is this data stored?
Data is stored in the calldata area, and contains info about the function signature and encoded parameters. Same for all 3 calls.

- [ ]  If a proxy calls an implementation, and the implementation self-destructs in the function that gets called, what happens?
Proxy gets destroyed.

- [ ]  If a proxy calls an empty address or an implementation that was previously self-destructed, what happens?
Call and delegate call should succeed. Will fail if you try to decode the result. Will fail if it is a contract deployed by solc with no code (solc will add default code in which builds the revert).

- [ ]  If a user calls a proxy makes a delegatecall to A, and A makes a regular call to B, from A's perspective, who is msg.sender? from B's perspective, who is msg.sender? From the proxy's perspective, who is msg.sender?
EOA -> proxy - delegatecall -> A - call -> B
From A's perspective, msg.sender is EOA
From B's perspective, msg.sender is proxy
From proxy's perspective, msg.sender is EOA

- [ ]  If a proxy makes a delegatecall to A, and A does address(this).balance, whose balance is returned, the proxy's or A?
Proxy's

- [ ]  If a proxy makes a delegatecall to A, and A calls codesize, is codesize the size of the proxy or A?
A (the only exception).. but what does A call? address(this).code.length will return proxy size.

- [ ]  If a delegatecall is made to a function that reverts, what does the delegatecall do?
If call success is not checked, it does not revert. If it is checked then it reverts.

- [ ]  Under what conditions does the Openzeppelin Proxy.sol overwrite the free memory pointer? Why is it safe to do this?
When the fallback function is called and delegatecall is performed. It is safe because solidity code is not used, and memory space is only used for the delegatecall.

- [ ]  If a delegatecall is made to a function that reads from an immutable variable, what will the value be?
The immutable variable (stored in bytecode)

- [ ]  If a delegatecall is made to a contract that makes a delegatecall to another contract, who is msg.sender in the proxy, the first contract, and the second contract?
EOA -> proxy - delegatecall -> A - delegatecall -> B
From A's perspective, msg.sender is EOA
From B's perspective, msg.sender is EOA
From proxy's perspective, msg.sender is EOA
