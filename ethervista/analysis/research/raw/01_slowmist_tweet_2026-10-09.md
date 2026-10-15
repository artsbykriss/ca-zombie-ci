# Raw: SlowMist tweet on EtherVista exploit
URL: https://x.com/SlowMist_Team/status/2108427455572918626
Author: @SlowMist_Team (id 988385053800517632)
Created: Fri Oct 09 05:20:52 +0000 2026 UTC
Fetched via api.fxtwitter.com/i/status/2108427455572918626 on 2026-10-15.
Metrics at fetch: 14937 views, 60 likes, 2 retweets, 25 replies, 6 quotes, 31 bookmarks.

FULL TEXT (verbatim):
"🚨SlowMist TI Alert🚨

💸 @ethervista Loss: ~18.6K

🔍 Root Cause: The EtherVistaPair.swap() function suffers from an integer overflow in its K-invariant check. Since both reserves are uint112, their multiplication overflows and wraps around, allowing the invariant check to pass even when the actual reserve product decreases significantly. The attacker exploited this flaw through an attacker-controlled contract registered as the authorized router, executing two crafted swaps to drain WETH and VISTA from the pool.

📌 Attacker: 0xbbf8f3fe8e4fdf6b594e6107144d78293d2018fa
📌 Attack Contract (Router): 0x469424b628a9d2036e41496e814db500d683b120
📌 Vulnerable Contract: 0xfdd05552f1377aa488afed744c8024358af02041

Powered by http://SlowMist.AI
Tx: https://etherscan.io/tx/0xb2c7332d9e1be6a86d9d37083aa4cc0d94b60eb95cc9b29494555a3c09764930"

Mentions: @ethervista resolved to account id 2082267914191695872 (= the new protected "Acquired by Arctide" account).
