use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Api, QuerierWrapper, StdError, StdResult};
use rujira_rs::{
    exchange::SwapItem,
    fin::{Commit, Denoms, Side, Tick},
    MergeNByIter,
};
use schemars::Set;
use std::collections::BTreeSet;

use crate::market_maker::{MarketMakerIter, MarketMakerOffer};

#[cw_serde]
pub struct MarketMakers {
    pub contracts: Set<Addr>,
    #[serde(default)]
    pub commits: Vec<Commit>,
}

impl MarketMakers {
    pub fn new(api: &dyn Api, market_makers: Vec<String>, commits: Vec<Commit>) -> StdResult<Self> {
        let mut value = Self {
            contracts: Default::default(),
            commits: vec![],
        };
        value.set_contracts(api, market_makers)?;
        value.set_commits(api, commits)?;
        Ok(value)
    }

    pub fn set_contracts(&mut self, api: &dyn Api, market_makers: Vec<String>) -> StdResult<()> {
        self.contracts = market_makers
            .into_iter()
            .map(|addr| api.addr_validate(&addr))
            .collect::<StdResult<Set<Addr>>>()?;
        Ok(())
    }

    pub fn set_commits(&mut self, api: &dyn Api, commits: Vec<Commit>) -> StdResult<()> {
        let commits: Vec<Commit> = commits
            .into_iter()
            .map(|commit| {
                Ok(Commit {
                    addr: api.addr_validate(commit.addr.as_str())?,
                    msg: commit.msg,
                })
            })
            .collect::<StdResult<_>>()?;

        let unique: BTreeSet<&Addr> = commits.iter().map(|commit| &commit.addr).collect();
        if unique.len() != commits.len() {
            return Err(StdError::generic_err("duplicate commit address"));
        }

        self.commits = commits;
        Ok(())
    }

    pub fn validate(&self) -> StdResult<()> {
        if let Some(addr) = self
            .commits
            .iter()
            .map(|commit| &commit.addr)
            .find(|addr| !self.contracts.contains(*addr))
        {
            return Err(StdError::generic_err(format!(
                "commit address {addr} is not a configured market maker"
            )));
        }
        Ok(())
    }

    pub fn iter<'a>(
        &'a self,
        querier: QuerierWrapper<'a>,
        denoms: &'a Denoms,
        tick: &'a Tick,
        side: &'a Side,
    ) -> impl Iterator<Item = Vec<MarketMakerOffer>> + 'a {
        MergeNByIter::new(
            self.contracts.iter().map(|addr| {
                MarketMakerIter::new(
                    querier,
                    denoms.clone(),
                    side.clone(),
                    addr.clone(),
                    tick.clone(),
                )
            }),
            move |a, b| match side.clone() {
                Side::Base => a.rate().cmp(&b.rate()),
                Side::Quote => b.rate().cmp(&a.rate()),
            },
        )
    }
}
