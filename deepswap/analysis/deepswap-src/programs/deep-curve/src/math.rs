//! Deep Curve integer math. Behavior must match `packages/curve-math/src/math.ts`
//! exactly — both are tested against `fixtures/curve-vectors.json`.
//!
//! Rounding: outputs to the user round DOWN, fees and required inputs round UP.
//! All intermediate products use checked u128 arithmetic.

pub const BPS_DENOMINATOR: u128 = 10_000;
/// THE hard cap on what a trade costs on one side: protocol fee + reward rate (10%). Checked
/// in one place, `validate_fees`, for every launch and every trade.
pub const MAX_TOTAL_FEE_BPS: u16 = 1_000;
/// Hard ceiling of a token's reward rate, the rate its creator chooses at launch (5%). Only
/// a program upgrade changes it. The admin sets the CURRENT maximum for new launches at or
/// under it (`Config.max_reward_bps`).
pub const MAX_REWARD_BPS: u16 = 500;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MathError {
    ZeroAmount,
    CurveComplete,
    InsufficientReserves,
    SlippageExceeded,
    InvalidFee,
    InvalidParams,
    Overflow,
}

impl MathError {
    pub fn code(&self) -> &'static str {
        match self {
            MathError::ZeroAmount => "ZeroAmount",
            MathError::CurveComplete => "CurveComplete",
            MathError::InsufficientReserves => "InsufficientReserves",
            MathError::SlippageExceeded => "SlippageExceeded",
            MathError::InvalidFee => "InvalidFee",
            MathError::InvalidParams => "InvalidParams",
            MathError::Overflow => "Overflow",
        }
    }
}

