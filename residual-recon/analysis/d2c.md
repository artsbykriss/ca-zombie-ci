# Residual enumeration — d2c-dormantdao

Source: `zombie-hunt-iv/wave2/d2c-dormantdao.md`

Rows/leads enumerated: **44**.

## Rows and prose/negative leads

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | HAI (Let's Get HAI) | $122k treasury + ~$927k protocol | **FINDING** | live governance capture; hardening unexecuted at check — `README:ZH4-01` |
| 2 | Ampleforth (FORTH) | $3.19M | closed (README) | timelock admin moved to 2-of-4 Safe; queue from governor reverts — `README:CLOSED#29` |
| 3 | Idle Finance | $310k+ | closed (README) | timelock admin moved to 3-of-6 Safe; queue reverts — `README:CLOSED#29` |
| 4 | Goldfinch | $802k | closed (README) | no Governor; token lacks votes interface; 6/12 Safe — `README:CLOSED#29` |
| 5 | BadgerDAO | $1.75M | closed (README) | no Governor; 5/8 Treasury Safe; active 2026 — `README:CLOSED#29` |
| 6 | mStable | ~$53k + 2.3M PT units | closed (README) | no Governor; human Safes; dormant — `README:CLOSED#29` |
| 7 | TrueFi | $0.01 timelock | closed (README) | TFIP-42 moved roles to 4-of-6 Safe; governor PROPOSER-only — `README:CLOSED#29` |
| 8 | Cream Finance | $0.78M v1 cash | closed (README) | no Governor; 2-of-4 Safe key-gated P-class — `README:CLOSED#29` |
| 9 | StrongBlock | already drained | closed (README) | attacker holds Governor — `README:CLOSED#29` |
| 10 | Fei/Tribe | husks | closed (README) | timelock disabled 2023 — `README:CLOSED#29` |
| 11 | Dopex/Stryke | - | closed (README) | rebrand, not capture — `README:CLOSED#29 (Dopex context)` |
| 12 | Aragon-legacy DAOs | unknown | closed (README) | enumerated gap only; subgraphs dead — `README:CLOSED#31; README:LOW#28` |
| 13 | Swerve | $304.9k LP | excluded | corpus; executor Agent empty; 4pool renounced — `d2c:41` |
| 14 | Ooki DAO | <$15 | excluded | corpus; no token-vote path — `d2c:42` |
| 15 | Panther | $14-18k realized | excluded | exploited Aug 6; protections restored — `d2c:46` |
| 16 | Unicly / TOP / BonkDAO / BarnBridge / Term / Neutron / Yam / Moonwell (8 names) | - | excluded | already exploited/covered — `d2c:47` |
| 17 | Balancer | - | closed (in-lane) | actively governed wind-down; wrong side of dormant condition — `d2c:48` |
| 18 | Seamless (Base) | $6.6M wind-down | excluded | corpus-covered; active distribution — `d2c:49` |
| 19 | Sceptre / Nucleus / UTONIC (3 names) | - | excluded | corpus-covered — `d2c:50` |
| 20 | InceptionLRT | - | PARKED | unchecked; no Governor/DEX indicators surfaced — `d2c:50` |
| 21 | Reserve hyUSD / Olas (2 names) | - | closed (in-lane) | attacks stopped; Olas thresholds raised — `d2c:51` |
| 22 | Dopex / Vesta / 88mph / Element / Fuji / Gro (6 names) | - | closed (in-lane) | no Compound-style dormant Governor with funds — `d2c:52` |
| 23 | Index Coop / PowerPool / BasketDAO / Domani / Cook / Indexed Finance (6 names) | - | excluded | corpus hits — `d2c:53` |
| 24 | Fantom/Moonbeam/Aurora ghost farms | - | closed (in-lane) | team multisigs/farm accounting; P-class — `d2c:54` |
