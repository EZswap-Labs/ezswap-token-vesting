# stake interface

## call function
##### 1.stake 
```solidity
function stake(uint256 amount)
```
##### params

| param            | type      | intro            | example                                         | 
| --------------- | --------- | --------------- | ------------------------------------------ | 
| amount            | uint256   | stake token amount   | 10000 * 10 ** 18 |   


##### 2.unstake 
```solidity
function unstake(uint256 amount)
```
##### params

| param            | type      | intro            | example                                         | 
| --------------- | --------- | --------------- | ------------------------------------------ | 
| amount            | uint256   | unstake token amount   | 10000 * 10 ** 18 |   


##### 3.withdraw 
```solidity
function withdraw()
```
##### params

withdraw available unstake token


## view function
##### 4.getTotalUnstakedAmount
```solidity
function getTotalUnstakedAmount(address user) returns (uint256)
```
##### params

| param            | type      | intro            | example                                         | 
| --------------- | --------- | --------------- | ------------------------------------------ | 
| user            | address   | getTotalUnstakedAmount   | 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 |   


##### 5.getAvailableWithdrawAmount
```solidity
function getAvailableWithdrawAmount(address user) returns (uint256)
```
##### params

| param            | type      | intro            | example                                         | 
| --------------- | --------- | --------------- | ------------------------------------------ | 
| user            | address   | getAvailableWithdrawAmount   | 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 |   

