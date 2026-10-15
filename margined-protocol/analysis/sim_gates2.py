#!/usr/bin/env python3
"""Part 2: corrected gate tests + deposit/redeem round trips (read-only simulate)."""
import json, base64, urllib.request, urllib.error, sys, time
sys.path.insert(0, "/home/heisenberg/CA/margined-protocol/analysis")
import sim_gates as SG

TIAR = "osmo1reyz7pwu7y9e7lmzqg6j4h7jcv32du7n7jhnk2lz93a9lxr56ess2qtgzl"
ATOMR = "osmo1hvl5kj4xzdj4udxjv2dzk2zfqhzkd9afqygwq3t84tn53e0250zqrltj48"
OSMR = "osmo15fqmdl8lfl9h0qflljd63ufw9j2m7xmsk3hu5vsn8xpta4hk5chqt7mddc"
D79E = "ibc/D79E7D83AB399BFFF93433E54FAA480C191248FC556924A2A8351AE2638B3877"
ATOM = "ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2"
UOSMO = "uosmo"
BOSMO_VAULT = "osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3"
AMPOSMO_VAULT = "osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq"
STOSMO_VAULT = "osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5"
BONE = "factory/osmo1s3l0lcqc7tu0vpj6wdjz9wqpxv8nk6eraevje4fuwkyjnwuy82qsx3lduv/boneOsmo"
AMP = "factory/osmo1dv8wz09tckslr2wy5z86r46dxvegylhpt97r9yd6qc3kyc6tv42qa89dr9/ampOSMO"
STOSMO = "ibc/D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC"
ESCROW = "neutron1rl7key2jr285vwz79hgkusgtw3ylcgateux5p8ajkk4rya067dkserkva8"

def main():
    results = {}
    def save():
        json.dump(results, open("/home/heisenberg/CA/margined-protocol/analysis/sim-gates2.json", "w"), indent=1)

    def rc(chain, signer, msgs, label):
        SG.run_case(chain, signer, msgs, label, results)
        save()

    # --- Correct nesting: vault_extension.vaultenator.<msg>
    def ext(m): return {"vault_extension": {"vaultenator": m}}
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"crank": {}})}], "g2_TIAR_crank_nonadmin")
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"pause": {}})}], "g2_TIAR_pause_nonadmin")
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"set_open": {}})}], "g2_TIAR_set_open_nonadmin")
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"update_config": {"new_config": {}}})}], "g2_TIAR_update_config_nonadmin")
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"withdraw_and_swap": {"withdraw_amount": "1", "min_amount_out": "0"}})}], "g2_TIAR_withdraw_and_swap_nonctrl")
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"repay": {}})}], "g2_TIAR_repay_nonctrl")
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"set_route": {"pool_route": {}}})}], "g2_TIAR_set_route_nonadmin")
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": ext({"remove_route": {"input_denom": "x", "output_denom": "y"}})}], "g2_TIAR_remove_route_nonadmin")

    # --- deposit tests
    rc("osmosis", "deployer2", [{"contract": TIAR, "msg": {"deposit": {"amount": "500000", "recipient": None}},
                                 "funds": [{"denom": D79E, "amount": "500000"}]}], "g2_dep_TIAR_0.5stTIA")
    rc("osmosis", "lsd_controller", [{"contract": OSMR, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                      "funds": [{"denom": UOSMO, "amount": "1000000"}]}], "g2_dep_OSMR_1osmo")
    rc("osmosis", "deployer2", [{"contract": ATOMR, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                 "funds": [{"denom": ATOM, "amount": "1000000"}]}], "g2_dep_ATOMR_1atom")

    # --- LSD vault deposits (from treasury: holds 316.77 boneOsmo)
    rc("osmosis", "treasury", [{"contract": BOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                "funds": [{"denom": BONE, "amount": "1000000"}]}], "g2_dep_BOSMO_1bone")
    rc("osmosis", "deployer2", [{"contract": AMPOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                 "funds": [{"denom": AMP, "amount": "1000000"}]}], "g2_dep_AMPOSMO_1amp")
    rc("osmosis", "treasury", [{"contract": STOSMO_VAULT, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                "funds": [{"denom": STOSMO, "amount": "1000000"}]}], "g2_dep_STOSMO_1stosmo")
    # LSD vault gate tests (from deployer2, not owner of bOSMO)
    rc("osmosis", "deployer2", [{"contract": BOSMO_VAULT, "msg": ext({"crank": {}})}], "g2_BOSMO_crank_nonadmin")
    rc("osmosis", "deployer2", [{"contract": BOSMO_VAULT, "msg": ext({"rebalance": {}})}], "g2_BOSMO_rebalance_nonctrl")
    rc("osmosis", "deployer2", [{"contract": BOSMO_VAULT, "msg": ext({"process_withdrawal": {}})}], "g2_BOSMO_process_withdrawal_nonctrl")
    rc("osmosis", "deployer2", [{"contract": BOSMO_VAULT, "msg": ext({"update_config": {"new_config": {}}})}], "g2_BOSMO_update_config_nonadmin")

    # --- Neutron escrow: claim from user vs non-user
    rc("neutron", "user_r6rv", [{"contract": ESCROW, "msg": {"claim_redemption": {"limit": 10}}}], "g2_ESCROW_claim_owner_user")
    rc("neutron", "admin", [{"contract": ESCROW, "msg": {"claim_redemption": {"limit": 10}}}], "g2_ESCROW_claim_nonuser_admin")
    # escrow: try to send a redemption as non-whitelisted fund
    rc("neutron", "user_r6rv", [{"contract": ESCROW, "msg": {"send_redemption": {"redemption": {"user": "neutron1r6rv879netg009eh6ty23v57qrq29afecuehlm", "funds": [{"denom": "untrn", "amount": "1"}], "timestamp": 0, "source": "neutron1r6rv879netg009eh6ty23v57qrq29afecuehlm"}}},
                                 "funds": [{"denom": "untrn", "amount": "1"}]}], "g2_ESCROW_send_redemption_nonwhitelisted")
    print("part2 saved")

if __name__ == "__main__":
    main()
