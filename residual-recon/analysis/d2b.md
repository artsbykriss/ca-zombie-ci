# Residual enumeration — d2b-staleprice

Source: `zombie-hunt-iv/wave2/d2b-staleprice.md`

Rows/leads enumerated: **23**.

## Rows and prose/negative leads

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | Shibarium stale-WBONE cluster | ~$17.2k pooled; +$877/cycle | **FINDING** | fork-verified 3x; bridge exit MED — `README:ZH4-03` |
| 2 | shibbex WBONES/WETH + dogswap WBONES/WETH (2 names) | ~$0.4k | covered (ZH4-03) | covered by ZH4-03; do not deep-dive — `d2b:12; README:ZH4-03 deep-dive in flight` |
| 3 | Aurora APE/wNEAR | $644 | PARKED | entry via Rainbow bridge unverified; one-shot small — `d2b:13` |
| 4 | Celo mCUSD/BTC | +$691 nominal | closed (in-lane) | TRAP: all Celo BTC venues drained; bridge idle — `d2b:14` |
| 5 | Aurora BUSD/wNEAR | - | closed (in-lane) | trap-leaning; BUSD exit circular — `d2b:15` |
| 6 | shibbex SHEX/WETH | $2,495 | closed (in-lane) | locked: only 58 SHEX outside pool — `d2b:16` |
| 7 | Sonic 9MM trio | phantom | closed (in-lane) | llama price 80x off; pools correctly priced — `d2b:17` |
| 8 | Conflux MemeDex | $56k DL | closed (README) | all 13 pairs hold zero; ghost reserves — `README:CLOSED#30` |
| 9 | KCC KuSwap DAI pools | phantom | closed (in-lane) | broken legacy DAI; internally consistent — `d2b:19` |
| 10 | WEMIX CLMM | $1.99M | LOW | not CLMM-swept — `README:LOW#26` |
| 11 | Fuse Voltage V4/AMM | $267k/$71k | LOW | Algebra CLMM + AMM; scan inconclusive — `README:LOW#26` |
| 12 | AZverse Perps custody wallets | $50.4M | excluded | plain EOAs/custody; not E-U — `d2b:22; README:CORR#12` |
| 13 | Shibarium dust list (10 factories) | <$5 each | closed (in-lane) | complete child scan — `d2b:45` |
| 14 | Chains unreachable (Canto, Velas, DFK, Moonbeam) (4 names) | - | excluded | no execution; Moonbeam halted 2026-08-10 — `d2b:46` |
| 15 | Fuse Voltage AMM enumeration | $267k ALG | closed (in-lane) | all token reads null on two RPCs; inconclusive — `d2b:47` |
| 16 | Perp/oracle dead-derivative shortlist (FinNexus, InsureDAO, Particle LAMM, Kinetix) (4 names) | - | excluded | no actionable frozen-mark venue — `d2b:48` |
