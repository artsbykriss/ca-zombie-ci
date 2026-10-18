//! Runs the shared cross-language vectors (fixtures/curve-vectors.json) against the
//! Rust math, plus property-based invariants mirroring packages/curve-math tests.

use deep_curve::math::*;
use proptest::prelude::*;
use serde_json::Value;

const SOL: u64 = 1_000_000_000;
const UNIT: u64 = 1_000_000;
const VECTORS: &str = include_str!("../../../fixtures/curve-vectors.json");

fn fees() -> Fees {
    Fees {
        protocol_fee_bps: 70,
        creator_fee_bps: 30,
    }
}

fn initial() -> Curve {
    Curve {
        virtual_sol_reserves: 45 * SOL,
        virtual_token_reserves: 1_000_000_000 * UNIT,
        real_sol_reserves: 0,
        real_token_reserves: 800_000_000 * UNIT,
        curve_supply: 800_000_000 * UNIT,
        token_total_supply: 1_000_000_000 * UNIT,
        complete: false,
    }
}

fn s(v: &Value) -> u64 {
    v.as_str().unwrap().parse().unwrap()
}

#[test]
fn fixture_params_match_defaults() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let p = &v["params"];
    let c = initial();
    assert_eq!(s(&p["initialVirtualSol"]), c.virtual_sol_reserves);
    assert_eq!(s(&p["initialVirtualToken"]), c.virtual_token_reserves);
    assert_eq!(s(&p["curveSupply"]), c.curve_supply);
    assert_eq!(s(&p["tokenTotalSupply"]), c.token_total_supply);
    assert_eq!(s(&p["protocolFeeBps"]) as u16, fees().protocol_fee_bps);
    assert_eq!(s(&p["creatorFeeBps"]) as u16, fees().creator_fee_bps);
}

fn check_graduation(c: &Curve, bps: u16, want: &Value, name: &str, i: usize) {
    let g = graduation_allocation(c, bps).unwrap();
    for (field, got) in [
        ("raisedSol", g.raised_sol),
        ("migrationFee", g.migration_fee),
        ("lpSol", g.lp_sol),
        ("lpTokens", g.lp_tokens),
        ("burnTokens", g.burn_tokens),
    ] {
        assert_eq!(
            got,
            s(&want[field]),
            "{name}[{i}] graduation@{bps}bps {field}"
        );
    }
}

/// Security review F5: `validate_graduation_params` agrees with the TypeScript
/// `validateGraduationParams` on every shared case (ranges, a zero pool side, the
/// minimum-liquidity boundary, seeded random parameters).
#[test]
fn graduation_params_match_the_shared_vectors() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let cases = v["graduationParams"].as_array().unwrap();
    assert!(cases.len() >= 50);
    let (mut accepted, mut refused) = (0, 0);
    for c in cases {
        let name = c["name"].as_str().unwrap();
        let u = |k: &str| c[k].as_str().unwrap().parse::<u128>().unwrap();
        // values outside u64 / u16 cannot even be passed to the program: not ok
        let fits = [
            "initialVirtualSol",
            "initialVirtualToken",
            "curveSupply",
            "tokenTotalSupply",
        ]
        .iter()
        .all(|k| u(k) <= u64::MAX as u128)
            && u("migrationFeeBps") <= u16::MAX as u128;
        let ok = fits
            && validate_graduation_params(
                u("initialVirtualSol") as u64,
                u("initialVirtualToken") as u64,
                u("curveSupply") as u64,
                u("tokenTotalSupply") as u64,
                u("migrationFeeBps") as u16,
            )
            .is_ok();
        assert_eq!(ok, c["ok"].as_bool().unwrap(), "{name}");
        if ok {
            accepted += 1;
        } else {
            refused += 1;
        }
    }
    assert!(
        accepted >= 5 && refused >= 5,
        "{accepted} accepted, {refused} refused"
    );
}

