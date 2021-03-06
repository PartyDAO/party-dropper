# party-droppper

Allows communities to mint "party favors" (ERC 1155 NFTs) for contributors to PartyBids and PartyBuys.

## Foundry development

Developed using [foundry](https://github.com/gakonst/foundry)

Building: `forge build`

Testing: `forge test --verbosity 2`

## Dapp tools deployment

Dapp tools is used for deploying given that foundry contract verification for forge is currently broken.

### Set up

`ethsign import`

`export ETHERSCAN_API_KEY=$YOUR_ETHERSCAN_API_KEY`

### Deploy!

`dapp build`

`ETH_GAS=5000000 ETH_FROM=$RINKEBY_DEPLOYER_ADDRESS ETH_RPC_URL=$RINKEBY_RPC_URI dapp create PartyDropper`

`ETH_RPC_URL=$RINKEBY_RPC_URI dapp verify-contract src/PartyDropper.sol:PartyDropper <address>`
