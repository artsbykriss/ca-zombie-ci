#!/usr/bin/env python3
"""Embed structured evidence (factory settings, reflists, simulations, gate reverts,
owner attributions) into state.json. All values read live in this session."""
import json

state = json.load(open("state.json"))

OWNER = "0x2c9bC901f39F847C2fe5D2D7AC9c5888A2Ab8Fcf"

common = {
    "owner_eoa": OWNER,
    "owner_futureOwner": "0x0000000000000000000000000000000000000000",
    "gate_reverts_unprivileged": [
        {"target": "vault", "fn": "borrowValue(1,attacker)", "revert": "Caller is not allowed to operate", "gate": "onlyMarket"},
        {"target": "vault", "fn": "withdrawValue(1,attacker)", "revert": "WITHDRAW-VALUE_BADCONDITIONS", "gate": "caller attribution"},
        {"target": "vault", "fn": "offsetDebt(1,attacker)", "revert": "ERROR_REPAY_DEBT_BADCONDITIONS", "gate": "caller attribution"},
        {"target": "vault", "fn": "utilize / setController / withdrawRedundant", "revert": "Caller is not allowed to operate", "gate": "onlyController/onlyOwner"},
        {"target": "registry", "fn": "addPool(attacker)", "revert": "ERROR: UNAUTHORIZED_CALLER", "gate": "factory/owner"},
        {"target": "market", "fn": "applyCover(...)", "revert": "Caller is not allowed to operate", "gate": "parameters.getOwner()"},
        {"target": "market", "fn": "applyBounty(...)", "revert": "Caller is not allowed to operate", "gate": "parameters.getOwner()"},
        {"target": "market", "fn": "redeem(0,1,[])", "revert": "ERROR: NO_APPLICABLE_INCIDENT", "gate": "marketStatus==Payingout"},
        {"target": "index", "fn": "set/setLeverage", "revert": "Caller is not allowed to operate", "gate": "parameters.getOwner()"},
    ],
    "simulations_eth_call_only": [
        {"fn": "factory createPool/createMarket from 0x2222...", "result": "permissionless creation LIVE (Arb/Op success; Astar historical txs prove; RPC cannot CREATE in eth_call)"},
        {"fn": "owner vault.withdrawValue(1e6, owner)", "result": "SUCCESS (owner redeems fee attribution; burns 850745 attr on Arb)"},
        {"fn": "owner controller.emergencyExit(owner)", "result": "SUCCESS on Arb & Op (transfers all aUSDC)"},
        {"fn": "owner vault.setController(0x9999...) on Astar", "result": "SUCCESS"},
    ],
}

state["arbitrum"]["extra"] = {
    **common,
    "factory_templates": {
        "MarketTemplate 0x576e74c0e1adb96b58f2237510853bc7d2561ebe": {"approval": True, "isOpen": True, "duplicate": False},
        "IndexTemplate 0xcb146803913cbfaa66c04e7fefc288af95c05af1": {"approval": True, "isOpen": False, "duplicate": True},
        "ReserveTemplate 0xf2f7e2b6334eec33409f00e1da35b303a6ac8970": {"approval": True, "isOpen": False, "duplicate": True},
    },
    "reflist_market_template": {"slot0_wildcard": True, "slot1_usdc": True, "slot2_registry": True, "slot3_params": True, "slot1to3_wildcard": False},
    "reference_approval_events": 10,
    "createPool_sim_result": "SUCCESS clone 0xfb57b8df7995b517c053b884188979642f5e18c1",
    "owner_attributions_raw": 376475435,
    "owner_attributions_note": "fee attribution accumulated by parameters.getOwner(); redeemable via withdrawValue",
    "reserve_deployed": False,
    "controller_emergencyExit_revert_unprivileged": "OnlyOwner",
}

state["optimism"]["extra"] = {
    **common,
    "factory_templates": {
        "MarketTemplate 0x4763f9720603342aad40056db65883bd55355945": {"approval": True, "isOpen": True, "duplicate": False},
        "IndexTemplate 0x016d4eb10fbce28010fde53c68c016b611b1aa0a": {"approval": True, "isOpen": False, "duplicate": True},
        "ReserveTemplate 0x23896335f2fd8735988472066405a668df3d9863": {"approval": True, "isOpen": False, "duplicate": True},
    },
    "reference_approval_events": 10,
    "reflist_market_template": {"slot0_wildcard": True, "slot1_usdc": True, "slot2_registry": True, "slot3_params": True, "slot1to3_wildcard": False},
    "createPool_sim_result": "SUCCESS clone 0xb679de5ecafbaf1eab1cdda96f548083454542a0",
    "owner_attributions_raw": 153800391,
    "reserve_deployed": False,
    "controller_emergencyExit_revert_unprivileged": "OnlyOwner",
}

state["astar"]["extra"] = {
    **common,
    "factory_fn": "createMarket (0.8.10)",
    "factory_templates": {
        "PoolTemplate 0x0074976043140a371aead31189c2be459950c816": {"approval": True, "isOpen": True, "duplicate": False},
        "IndexTemplate 0x734afd33dfb5100ee91efe690526dffdedbe0cf4": {"approval": True, "isOpen": False, "duplicate": True},
    },
    "reflist_pool_template": {"slot0_wildcard": True, "slot1_usdc": True, "slot2_registry": True, "slot3_params": True, "slot1to3_wildcard": False},
    "reference_approval_events": 9,
    "createMarket_sim_note": "eth_call cannot CREATE on evm.astar.network (control test returned address(0)); 15 historical createMarket txs prove permissionless path; replayed historical tx reverts ERROR: DUPLICATE_MARKET as expected",
    "owner_attributions_raw": 18863572,
    "former_owner_eoa": "0x878bfba05b1d7c8c10868cb51be0732ed8c81646",
    "former_owner_attributions_raw": 75702994,
    "former_owner_note": "interim owner of the shared Ownership contract blocks 1,667,152-4,125,874 (AcceptNewOwnership events); fee attributions redeemable via public withdrawValue; no admin powers remain",
    "reserve_deployed": False,
    "vault_keeper": "0x0000000000000000000000000000000000000000",
    "controller": None,
}

json.dump(state, open("state.json", "w"), indent=1, default=str)
print("state.json updated with extras; chains:", list(state.keys()))