/// What the validation promises: under accepted parameters a curve completed at the LEAST
/// possible raise, and at any larger one, allocates SOL and tokens to its pool with more than
/// deep-amm's 100 locked LP units of liquidity.
#[test]
fn accepted_graduation_params_always_leave_a_pool() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let mut checked = 0;
    for c in v["graduationParams"].as_array().unwrap() {
        if !c["ok"].as_bool().unwrap() {
            continue;
        }
        let u = |k: &str| c[k].as_str().unwrap().parse::<u64>().unwrap();
        let (ivs, ivt, cs, total) = (
            u("initialVirtualSol"),
            u("initialVirtualToken"),
            u("curveSupply"),
            u("tokenTotalSupply"),
        );
        let bps = u("migrationFeeBps") as u16;
        let least = sol_in_for_tokens(ivs, ivt, cs).unwrap();
        // the least raise, the next lamports (where the fee ceiling steps), and far more
        for extra in [
            0u64,
            1,
            2,
            3,
            99,
            100,
            101,
            9_999,
            10_000,
            10_001,
            least / 3,
            least,
        ] {
            let Some(raised) = least.checked_add(extra) else {
                continue;
            };
            let Some(v_sol) = ivs.checked_add(raised) else {
                continue;
            };
            let curve = Curve {
                virtual_sol_reserves: v_sol,
                virtual_token_reserves: ivt - cs,
                real_sol_reserves: raised,
                real_token_reserves: 0,
                curve_supply: cs,
                token_total_supply: total,
                complete: true,
            };
            let a = graduation_allocation(&curve, bps)
                .unwrap_or_else(|e| panic!("{}: +{extra}: {e:?}", c["name"]));
            assert!(a.lp_sol > 0 && a.lp_tokens > 0);
            assert!(
                (a.lp_sol as u128) * (a.lp_tokens as u128) >= 101 * 101,
                "{}: +{extra}",
                c["name"]
            );
            assert_eq!(a.lp_tokens + a.burn_tokens, total - cs);
            assert_eq!(a.lp_sol + a.migration_fee, raised);
            checked += 1;
        }
    }
    assert!(checked >= 50);
}

/// The allocation refuses a pool with a zero side instead of returning it.
#[test]
fn graduation_allocation_refuses_a_zero_side() {
    let mut c = initial();
    c.complete = true;
    c.real_token_reserves = 0;
    c.virtual_token_reserves -= c.curve_supply;
    // nothing raised
    assert_eq!(
        graduation_allocation(&c, 100),
        Err(MathError::InvalidParams)
    );
    // raised, but the whole supply was on the curve
    c.real_sol_reserves = 180 * SOL;
    c.virtual_sol_reserves += 180 * SOL;
    assert!(graduation_allocation(&c, 100).is_ok());
    c.token_total_supply = c.curve_supply;
    assert_eq!(
        graduation_allocation(&c, 100),
        Err(MathError::InvalidParams)
    );
}

#[test]
fn cross_language_vectors() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let mut checked = 0;
    let mut graduations = 0;
    for seq in v["sequences"].as_array().unwrap() {
        let name = seq["name"].as_str().unwrap();
        let mut c = initial();
        for (i, step) in seq["steps"].as_array().unwrap().iter().enumerate() {
            let exp = &step["expect"];
            let ok = exp["ok"].as_bool().unwrap();
            let res = if step["op"] == "buy" {
                quote_buy(&c, s(&step["solIn"]), &fees(), 0).map(|q| {
                    assert_eq!(q.tokens_out, s(&exp["tokensOut"]), "{name}[{i}] tokensOut");
                    assert_eq!(q.sol_in, s(&exp["solCharged"]), "{name}[{i}] solCharged");
                    assert_eq!(q.fees.total, s(&exp["feeTotal"]), "{name}[{i}] feeTotal");
                    assert_eq!(
                        q.fees.creator,
                        s(&exp["feeCreator"]),
                        "{name}[{i}] feeCreator"
                    );
                    q.next
                })
            } else {
                quote_sell(&c, s(&step["tokensIn"]), &fees(), 0).map(|q| {
                    assert_eq!(q.sol_out, s(&exp["solOut"]), "{name}[{i}] solOut");
                    assert_eq!(q.fees.total, s(&exp["feeTotal"]), "{name}[{i}] feeTotal");
                    assert_eq!(
                        q.fees.creator,
                        s(&exp["feeCreator"]),
                        "{name}[{i}] feeCreator"
                    );
                    q.next
                })
            };
            match res {
                Ok(next) => {
                    assert!(ok, "{name}[{i}] expected error {}", exp["error"]);
                    let st = &exp["state"];
                    assert_eq!(next.virtual_sol_reserves, s(&st["virtualSolReserves"]));
                    assert_eq!(next.virtual_token_reserves, s(&st["virtualTokenReserves"]));
                    assert_eq!(next.real_sol_reserves, s(&st["realSolReserves"]));
                    assert_eq!(next.real_token_reserves, s(&st["realTokenReserves"]));
                    assert_eq!(next.complete, st["complete"].as_bool().unwrap());
                    // completing steps carry graduation expectations (and only those)
                    assert_eq!(
                        !exp["graduation"].is_null(),
                        next.complete,
                        "{name}[{i}] graduation present"
                    );
                    if next.complete {
                        check_graduation(
                            &next,
                            s(&v["params"]["migrationFeeBps"]) as u16,
                            &exp["graduation"],
                            name,
                            i,
                        );
                        for (bps, want) in exp["graduationByBps"].as_object().unwrap() {
                            check_graduation(&next, bps.parse().unwrap(), want, name, i);
                        }
                        graduations += 1;
                    }
                    c = next;
                }
                Err(e) => {
                    assert!(!ok, "{name}[{i}] unexpected error {e:?}");
                    assert_eq!(e.code(), exp["error"].as_str().unwrap(), "{name}[{i}]");
                }
            }
            checked += 1;
        }
    }
    assert!(checked > 200);
    assert!(
        graduations >= 4,
        "fixtures must cover several completed curves"
    );
}