pub type MathResult<T> = Result<T, MathError>;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Fees {
    pub protocol_fee_bps: u16,
    pub creator_fee_bps: u16,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Curve {
    pub virtual_sol_reserves: u64,
    pub virtual_token_reserves: u64,
    pub real_sol_reserves: u64,
    pub real_token_reserves: u64,
    pub curve_supply: u64,
    pub token_total_supply: u64,
    pub complete: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FeeSplit {
    pub total: u64,
    pub protocol: u64,
    pub creator: u64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BuyResult {
    pub sol_in: u64,
    pub sol_to_curve: u64,
    pub fees: FeeSplit,
    pub tokens_out: u64,
    pub next: Curve,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SellResult {
    pub sol_from_curve: u64,
    pub fees: FeeSplit,
    pub sol_out: u64,
    pub next: Curve,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GraduationAllocation {
    pub raised_sol: u64,
    pub migration_fee: u64,
    pub lp_sol: u64,
    pub lp_tokens: u64,
    pub burn_tokens: u64,
}

fn to_u64(v: u128) -> MathResult<u64> {
    u64::try_from(v).map_err(|_| MathError::Overflow)
}

fn mul(a: u128, b: u128) -> MathResult<u128> {
    a.checked_mul(b).ok_or(MathError::Overflow)
}

fn add(a: u128, b: u128) -> MathResult<u128> {
    a.checked_add(b).ok_or(MathError::Overflow)
}

fn sub(a: u128, b: u128) -> MathResult<u128> {
    a.checked_sub(b).ok_or(MathError::Overflow)
}

pub fn ceil_div(a: u128, b: u128) -> MathResult<u128> {
    if b == 0 {
        return Err(MathError::InvalidParams);
    }
    if a == 0 {
        return Ok(0);
    }
    Ok(sub(add(a, b)?, 1)? / b)
}

/// The total cap of one side: protocol fee + reward rate (`creator_fee_bps`) at most
/// `MAX_TOTAL_FEE_BPS`.
pub fn validate_fees(f: &Fees) -> MathResult<()> {
    if (f.protocol_fee_bps as u32) + (f.creator_fee_bps as u32) > MAX_TOTAL_FEE_BPS as u32 {
        return Err(MathError::InvalidFee);
    }
    Ok(())
}

// ───────────── DEEP V1: per-side protocol fee + reward model ─────────────
//
// The curve math above is unchanged. V1 only selects which `Fees` a trade uses (the buy or the
// sell protocol rate, plus the token's reward rate) and where the reward part of the fee goes.
// Mirrors `quoteBuyV1` / `quoteSellV1` in packages/curve-math/src/v1.ts.

/// No reward: a token launched as Standard has `reward_bps` 0 (`validate_launch_reward`).
/// (A non-zero rate on a Standard curve would accrue to the creator, as the pre-V1 creator
/// fee did; no curve is created or migrated that way.)
pub const REWARD_MODEL_STANDARD: u8 = 0;
/// The reward part accrues to the token's creator (`claim_creator_fees`).
pub const REWARD_MODEL_CREATOR: u8 = 1;
/// The reward part accrues to the token's holders (`sweep_holder_fees` to the holder vault).
pub const REWARD_MODEL_HOLDER: u8 = 2;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FeesV1 {
    pub buy_protocol_fee_bps: u16,
    pub sell_protocol_fee_bps: u16,
    /// The token's reward rate, chosen by its creator at launch: charged on both sides on
    /// top of the protocol fee. 0 for Standard.
    pub reward_bps: u16,
    pub reward_model: u8,
}

/// Where one trade's fee goes. `protocol + creator + holder == FeeSplit.total`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FeeRouting {
    pub protocol: u64,
    pub creator: u64,
    pub holder: u64,
}

pub fn validate_reward_model(reward_model: u8) -> MathResult<()> {
    if reward_model > REWARD_MODEL_HOLDER {
        return Err(MathError::InvalidParams);
    }
    Ok(())
}

/// What a creator may choose at launch: Standard with no reward rate, or Creator / Holder
/// with a rate of 1..=`MAX_REWARD_BPS` (the hard ceiling; the admin's current maximum and the
/// total cap per side are checked by the caller). Both are immutable afterwards.
pub fn validate_launch_reward(reward_model: u8, reward_bps: u16) -> MathResult<()> {
    validate_reward_model(reward_model)?;
    let ok = if reward_model == REWARD_MODEL_STANDARD {
        reward_bps == 0
    } else {
        (1..=MAX_REWARD_BPS).contains(&reward_bps)
    };
    if !ok {
        return Err(MathError::InvalidFee);
    }
    Ok(())
}

/// The `Fees` of one side of a V1 token.
pub fn side_fees(f: &FeesV1, is_buy: bool) -> Fees {
    Fees {
        protocol_fee_bps: if is_buy {
            f.buy_protocol_fee_bps
        } else {
            f.sell_protocol_fee_bps
        },
        creator_fee_bps: f.reward_bps,
    }
}

pub fn validate_fees_v1(f: &FeesV1) -> MathResult<()> {
    validate_reward_model(f.reward_model)?;
    validate_fees(&side_fees(f, true))?;
    validate_fees(&side_fees(f, false))
}

/// Hard cap for a whole fee schedule (Config): on each side, the protocol rate plus the largest
/// reward rate any token could snapshot must stay within `MAX_TOTAL_FEE_BPS` (10%).
pub fn validate_fee_schedule(
    buy_protocol_fee_bps: u16,
    sell_protocol_fee_bps: u16,
    creator_fee_bps: u16,
    creator_reward_bps: u16,
    holder_reward_bps: u16,
) -> MathResult<()> {
    let reward = creator_fee_bps
        .max(creator_reward_bps)
        .max(holder_reward_bps);
    for protocol in [buy_protocol_fee_bps, sell_protocol_fee_bps] {
        validate_fees(&Fees {
            protocol_fee_bps: protocol,
            creator_fee_bps: reward,
        })?;
    }
    Ok(())
}

/// Routes the reward part of a fee (`FeeSplit.creator`) by reward model.
pub fn route_fees(reward_model: u8, fees: &FeeSplit) -> MathResult<FeeRouting> {
    validate_reward_model(reward_model)?;
    let holder = reward_model == REWARD_MODEL_HOLDER;
    Ok(FeeRouting {
        protocol: fees.protocol,
        creator: if holder { 0 } else { fees.creator },
        holder: if holder { fees.creator } else { 0 },
    })
}

pub fn quote_buy_v1(
    c: &Curve,
    sol_in: u64,
    f: &FeesV1,
    min_tokens_out: u64,
) -> MathResult<(BuyResult, FeeRouting)> {
    validate_fees_v1(f)?;
    let q = quote_buy(c, sol_in, &side_fees(f, true), min_tokens_out)?;
    let routing = route_fees(f.reward_model, &q.fees)?;
    Ok((q, routing))
}

pub fn quote_sell_v1(
    c: &Curve,
    tokens_in: u64,
    f: &FeesV1,
    min_sol_out: u64,
) -> MathResult<(SellResult, FeeRouting)> {
    validate_fees_v1(f)?;
    let q = quote_sell(c, tokens_in, &side_fees(f, false), min_sol_out)?;
    let routing = route_fees(f.reward_model, &q.fees)?;
    Ok((q, routing))
}

pub fn compute_fees(amount: u64, f: &Fees) -> MathResult<FeeSplit> {
    validate_fees(f)?;
    let a = amount as u128;
    let bps = f.protocol_fee_bps as u128 + f.creator_fee_bps as u128;
    let total = to_u64(ceil_div(mul(a, bps)?, BPS_DENOMINATOR)?)?;
    let creator = to_u64(mul(a, f.creator_fee_bps as u128)? / BPS_DENOMINATOR)?;
    Ok(FeeSplit {
        total,
        creator,
        protocol: total - creator,
    })
}

pub fn tokens_out_for_sol(v_sol: u64, v_token: u64, sol_net: u64) -> MathResult<u64> {
    let num = mul(v_token as u128, sol_net as u128)?;
    let den = add(v_sol as u128, sol_net as u128)?;
    to_u64(num / den)
}

pub fn sol_in_for_tokens(v_sol: u64, v_token: u64, tokens: u64) -> MathResult<u64> {
    if tokens >= v_token {
        return Err(MathError::InsufficientReserves);
    }
    to_u64(ceil_div(
        mul(v_sol as u128, tokens as u128)?,
        (v_token - tokens) as u128,
    )?)
}

pub fn sol_out_for_tokens(v_sol: u64, v_token: u64, tokens: u64) -> MathResult<u64> {
    let num = mul(v_sol as u128, tokens as u128)?;
    let den = add(v_token as u128, tokens as u128)?;
    to_u64(num / den)
}

pub fn gross_for_net(net: u64, f: &Fees) -> MathResult<u64> {
    let bps = f.protocol_fee_bps as u128 + f.creator_fee_bps as u128;
    let mut g = to_u64(ceil_div(
        mul(net as u128, BPS_DENOMINATOR)?,
        BPS_DENOMINATOR - bps,
    )?)?;
    // bounded: at most a couple of iterations due to fee ceil
    for _ in 0..4 {
        if g - compute_fees(g, f)?.total >= net {
            return Ok(g);
        }
        g = g.checked_add(1).ok_or(MathError::Overflow)?;
    }
    Err(MathError::Overflow)
}

pub fn quote_buy(c: &Curve, sol_in: u64, f: &Fees, min_tokens_out: u64) -> MathResult<BuyResult> {
    if c.complete || c.real_token_reserves == 0 {
        return Err(MathError::CurveComplete);
    }
    if sol_in == 0 {
        return Err(MathError::ZeroAmount);
    }
    let mut gross = sol_in;
    let mut fees = compute_fees(gross, f)?;
    let mut net = gross - fees.total;
    if net == 0 {
        return Err(MathError::ZeroAmount);
    }
    let mut tokens_out = tokens_out_for_sol(c.virtual_sol_reserves, c.virtual_token_reserves, net)?;

    if tokens_out >= c.real_token_reserves {
        tokens_out = c.real_token_reserves;
        let net_needed =
            sol_in_for_tokens(c.virtual_sol_reserves, c.virtual_token_reserves, tokens_out)?;
        if net_needed < net {
            gross = gross_for_net(net_needed, f)?;
            fees = compute_fees(gross, f)?;
            net = gross - fees.total;
        }
    }

    if tokens_out == 0 {
        return Err(MathError::ZeroAmount);
    }
    if tokens_out < min_tokens_out {
        return Err(MathError::SlippageExceeded);
    }

    let real_token_reserves = c.real_token_reserves - tokens_out;
    let next = Curve {
        virtual_sol_reserves: c
            .virtual_sol_reserves
            .checked_add(net)
            .ok_or(MathError::Overflow)?,
        virtual_token_reserves: c.virtual_token_reserves - tokens_out,
        real_sol_reserves: c
            .real_sol_reserves
            .checked_add(net)
            .ok_or(MathError::Overflow)?,
        real_token_reserves,
        complete: real_token_reserves == 0,
        ..*c
    };
    Ok(BuyResult {
        sol_in: gross,
        sol_to_curve: net,
        fees,
        tokens_out,
        next,
    })
}

pub fn quote_sell(c: &Curve, tokens_in: u64, f: &Fees, min_sol_out: u64) -> MathResult<SellResult> {
    if c.complete {
        return Err(MathError::CurveComplete);
    }
    if tokens_in == 0 {
        return Err(MathError::ZeroAmount);
    }
    let sold = c
        .curve_supply
        .checked_sub(c.real_token_reserves)
        .ok_or(MathError::Overflow)?;
    if tokens_in > sold {
        return Err(MathError::InsufficientReserves);
    }
    let sol_from_curve =
        sol_out_for_tokens(c.virtual_sol_reserves, c.virtual_token_reserves, tokens_in)?;
    if sol_from_curve > c.real_sol_reserves {
        return Err(MathError::InsufficientReserves);
    }
    let fees = compute_fees(sol_from_curve, f)?;
    let sol_out = sol_from_curve - fees.total;
    if sol_out == 0 {
        return Err(MathError::ZeroAmount);
    }
    if sol_out < min_sol_out {
        return Err(MathError::SlippageExceeded);
    }
    let next = Curve {
        virtual_sol_reserves: c.virtual_sol_reserves - sol_from_curve,
        virtual_token_reserves: c
            .virtual_token_reserves
            .checked_add(tokens_in)
            .ok_or(MathError::Overflow)?,
        real_sol_reserves: c.real_sol_reserves - sol_from_curve,
        real_token_reserves: c.real_token_reserves + tokens_in,
        ..*c
    };
    Ok(SellResult {
        sol_from_curve,
        fees,
        sol_out,
        next,
    })
}

pub fn graduation_allocation(
    c: &Curve,
    migration_fee_bps: u16,
) -> MathResult<GraduationAllocation> {
    if !c.complete {
        return Err(MathError::InvalidParams);
    }
    let reserve = c
        .token_total_supply
        .checked_sub(c.curve_supply)
        .ok_or(MathError::Overflow)?;
    let migration_fee = to_u64(ceil_div(
        mul(c.real_sol_reserves as u128, migration_fee_bps as u128)?,
        BPS_DENOMINATOR,
    )?)?;
    let lp_sol = c.real_sol_reserves - migration_fee;
    let mut lp_tokens = to_u64(
        mul(lp_sol as u128, c.virtual_token_reserves as u128)? / c.virtual_sol_reserves as u128,
    )?;
    if lp_tokens > reserve {
        lp_tokens = reserve;
    }
    // A pool needs both sides: a zero side can never be deposited. `validate_graduation_params`
    // rules it out for every curve launched under a validated Config.
    if lp_sol == 0 || lp_tokens == 0 {
        return Err(MathError::InvalidParams);
    }
    Ok(GraduationAllocation {
        raised_sol: c.real_sol_reserves,
        migration_fee,
        lp_sol,
        lp_tokens,
        burn_tokens: reserve - lp_tokens,
    })
}

/// deep-amm locks the first 100 LP units of a new pool (`lock_lp_amount`): the initial
/// liquidity `floor(sqrt(amount_0 * amount_1))` must be above it.
pub const MIN_POOL_LIQUIDITY: u128 = 100;

/// Launch parameters under which EVERY curve can graduate (security review F5). Mirrors
/// `validateGraduationParams` in packages/curve-math/src/params.ts (shared vectors:
/// `graduationParams` in fixtures/curve-vectors.json).
///
/// * `0 < curve_supply < token_total_supply`: tokens are left for the pool;
/// * `initial_virtual_token > curve_supply`, `initial_virtual_sol > 0`;
/// * the graduation allocation of a completed curve has SOL and tokens for the pool and
///   enough of both for deep-amm's minimum liquidity, whatever path the curve took.
///
/// The check is made on the completed curve that raised the LEAST SOL. Trades only ever round
/// against the trader, so `virtual_sol * virtual_token` never decreases and a completed curve
/// holds at least `sol_in_for_tokens(initial_virtual_sol, initial_virtual_token, curve_supply)`.
/// `lp_sol` does not decrease when more is raised. `lp_tokens` can, by rounding only, by less
/// than `virtual_token / virtual_sol + 1` (one step of the migration-fee ceiling), so that much
/// is taken off before checking.
pub fn validate_graduation_params(
    initial_virtual_sol: u64,
    initial_virtual_token: u64,
    curve_supply: u64,
    token_total_supply: u64,
    migration_fee_bps: u16,
) -> MathResult<()> {
    if initial_virtual_sol == 0
        || curve_supply == 0
        || curve_supply >= token_total_supply
        || initial_virtual_token <= curve_supply
        || migration_fee_bps as u128 > BPS_DENOMINATOR
    {
        return Err(MathError::InvalidParams);
    }
    let raised = sol_in_for_tokens(initial_virtual_sol, initial_virtual_token, curve_supply)?;
    let v_sol = add(initial_virtual_sol as u128, raised as u128)?;
    let v_token = (initial_virtual_token - curve_supply) as u128;
    let migration_fee = ceil_div(
        mul(raised as u128, migration_fee_bps as u128)?,
        BPS_DENOMINATOR,
    )?;
    let lp_sol = sub(raised as u128, migration_fee)?;
    let uncapped = mul(lp_sol, v_token)? / v_sol;
    let slack = add(ceil_div(v_token, v_sol)?, 1)?;
    let reserve = (token_total_supply - curve_supply) as u128;
    let lp_tokens = uncapped.saturating_sub(slack).min(reserve);
    let min_product = (MIN_POOL_LIQUIDITY + 1) * (MIN_POOL_LIQUIDITY + 1);
    if lp_sol == 0 || lp_tokens == 0 || mul(lp_sol, lp_tokens)? < min_product {
        return Err(MathError::InvalidParams);
    }
    Ok(())
}
