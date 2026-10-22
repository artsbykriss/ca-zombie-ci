#!/bin/bash
for s in $(cat /tmp/opencode/ac_sels.txt); do
  n=$(cast 4byte 0x$s 2>/dev/null | head -1)
  echo "$s $n"
done