#[test]
fn whale_buy_caps_and_graduation_allocates() {
    let q = quote_buy(&initial(), 1_000 * SOL, &fees(), 0).unwrap();
    assert!(q.next.complete);
    assert_eq!(q.tokens_out, 800_000_000 * UNIT);
    assert!(q.sol_in < 1_000 * SOL);
    assert_eq!(
        quote_buy(&q.next, SOL, &fees(), 0),
        Err(MathError::CurveComplete)
    );
    assert_eq!(
        quote_sell(&q.next, UNIT, &fees(), 0).unwrap_err(),
        MathError::CurveComplete
    );

    let a = graduation_allocation(&q.next, 100).unwrap();
    assert_eq!(a.lp_sol + a.migration_fee, q.next.real_sol_reserves);
    assert_eq!(a.lp_tokens + a.burn_tokens, 200_000_000 * UNIT);
    assert_eq!(
        graduation_allocation(&initial(), 100),
        Err(MathError::InvalidParams)
    );
}

#[test]
fn rejects_bad_fees_slippage_and_huge_inputs() {
    assert_eq!(
        compute_fees(
            1,
            &Fees {
                protocol_fee_bps: 1_001,
                creator_fee_bps: 0
            }
        ),
        Err(MathError::InvalidFee)
    );
    assert_eq!(
        compute_fees(
            1,
            &Fees {
                protocol_fee_bps: 0,
                creator_fee_bps: 1_001
            }
        ),
        Err(MathError::InvalidFee)
    );
    // one total cap per side: protocol + reward <= 10%
    assert_eq!(
        compute_fees(
            1,
            &Fees {
                protocol_fee_bps: 900,
                creator_fee_bps: 101
            }
        ),
        Err(MathError::InvalidFee)
    );
    assert!(compute_fees(
        1,
        &Fees {
            protocol_fee_bps: 500,
            creator_fee_bps: 500
        }
    )
    .is_ok());
    // a launch: the reward rate is 0 for Standard, 1..=500 otherwise
    assert_eq!(MAX_REWARD_BPS, 500);
    for (model, bps, ok) in [
        (REWARD_MODEL_STANDARD, 0u16, true),
        (REWARD_MODEL_STANDARD, 1, false),
        (REWARD_MODEL_CREATOR, 0, false),
        (REWARD_MODEL_CREATOR, 1, true),
        (REWARD_MODEL_HOLDER, 100, true),
        (REWARD_MODEL_HOLDER, 500, true),
        (REWARD_MODEL_CREATOR, 501, false),
        (3, 100, false),
    ] {
        assert_eq!(
            validate_launch_reward(model, bps).is_ok(),
            ok,
            "{model}/{bps}"
        );
    }
    // u64::MAX buy must not panic; it caps at remaining supply.
    let q = quote_buy(&initial(), u64::MAX, &fees(), 0).unwrap();
    assert!(q.next.complete);
    let base = quote_buy(&initial(), SOL, &fees(), 0).unwrap();
    assert_eq!(
        quote_buy(&initial(), SOL, &fees(), base.tokens_out + 1),
        Err(MathError::SlippageExceeded)
    );
}

