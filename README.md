# Simple CPAMM

This is repository about for practice Defi EVM.

[SimpleCPAMM Example](https://testnet.bscscan.com/address/0xb268939a901e5e93156017e7b112d7c77b22d0bf#code)

[CPAMM Example](https://testnet.bscscan.com/address/0x7faa9fc3b075506a45e2eab13aaebb6635af0d42#code)

# About

This project is meant to be simple swap token A and token B.

- [Simple AMM](#simple-amm)
- [About](#about)
- [Getting started](#getting-started)
    - [Requirements](#requirements)
    - [Quickstart](#quickstart)
- [Usage](#usage)
    - [Start a local node](#start-a-local-node)
    - [Deploy](#deploy)
    - [Deploy on testnet](#deploy-on-testnet)
    - [Testing](#testing)
        - [Test Coverage](#test-coverage)
- [Deployment to a testnet](#deployment-to-a-testnet)
- [References](#references)

# Getting started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/chibihate/simple-cpamm
cd simple-cpamm
forge build
```
# Usage

## Start a local node

```
make anvil
```
## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.
```
make deployCPAMM
or
make deploySimpleCPAMM
```

## Deploy on testnet

[See below](#deployment-to-a-testnet)

## Testing

In this repo, we cover unittest
```
forge test
```
### Test Coverage

```
forge coverage
```

and for generate html report by lcov
```
make coverage
make report_coverage
```

# Deployment to a testnet

1. Setup environment variables

You'll want to set your BNB_TEST_RPC_URL and PRIVATE_KEY as environment variables. You can add them to a .env file, similar to what you see in .env.example.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `BNB_TEST_RPC_URL`: This is url of the bnb testnet node you're working with. You can get setup with one for free from [Chainlist](https://chainlist.org/?search=bnb&testnets=true)

Optionally, add your `BSC_API_KEY` if you want to verify your contract on [BscScan](https://bscscan.com/).

2. Get testnet BSC

Head over to [faucet BNB testnet](https://www.bnbchain.org/en/testnet-faucet) and get some testnet BNB. You should see the BNB show up in your metamask.

3. Deploy

```
make make deployCPAMM ARGS="--network bnb"
```
# References
- Smart Contract Programmer
    - [Video: Constant Product AMM Math | DeFi](https://www.youtube.com/watch?v=QNPyFs8Wybk)
    - [Video: Constant Product Automated Market Maker | Solidity 0.8](https://www.youtube.com/watch?v=JSZbvmyi_LE)
    - [Constant Product AMM](https://solidity-by-example.org/defi/constant-product-amm/)
- Cyfrin
    - [Foundry full course f23](https://github.com/Cyfrin/foundry-full-course-f23)