-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network bnb\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network bnb\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

coverage :; forge coverage --report lcov

report_coverage :; lcov --remove lcov.info -o lcov_filter.info 'script/*' && genhtml lcov_filter.info -o report/

clean_report :; rm -rf lcov.info lcov_filter.info report/

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network bnb,$(ARGS)),--network bnb)
	NETWORK_ARGS := --rpc-url $(BNB_TEST_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(BSC_API_KEY) -vvvv
endif

deployCPAMM:
	@forge script script/DeployCPAMM.s.sol:DeployCPAMM $(NETWORK_ARGS)
deploySimpleCPAMM:
	@forge script script/DeploySimpleCPAMM.s.sol:DeploySimpleCPAMM $(NETWORK_ARGS)