proptest! {
    #![proptest_config(ProptestConfig::with_cases(512))]

    #[test]
    fn invariants_hold(ops in prop::collection::vec((any::<bool>(), 0u64..50 * SOL, 0u64..10_000), 0..60)) {
        let mut c = initial();
        let (mut user_in, mut user_out, mut fee_total) = (0u128, 0u128, 0u128);
        for (is_buy, sol, frac) in ops {
            let k0 = c.virtual_sol_reserves as u128 * c.virtual_token_reserves as u128;
            let r = if is_buy {
                quote_buy(&c, sol, &fees(), 0).map(|q| {
                    user_in += q.sol_in as u128;
                    fee_total += q.fees.total as u128;
                    q.next
                })
            } else {
                let sold = c.curve_supply - c.real_token_reserves;
                quote_sell(&c, ((sold as u128 * frac as u128) / 10_000) as u64, &fees(), 0).map(|q| {
                    user_out += q.sol_out as u128;
                    fee_total += q.fees.total as u128;
                    q.next
                })
            };
            if let Ok(next) = r {
                c = next;
                let k1 = c.virtual_sol_reserves as u128 * c.virtual_token_reserves as u128;
                prop_assert!(k1 >= k0);
                prop_assert!(c.real_token_reserves <= c.curve_supply);
                prop_assert_eq!(c.virtual_sol_reserves - c.real_sol_reserves, 45 * SOL);
                prop_assert_eq!(user_in, c.real_sol_reserves as u128 + user_out + fee_total);
            }
        }
    }
}

fn s128(v: &Value) -> u128 {
    v.as_str().unwrap().parse().unwrap()
}

/// DEEP V1 fee splitter: the `splitter` section is generated by packages/curve-math
/// (`splitRound`); the program's `split_round` must agree bit for bit.
#[test]
fn splitter_vectors() {
    use deep_curve::splitter::split_round;
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let seqs = v["splitter"].as_array().expect("splitter vectors");
    assert!(seqs.len() >= 5);
    for q in seqs {
        let bps: Vec<u16> = q["bps"]
            .as_array()
            .unwrap()
            .iter()
            .map(|b| b.as_str().unwrap().parse().unwrap())
            .collect();
        let (mut base, mut paid, mut retained) = (0u128, 0u64, 0u64);
        for r in q["rounds"].as_array().unwrap() {
            assert_eq!(retained, s(&r["retainedIn"]));
            let o = split_round(s(&r["revenue"]), retained, base, paid, &bps).unwrap();
            let name = q["name"].as_str().unwrap();
            assert_eq!(o.builder, s(&r["builder"]), "{name}");
            assert_eq!(o.pool, s(&r["pool"]), "{name}");
            let shares: Vec<u64> = r["shares"].as_array().unwrap().iter().map(s).collect();
            assert_eq!(o.shares, shares, "{name}");
            assert_eq!(o.retained, s(&r["retained"]), "{name}");
            assert_eq!(o.base_total, s128(&r["baseTotal"]), "{name}");
            assert_eq!(o.builder_paid_total, s(&r["builderPaidTotal"]), "{name}");
            base = o.base_total;
            paid = o.builder_paid_total;
            retained = o.retained;
        }
    }
    // A 1 SOL curve buy's protocol fee (7_000_000 at 70 bps) through the splitter: 700_000
    // to the builder (10%), the rest to the destinations.
    let q = quote_buy(&initial(), SOL, &fees(), 0).unwrap();
    let o = split_round(q.fees.protocol, 0, 0, 0, &[10_000]).unwrap();
    assert_eq!(o.builder, 700_000);
    assert_eq!(o.shares, vec![6_300_000]);
}

