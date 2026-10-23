#!/usr/bin/env bash
# filtered prior-coverage check: only verdict-bearing sources (exclude llama data dumps)
cd /home/heisenberg/CA
ROOTS="ci zombie_hunt zombie-deep zombie-hunt-iv/pass2 zombie-hunt-iv/pass3 zombie-hunt-iv/pass5 zombie-hunt-iv/wave1 zombie-hunt-iv/wave2"
while IFS= read -r n; do
  [ -z "$n" ] && continue
  hits=$(grep -rilF -- "$n" $ROOTS 2>/dev/null \
    | grep -vE 'work/llama_|work/lane_|work/gov/|work/MASTER-BOARD|work/hacks_recent|work/WAVE2-PLAN' \
    | sort -u | tr '\n' ' ')
  f=$(find . -maxdepth 1 -type d -iname "*$(echo "$n" | tr ' ' '_')*" 2>/dev/null | grep -vE '^\.$|zombie-hunt-iv|\.git' | tr '\n' ' ')
  printf '%s\t%s\t%s\n' "$n" "$hits" "$f"
done < pass4-recon/analysis/names.txt
