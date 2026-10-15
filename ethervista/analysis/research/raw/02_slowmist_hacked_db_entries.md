# Raw: SlowMist Hacked DB — EtherVista entry
URLs: https://hacked.slowmist.io/  and  https://hacked.slowmist.io/?c=ETH  and https://hacked.slowmist.io/zh/
Fetched: 2026-10-15 (Firecrawl markdown scrape)

Entry (dated 2026-10-09 in the DB):
_Hacked target:_ EtherVista
_Description of the event:_ "EtherVista's liquidity pool was exploited due to an integer overflow in the K-invariant check inside EtherVistaPair.swap(). Both reserves are uint112, so their product can wrap around and the check can pass even when the real reserve product drops sharply. The attacker registered a self-controlled contract as an authorized router and ran two crafted swaps to drain WETH and VISTA, with a loss of about $18,600."
_Amount of loss:_ $ 18600
_Attack method:_ Smart Contract Vulnerability
Reference sources: https://x.com/SlowMist_Team/status/2108427455572918626

Chinese version (/zh/): "被黑目标：EtherVista … 攻击者将自控合约注册为授权路由器，通过两次构造的 swap 抽走池中 WETH 与 VISTA，损失约 18600 美元。损失金额：$18600 攻击手法：合约漏洞"

Adjacent entries (for hygiene — NOT EtherVista): 2026-10-08 X7 Finance ($16,514); 2026-10-07 Based Visa Card (0 loss); the $1,530,000 "Private Key Leakage" entry on 2026-09-19 is Fetch.ai, NOT EtherVista (verified in the ETH-filtered page).
