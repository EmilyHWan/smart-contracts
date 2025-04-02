# Aruspex-smart-contracts: Funding and Lottery
- FundMe: a smart contract that converts USD to ETH and sends the funds to the contract owner  
- Raffle: a smart contract that accepts players, picks a winner, and performs a timed upkeep and reset for each lottery 

## Requirements
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [foundry](https://getfoundry.sh/)

## FundMe Usage

#### FundMe Deploy
```
forge script script/DeployFundMe.s.sol
```

#### FundMe Testing
```
forge test
```
or 
```
forge test --match-test testFunctionName
```
or
```
forge test --fork-url $SEPOLIA_RPC_URL
```

#### FundMe Test Coverage
```
forge coverage
```

## Deployment to a Testnet or Mainnet

#### Set Up Environment Variables
- `PRIVATE_KEY`: e.g., [Metamask](https://metamask.io/))
- `SEPOLIA_RPC_URL`: free setup from [Alchemy](https://alchemy.com/?a=673c802981)

#### Get Testnet ETH
- Go to [faucets.chain.link](https://faucets.chain.link/) for some testnet ETH

#### Deploy
```
forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

## FundMe Scripts
```
cast send <FUNDME_CONTRACT_ADDRESS> "fund()" --value 0.1ether --private-key <PRIVATE_KEY>
```

## Raffle Usage

#### Start a Local Node
```
make anvil
```

#### Library
```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

#### Raffle Deploy
```
make deploy
```

#### Raffle Testing
```
forge test
```
or
```
forge test --fork-url $SEPOLIA_RPC_URL
```

#### Raffle Test Coverage
```
forge coverage
```

## Deployment to a Testnet or Mainnet (Same as FundMe)

## Raffle Scripts

```
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```
or, to create a ChainlinkVRF Subscription:
```
make createSubscription ARGS="--network sepolia"
```

## Estimate Gas
```
forge snapshot
```
to return an output file called `.gas-snapshot`


