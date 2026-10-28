package main

// bank.go — Desmos-matched in-memory bank target for the CWA-2026-006 harness.
//
// This mirrors source/harness/bank.go from the verified PoC (archway-harness),
// but is pinned to the Cosmos SDK line Desmos mainnet actually runs:
//
//	cosmos-sdk  v0.47.10   (Desmos replaces it with desmos-labs/cosmos-sdk v0.47.10-desmos;
//	                        the x/bank keeper signatures are identical)
//	cometbft    v0.37.4    (so sdk.Context logger = github.com/cometbft/cometbft/libs/log)
//	cometbft-db v0.11.0
//
// The load-bearing difference vs the SDK 0.50 PoC harness:
//
//	0.50 : func (k BaseKeeper) MintCoins(ctx context.Context, ...)   -> context.Context itab
//	0.47 : func (k BaseKeeper) MintCoins(ctx sdk.Context, ...)       -> sdk.Context BY VALUE
//
// i.e. on the Desmos shape there is NO runtime-created `go:itab.Context,context.Context`;
// the callee reads the ~0.5 KB sdk.Context from the caller's argument frame. This is the
// ①-reduction the CROSS-CHAIN-FEASIBILITY study identifies.

import (
	"fmt"
	"os"
	"unsafe"

	"cosmossdk.io/math"
	dbm "github.com/cometbft/cometbft-db"
	"github.com/cometbft/cometbft/libs/log"
	tmproto "github.com/cometbft/cometbft/proto/tendermint/types"
	"github.com/cosmos/cosmos-sdk/codec"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/store"
	storetypes "github.com/cosmos/cosmos-sdk/store/types"
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
	// Desmos bech32 (udsm denom). Set before any address String()/BytesToString.
	cfg := sdk.GetConfig()
	cfg.SetBech32PrefixForAccount("desmos", "desmospub")
	cfg.SetBech32PrefixForValidator("desmosvaloper", "desmosvaloperpub")
	cfg.SetBech32PrefixForConsensusNode("desmosvalcons", "desmosvalconspub")

	registry := codectypes.NewInterfaceRegistry()
	authtypes.RegisterInterfaces(registry)
	cdc := codec.NewProtoCodec(registry)

	db := dbm.NewMemDB()
	multiStore := store.NewCommitMultiStore(db)
	storeKey := storetypes.NewKVStoreKey("bank")
	multiStore.MountStoreWithDB(storeKey, storetypes.StoreTypeIAVL, db)
	if err := multiStore.LoadLatestVersion(); err != nil {
		panic(err)
	}
	ctx := sdk.NewContext(multiStore, tmproto.Header{}, false, log.NewNopLogger())

	permissions := map[string][]string{"mint": {authtypes.Minter}}
	authority := authtypes.NewModuleAddress("gov").String()
	accountKeeper := authkeeper.NewAccountKeeper(
		cdc, storeKey, authtypes.ProtoBaseAccount, permissions, "desmos", authority,
	)
	keeper := bankkeeper.NewBaseKeeper(cdc, storeKey, accountKeeper, map[string]bool{}, authority)

	return &bankTarget{
		ctx:           ctx,
		keeper:        keeper,
		moduleAddress: authtypes.NewModuleAddress("mint"),
		amount:        sdk.NewCoins(sdk.NewCoin("udsm", math.NewInt(1_000_000))),
	}
}

//go:noinline
func mintBridge(_ unsafe.Pointer) {
	if demoBank == nil {
		demoBank = newBankTarget()
	}
	bank := demoBank
	bank.calls++
	supplyBefore := bank.keeper.GetSupply(bank.ctx, "udsm")
	// NOTE: 0.47 signature — ctx passed BY VALUE (no context.Context itab).
	bank.err = bank.keeper.MintCoins(bank.ctx, "mint", bank.amount)
	supplyAfter := bank.keeper.GetSupply(bank.ctx, "udsm")
	balance := bank.keeper.GetBalance(bank.ctx, bank.moduleAddress, "udsm")
	fmt.Fprintf(os.Stderr, "M4BANK call=%d err=%v supply_before=%s supply_after=%s module_balance=%s\n",
		bank.calls, bank.err, supplyBefore.String(), supplyAfter.String(), balance.String())
}

func runBankCheck() error {
	mintBridge(nil)
	return demoBank.err
}
