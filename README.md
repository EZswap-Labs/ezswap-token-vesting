# <h1 align="center"> ezswap-token-vesting </h1>

## Intro

This is vesting comtract for ezswap token, targeted for linear unlocking, once `createLock`, owner can only `claim` certain number of tokens according to the time specified in the contract. Before ending, owner can't remove any token of contract. Once After claiming, owner can control the contract with `ownerCall` to do some unexpected recovery of token.

```sh
forge build
forge test
```

```
forge script script/Vesting.s.sol:MyScript --rpc-url https://pacific-rpc.testnet.manta.network/http --broadcast --verify -vvvv 

forge script script/Vesting.s.sol:MyScript --rpc-url https://pacific-rpc.testnet.manta.network/http --verify --resume

forge script script/Stake.s.sol:MyScript --rpc-url https://pacific-rpc.sepolia-testnet.manta.network/http --broadcast --verify -vvvv 

forge script script/Stake.s.sol:MyScript --rpc-url https://pacific-rpc.sepolia-testnet.manta.network/http --verify --resume
```