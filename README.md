# party-droppper

Allows communities to mint "party favors" (ERC 1155 NFTs) for contributors to PartyBids and PartyBuys.

Developed using [foundry](https://github.com/gakonst/foundry)

Building: `forge build`

Testing: `forge test --verbosity 2`

Deploying: `forge create --private-key $RINKEBY_PRIVATE_KEY --rpc-url $RINKEBY_RPC_URI --from $RINKEBY_ADDRESS ./src/PartyDropper.sol:PartyDropper`