proptest! {
    #![proptest_config(ProptestConfig::with_cases(512))]

    /// Over any sequence of distributions the builder has been paid exactly floor(10%) of all
    /// revenue (never more); builder + destinations + retained dust == revenue (nothing lost
    /// or counted twice); the dust never exceeds one lamport per destination.
    #[test]
    fn splitter_builder_exact_over_time(
        revs in prop::collection::vec(1u64..(1u64 << 40), 1..200),
        bps_set in 0usize..4,
    ) {
        use deep_curve::splitter::split_round;
        let sets: [&[u16]; 4] = [&[10_000], &[5_000, 5_000], &[3_333, 3_333, 3_334], &[9_999, 1]];
        let bps = sets[bps_set];
        let (mut base, mut paid, mut retained) = (0u128, 0u64, 0u64);
        let (mut total, mut builder, mut dests) = (0u128, 0u128, 0u128);
        for r in &revs {
            let o = split_round(*r, retained, base, paid, bps).unwrap();
            total += *r as u128;
            builder += o.builder as u128;
            dests += o.shares.iter().map(|x| *x as u128).sum::<u128>();
            base = o.base_total;
            paid = o.builder_paid_total;
            retained = o.retained;
            prop_assert_eq!(builder, total / 10);
            prop_assert_eq!(builder + dests + retained as u128, total);
            prop_assert!((retained as usize) < bps.len());
        }
    }
}

// ───────────── DEEP V1: per-side protocol fee + reward model ─────────────

fn fees_v1(v: &Value) -> FeesV1 {
    FeesV1 {
        buy_protocol_fee_bps: s(&v["buyProtocolFeeBps"]) as u16,
        sell_protocol_fee_bps: s(&v["sellProtocolFeeBps"]) as u16,
        reward_bps: s(&v["rewardBps"]) as u16,
        reward_model: v["rewardModel"].as_u64().unwrap() as u8,
    }
}

/// The `v1` section is generated by packages/curve-math (`quoteBuyV1` / `quoteSellV1`); the
/// Rust `quote_buy_v1` / `quote_sell_v1` must agree bit for bit, for every reward model, on
/// the quote and on where each lamport of the fee goes.
#[test]
fn v1_cross_language_vectors() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let seqs = v["v1"].as_array().expect("v1 vectors");
    assert!(seqs.len() >= 8);
    let (mut checked, mut completed) = (0, 0);
    let mut models = [0usize; 3];
    let (mut creator_total, mut holder_total) = (0u128, 0u128);
    for seq in seqs {
        let name = seq["name"].as_str().unwrap();
        let f = fees_v1(&seq["fees"]);
        models[f.reward_model as usize] += 1;
        let mut c = initial();
        for (i, step) in seq["steps"].as_array().unwrap().iter().enumerate() {
            let exp = &step["expect"];
            let ok = exp["ok"].as_bool().unwrap();
            let res = if step["op"] == "buy" {
                quote_buy_v1(&c, s(&step["solIn"]), &f, 0).map(|(q, r)| {
                    assert_eq!(q.tokens_out, s(&exp["tokensOut"]), "{name}[{i}] tokensOut");
                    assert_eq!(q.sol_in, s(&exp["solCharged"]), "{name}[{i}] solCharged");
                    assert_eq!(q.sol_in, q.sol_to_curve + q.fees.total, "{name}[{i}]");
                    (q.fees, r, q.next)
                })
            } else {
                quote_sell_v1(&c, s(&step["tokensIn"]), &f, 0).map(|(q, r)| {
                    assert_eq!(q.sol_out, s(&exp["solOut"]), "{name}[{i}] solOut");
                    assert_eq!(q.sol_from_curve, q.sol_out + q.fees.total, "{name}[{i}]");
                    (q.fees, r, q.next)
                })
            };
            match res {
                Ok((fees, r, next)) => {
                    assert!(ok, "{name}[{i}] expected error {}", exp["error"]);
                    assert_eq!(fees.total, s(&exp["feeTotal"]), "{name}[{i}] feeTotal");
                    assert_eq!(
                        r.protocol,
                        s(&exp["feeProtocol"]),
                        "{name}[{i}] feeProtocol"
                    );
                    assert_eq!(r.creator, s(&exp["feeCreator"]), "{name}[{i}] feeCreator");
                    assert_eq!(r.holder, s(&exp["feeHolder"]), "{name}[{i}] feeHolder");
                    assert_eq!(r.protocol + r.creator + r.holder, fees.total, "{name}[{i}]");
                    creator_total += r.creator as u128;
                    holder_total += r.holder as u128;
                    let st = &exp["state"];
                    assert_eq!(next.virtual_sol_reserves, s(&st["virtualSolReserves"]));
                    assert_eq!(next.virtual_token_reserves, s(&st["virtualTokenReserves"]));
                    assert_eq!(next.real_sol_reserves, s(&st["realSolReserves"]));
                    assert_eq!(next.real_token_reserves, s(&st["realTokenReserves"]));
                    assert_eq!(next.complete, st["complete"].as_bool().unwrap());
                    completed += next.complete as usize;
                    c = next;
                }
                Err(e) => {
                    assert!(!ok, "{name}[{i}] unexpected error {e:?}");
                    assert_eq!(e.code(), exp["error"].as_str().unwrap(), "{name}[{i}]");
                }
            }
            checked += 1;
        }
    }
    assert!(checked > 1_000, "{checked}");
    assert!(models.iter().all(|n| *n >= 2), "every model: {models:?}");
    assert!(completed >= 4, "completed curves in the v1 vectors");
    assert!(creator_total > 0 && holder_total > 0);
}

