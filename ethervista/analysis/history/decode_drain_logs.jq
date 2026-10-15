def pad0: "0x0000000000000000000000000000000000000000";
def topic_addr: .[26:66];
def hex2dec:
  if . == null then "0"
  elif (test("^0x[0-9a-fA-F]*$")) then
    (.[2:] | if . == "" then "0" else explode | map(
      if . >= 48 and . <= 57 then (. - 48)
      elif . >= 97 then (. - 87)
      else (. - 55) end) | reduce .[] as $d (0; . * 16 + $d) | tostring end)
  else . end;
.result.logs
| to_entries[]
| . as $e
| ($e.value.address | ascii_downcase) as $addr
| ($e.value.topics[0] | ascii_downcase) as $t0
| if $t0 == "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" then
    [ $e.key, "LOG-Transfer", $addr[0:14],
      ("from=" + ($e.value.topics[1] | topic_addr | "0x" + .)),
      ("to=" + ($e.value.topics[2] | topic_addr | "0x" + .)),
      ("value=" + ($e.value.data | hex2dec)) ]
  else
    [ $e.key, "LOG", $addr[0:14], ("topic0=" + $t0[0:12]),
      ("topic1=" + (($e.value.topics[1] // "-"))),
      ("data=" + ($e.value.data[0:66])) ]
  end
| @tsv
