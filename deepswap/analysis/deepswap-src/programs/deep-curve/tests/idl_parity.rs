//! Checks the committed Anchor IDL (idl/deep_curve.json, regenerated with
//! `node scripts/programs-test.mjs --idl`) against fixtures/ix-vectors.json, which
//! @deep/sdk's builders produce: same instruction set, same account count/order,
//! same signer/writable flags, same fixed addresses, same discriminators.
//! (`ix_vectors.rs` separately checks those vectors against the Rust account structs.)

use serde_json::Value;

const IDL: &str = include_str!("../../../idl/deep_curve.json");
const VECTORS: &str = include_str!("../../../fixtures/ix-vectors.json");

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

#[test]
fn idl_address_matches_program_id() {
    let idl: Value = serde_json::from_str(IDL).unwrap();
    assert_eq!(idl["address"].as_str().unwrap(), deep_curve::ID.to_string());
    assert_eq!(idl["metadata"]["name"], "deep_curve");
}

#[test]
fn idl_instructions_match_sdk_vectors() {
    let idl: Value = serde_json::from_str(IDL).unwrap();
    let vectors: Value = serde_json::from_str(VECTORS).unwrap();
    let vecs = vectors["instructions"].as_object().unwrap();

    let mut covered = std::collections::BTreeSet::new();
    for (vec_name, v) in vecs {
        // variants such as "graduate_low_mint" / "create_token_holder" exercise the same
        // instruction
        let name = if vec_name.starts_with("graduate") {
            "graduate"
        } else if vec_name.starts_with("create_token") {
            "create_token"
        } else {
            vec_name.as_str()
        };
        let ix = idl["instructions"]
            .as_array()
            .unwrap()
            .iter()
            .find(|i| i["name"] == name)
            .unwrap_or_else(|| panic!("IDL has no instruction `{name}` (vector {vec_name})"));
        covered.insert(name.to_string());

        let accts = ix["accounts"].as_array().unwrap();
        let keys = v["keys"].as_array().unwrap();
        // `distribute` takes the splitter destinations as remaining accounts after its own.
        if name == "distribute" {
            assert!(keys.len() > accts.len(), "{vec_name}: account count");
        } else {
            assert_eq!(accts.len(), keys.len(), "{vec_name}: account count");
        }
        for (i, (a, k)) in accts.iter().zip(keys).enumerate() {
            let an = a["name"].as_str().unwrap();
            let flag = |f: &str| a[f].as_bool().unwrap_or(false);
            assert_eq!(
                flag("signer"),
                k["isSigner"].as_bool().unwrap(),
                "{vec_name}[{i}] {an} signer"
            );
            // `graduate.reward_recipient` is read-only in the program's account struct (a
            // creator who is also the migration authority must not break graduation); for a
            // Holder token the SDK passes the holder vault WRITABLE, so graduate can sweep
            // the curve's holder fees to it. That one flag differs on purpose.
            let holder_vault_writable = vec_name == "graduate_holder" && an == "reward_recipient";
            assert_eq!(
                flag("writable") || holder_vault_writable,
                k["isWritable"].as_bool().unwrap(),
                "{vec_name}[{i}] {an} writable"
            );
            // `graduate.create_pool_fee` is pinned to deep-amm's BUILD-TIME
            // DEEP_AMM_CREATE_POOL_FEE_RECEIVER (unset = system program in the committed
            // IDL, a throwaway key under --sbf); the SDK takes it as a caller parameter.
            // `builder` (distribute) is pinned to the BUILD-TIME
            // DEEP_BUILDER_WALLET the same way; the SDK takes it as a caller parameter too.
            // These are the only build-dependent fixed addresses, so they are not compared.
            let build_time = (name == "graduate" && an == "create_pool_fee") || an == "builder";
            if let Some(addr) = a["address"].as_str().filter(|_| !build_time) {
                assert_eq!(
                    addr,
                    k["pubkey"].as_str().unwrap(),
                    "{vec_name}[{i}] {an} fixed address"
                );
            }
        }

        let disc: Vec<u8> = ix["discriminator"]
            .as_array()
            .unwrap()
            .iter()
            .map(|b| b.as_u64().unwrap() as u8)
            .collect();
        assert!(
            v["data"].as_str().unwrap().starts_with(&hex(&disc)),
            "{vec_name}: discriminator"
        );
    }

    // Every IDL instruction must have an SDK vector, so new instructions can't slip by.
    let all: std::collections::BTreeSet<String> = idl["instructions"]
        .as_array()
        .unwrap()
        .iter()
        .map(|i| i["name"].as_str().unwrap().to_string())
        .collect();
    let without_vectors: Vec<_> = all.difference(&covered).cloned().collect();
    assert!(
        without_vectors.is_empty(),
        "IDL instructions without SDK vectors: {without_vectors:?}"
    );
}