/// The `feeSchedules` section: which Config fee schedules pass the on-chain cap.
#[test]
fn fee_schedule_cap_vectors() {
    let v: Value = serde_json::from_str(VECTORS).unwrap();
    let rows = v["feeSchedules"].as_array().expect("feeSchedules vectors");
    assert!(rows.len() >= 10);
    let n = |x: &Value| x.as_u64().unwrap() as u16;
    let (mut accepted, mut rejected) = (0, 0);
    for r in rows {
        let res = validate_fee_schedule(
            n(&r["buyProtocolFeeBps"]),
            n(&r["sellProtocolFeeBps"]),
            n(&r["creatorFeeBps"]),
            n(&r["creatorRewardBps"]),
            n(&r["holderRewardBps"]),
        );
        assert_eq!(res.is_ok(), r["ok"].as_bool().unwrap(), "{r}");
        if let Err(e) = res {
            assert_eq!(e, MathError::InvalidFee);
            rejected += 1;
        } else {
            accepted += 1;
        }
    }
    assert!(accepted >= 5 && rejected >= 5);
}

#[test]
fn v1_worked_examples_and_rejections() {
    let std = FeesV1 {
        buy_protocol_fee_bps: 125,
        sell_protocol_fee_bps: 125,
        reward_bps: 0,
        reward_model: REWARD_MODEL_STANDARD,
    };
    // 1 SOL buy at the V1 target: 12_500_000 to DEEP, nothing else, whatever the model.
    for model in [
        REWARD_MODEL_STANDARD,
        REWARD_MODEL_CREATOR,
        REWARD_MODEL_HOLDER,
    ] {
        let f = FeesV1 {
            reward_model: model,
            ..std
        };
        let (q, r) = quote_buy_v1(&initial(), SOL, &f, 0).unwrap();
        assert_eq!(q.fees.total, 12_500_000);
        assert_eq!((r.protocol, r.creator, r.holder), (12_500_000, 0, 0));
    }
    // with the curve reward parameter at 100 bps
    let creator = FeesV1 {
        reward_bps: 100,
        reward_model: REWARD_MODEL_CREATOR,
        ..std
    };
    let (q, r) = quote_buy_v1(&initial(), SOL, &creator, 0).unwrap();
    assert_eq!(q.fees.total, 22_500_000);
    assert_eq!(
        (r.protocol, r.creator, r.holder),
        (12_500_000, 10_000_000, 0)
    );
    let holder = FeesV1 {
        reward_model: REWARD_MODEL_HOLDER,
        ..creator
    };
    let (qh, r) = quote_buy_v1(&initial(), SOL, &holder, 0).unwrap();
    assert_eq!(
        (r.protocol, r.creator, r.holder),
        (12_500_000, 0, 10_000_000)
    );
    assert_eq!(
        qh.next, q.next,
        "the model only changes where the reward goes"
    );

    // a Standard token with the legacy creator fee trades exactly as before V1
    let legacy = FeesV1 {
        buy_protocol_fee_bps: 70,
        sell_protocol_fee_bps: 70,
        reward_bps: 30,
        reward_model: REWARD_MODEL_STANDARD,
    };
    let (q1, r1) = quote_buy_v1(&initial(), 3 * SOL, &legacy, 0).unwrap();
    let q0 = quote_buy(&initial(), 3 * SOL, &fees(), 0).unwrap();
    assert_eq!(q1, q0);
    assert_eq!(
        (r1.protocol, r1.creator, r1.holder),
        (q0.fees.protocol, q0.fees.creator, 0)
    );

    // rejections: unknown model, either side above the cap
    let bad_model = FeesV1 {
        reward_model: 3,
        ..std
    };
    assert_eq!(
        quote_buy_v1(&initial(), SOL, &bad_model, 0).unwrap_err(),
        MathError::InvalidParams
    );
    assert_eq!(
        route_fees(
            3,
            &FeeSplit {
                total: 1,
                protocol: 1,
                creator: 0
            }
        )
        .unwrap_err(),
        MathError::InvalidParams
    );
    for (buy, sell, reward) in [(1_001, 0, 100), (0, 1_001, 100), (125, 125, 1_001)] {
        let f = FeesV1 {
            buy_protocol_fee_bps: buy,
            sell_protocol_fee_bps: sell,
            reward_bps: reward,
            reward_model: REWARD_MODEL_HOLDER,
        };
        assert_eq!(validate_fees_v1(&f), Err(MathError::InvalidFee));
        assert_eq!(
            quote_buy_v1(&initial(), SOL, &f, 0).unwrap_err(),
            MathError::InvalidFee
        );
    }
}

