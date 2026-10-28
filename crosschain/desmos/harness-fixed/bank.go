package main

import (
	"fmt"
	"os"
	"unsafe"

	"cosmossdk.io/log"
	"cosmossdk.io/math"
	"cosmossdk.io/store"
	"cosmossdk.io/store/metrics"
	storetypes "cosmossdk.io/store/types"
	cmtproto "github.com/cometbft/cometbft/proto/tendermint/types"
	dbm "github.com/cosmos/cosmos-db"
	"github.com/cosmos/cosmos-sdk/codec"
	addresscodec "github.com/cosmos/cosmos-sdk/codec/address"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/runtime"
	sdk "github.com/cosmos/cosmos-sdk/types"
	authkeeper "github.com/cosmos/cosmos-sdk/x/auth/keeper"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"
	bankkeeper "github.com/cosmos/cosmos-sdk/x/bank/keeper"
)

type bankTarget struct {
	ctx           sdk.Context
	keeper        bankkeeper.BaseKeeper
	moduleAddress sdk.AccAddress
	amount        sdk.Coins
	calls         int
	err           error
}

var demoBank *bankTarget

func newBankTarget() *bankTarget {
	registry := codectypes.NewInterfaceRegistry()
	authtypes.RegisterInterfaces(registry)
	cdc := codec.NewProtoCodec(registry)
	address := addresscodec.NewBech32Codec("archway")
	db := dbm.NewMemDB()
	multiStore := store.NewCommitMultiStore(db, log.NewNopLogger(), metrics.NewNoOpMetrics())
	storeKey := storetypes.NewKVStoreKey("bank")
	multiStore.MountStoreWithDB(storeKey, storetypes.StoreTypeIAVL, db)
	if err := multiStore.LoadLatestVersion(); err != nil {
		panic(err)
	}
	ctx := sdk.NewContext(multiStore, cmtproto.Header{}, false, log.NewNopLogger())
	storeService := runtime.NewKVStoreService(storeKey)
	permissions := map[string][]string{"mint": {authtypes.Minter}}
	accountKeeper := authkeeper.NewAccountKeeper(cdc, storeService, authtypes.ProtoBaseAccount, permissions, address, "archway", "")
	authorityBytes := authtypes.NewModuleAddress("gov")
	authority, err := address.BytesToString(authorityBytes)
	if err != nil {
		panic(err)
	}
	keeper := bankkeeper.NewBaseKeeper(cdc, storeService, accountKeeper, map[string]bool{}, authority, log.NewNopLogger())
	return &bankTarget{
		ctx:           ctx,
		keeper:        keeper,
		moduleAddress: authtypes.NewModuleAddress("mint"),
		amount:        sdk.NewCoins(sdk.NewCoin("aarch", math.NewInt(1_000_000))),
	}
}

func mintBridge(_ unsafe.Pointer) {
	if demoBank == nil {
		demoBank = newBankTarget()
	}
	bank := demoBank
	bank.calls++
	supplyBefore := bank.keeper.GetSupply(bank.ctx, "aarch")
	bank.err = bank.keeper.MintCoins(bank.ctx, "mint", bank.amount)
	supplyAfter := bank.keeper.GetSupply(bank.ctx, "aarch")
	balance := bank.keeper.GetBalance(bank.ctx, bank.moduleAddress, "aarch")
	fmt.Fprintf(os.Stderr, "M4BANK call=%d err=%v supply_before=%s supply_after=%s module_balance=%s\n",
		bank.calls, bank.err, supplyBefore.String(), supplyAfter.String(), balance.String())
}

func runBankCheck() error {
	mintBridge(nil)
	return demoBank.err
}
