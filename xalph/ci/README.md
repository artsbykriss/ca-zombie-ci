# xALPH — CI job

`ci/run.sh` is the custom heavy job. It runs on **GitHub Actions** (repo
`artsbykriss/ca-zombie-ci`, dispatched by `bash /home/heisenberg/CA/ci/ci-run.sh xalph`).

It is deliberately small: this target needs **no Foundry/EVM work** (Alephium is not
EVM). The job performs the two compute/data tasks that are worth running off-machine:

1. `analysis/roundtrip_math.py --big` — a large randomized search over the exact
   mint/burn arithmetic of the deployed `XAlphToken` bytecode, proving that no
   unprivileged round-trip is profitable and that the exchange rate is monotonically
   non-decreasing.
2. `analysis/live_state.py` — re-derives the contract addresses from their contract ids
   and re-reads the live on-chain state (backing, circulating supply, reserve, reward
   collector) from the **public** Alephium node/backend.

Results are written to `ci-out/` and uploaded as workflow artifacts.

**Secrets:** none. All endpoints are public and keyless
(`node.mainnet.alephium.org`, `backend.mainnet.alephium.org`, `api.coingecko.com`).
No keyed RPC URL, API key, private key or `.env` content is ever written into this
folder (it is synced to a public repo).