proptest! {
    #![proptest_config(ProptestConfig::with_cases(512))]

    /// Solvency with reward accrual, for any rates and any model: after every trade, the SOL
    /// users paid in minus the SOL paid out equals the real reserves plus the three fee
    /// accumulators (what `assert_solvent` requires the curve PDA to hold above rent), and each
    /// trade's fee is routed exactly once.
    #[test]
    fn v1_invariants_hold(
        buy_bps in 0u16..=500,
        sell_bps in 0u16..=500,
        reward_bps in 0u16..=500,
        model in 0u8..=2,
        ops in prop::collection::vec((any::<bool>(), 0u64..50 * SOL, 0u64..10_000), 0..60),
    ) {
        let f = FeesV1 {
            buy_protocol_fee_bps: buy_bps,
            sell_protocol_fee_bps: sell_bps,
            reward_bps,
            reward_model: model,
        };
        let mut c = initial();
        let (mut user_in, mut user_out) = (0u128, 0u128);
        let (mut protocol, mut creator, mut holder) = (0u128, 0u128, 0u128);
        for (is_buy, sol, frac) in ops {
            let k0 = c.virtual_sol_reserves as u128 * c.virtual_token_reserves as u128;
            let r = if is_buy {
                quote_buy_v1(&c, sol, &f, 0).map(|(q, r)| {
                    user_in += q.sol_in as u128;
                    (q.fees, r, q.next)
                })
            } else {
                let sold = c.curve_supply - c.real_token_reserves;
                quote_sell_v1(&c, ((sold as u128 * frac as u128) / 10_000) as u64, &f, 0).map(|(q, r)| {
                    user_out += q.sol_out as u128;
                    (q.fees, r, q.next)
                })
            };
            if let Ok((fees, r, next)) = r {
                prop_assert_eq!(r.protocol + r.creator + r.holder, fees.total);
                protocol += r.protocol as u128;
                creator += r.creator as u128;
                holder += r.holder as u128;
                c = next;
                let k1 = c.virtual_sol_reserves as u128 * c.virtual_token_reserves as u128;
                prop_assert!(k1 >= k0);
                prop_assert_eq!(
                    user_in - user_out,
                    c.real_sol_reserves as u128 + protocol + creator + holder
                );
                if model == REWARD_MODEL_HOLDER {
                    prop_assert_eq!(creator, 0);
                } else {
                    prop_assert_eq!(holder, 0);
                }
                if reward_bps == 0 {
                    prop_assert_eq!(creator + holder, 0);
                }
            }
        }
    }
}
