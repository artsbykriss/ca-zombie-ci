# CI runs — C2-36 Phase Delegation

Repo: `artsbykriss/ca-zombie-ci` (public) · workflow `poc.yml` · job: `bash ci/run.sh`
(runs `analysis/verify_all.py`: 30 on-chain checks, public keyless RPCs only, read-only)

| # | Run | Result | Notes |
|---|---|---|---|
| 1 | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38753018068 | **success** | 29/29 PASS (pre-buffer-check build); slot 457,273,511; artifact `result-phase-delegation` |
| 2 | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38756446889 | **success** | **30/30 PASS**: adds pending-upgrade buffer hash check; slot 457,279,799, epoch 1058; SOL $104.73 → pool $115,324,925; program ELF sha256 `ec2dfef…` == official program@v2.1.0; buffer sha256 `40ff0779…` == official program@v2.2.0 (authority = Squads vault); 111/111 sweep, 0 orphans |
| 3 | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38756850481 | **success** | 30/30 PASS; SOL $104.64 → pool $115,225,152; syncs final README/summary revision |
| 4 | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38757319949 | **success** | **30/30 PASS** — final sync (includes child-A `analysis/child-a/REPORT.md`); SOL $105.36 → pool $116,018,085 |

Artifacts:
- run 2: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38756446889/artifacts/11982544884
- run 1: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/38753018068/artifacts/11980959994
- run 3: see run page (artifact `result-phase-delegation`)
