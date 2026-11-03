# Precomputed 4-byte selectors (keccak256) used by the R25 PoC.
# Kept static so CI needs no eth_utils / pycryptodome.
SELECTORS = {
    "asset()": "0x38d52e0f",
    "totalAssets()": "0x01e1d114",
    "totalSupply()": "0x18160ddd",
    "decimals()": "0x313ce567",
    "name()": "0x06fdde03",
    "symbol()": "0x95d89b41",
    "balanceOf(address)": "0x70a08231",
    "allowance(address,address)": "0xdd62ed3e",
    "latestNav()": "0x513a9c34",
    "custodian()": "0x375b74c3",
    "whitelist()": "0x93e59dc1",
    "swaper()": "0xeed83f11",
    "share()": "0xa8d5fd65",
    "maxWithdraw(address)": "0xce96cb77",
    "maxRedeem(address)": "0xd905777e",
    "maxDeposit(address)": "0x402d267d",
    "maxMint(address)": "0xc63d75b6",
    "convertToAssets(uint256)": "0x07a2d13a",
    "convertToShares(uint256)": "0xc6e6f592",
    "paused()": "0x5c975abb",
    "whitelistEnabled()": "0x51fb012d",
    "isWhitelisted(address)": "0x3af32abf",
    "deposit(uint256,address)": "0x6e553f65",
    "requestRedeem(uint256,address,address)": "0x7d41c86e",
    "redeem(uint256,address,address)": "0xba087652",
    "withdraw(uint256,address,address)": "0xb460af94",
    "handleOracleReport((uint64,uint64,uint64,uint256,address))": "0x4bda1b55",
    "getRedeemRequestCount(address)": "0x45a8c5d1",
    "getAllBatches(address)": "0x944d5b06",
    "cancelRedeemRequest(uint256)": "0xc3f0d30e",
    "getAvailableShares(address,uint64)": "0x44b5794d",
    "pendingRedeemRequest(uint256,address)": "0xf5a23d8d",
    "claimableRedeemRequest(uint256,address)": "0xeaed1d07",
    "nextRedeemRequestId()": "0xfddca041",
    "getProxyImplementation()": "0x90e4b720",
    "getProxyAdmin()": "0x8b3240a0",
    "owner()": "0x8da5cb5b",
}

TOKEN = "0xC879C018dB60520F4355C26eD1a6D572cdAC1815"
VAULTS = {
    "vRPCQuarterlyVault": "0x94f7ebc6ae0819a4b4e231ae6ddaaf9bfd2a1a86",
    "vRPCWeeklyVault": "0x1c2bc8b553d9a7e61f7531a3a4bf2162f4569268",
    "vRPCSemiYearlyVault": "0xee26bb0989691735c997dfdc49a4a607f75e190b",
    "apcVault": "0xd0428799fbc35557834d33121ba4472692c8908a",
    "hybVault": "0x6Ce4bc043398Ac40392d1E063328048072b2075d",
}
CUSTODIANS = {
    "vRPCQ_custodian": "0xb4b6d9f817182246053a9f81e30f93e7c44a826c",
    "vRPCW_custodian": "0x292336804567651730194704877415235295160093493470",
    "vRPCS_custodian": "0x389874074521433842229592400867536959466731807704",
}
SWAPER = "0xa1f932650e66f37f650b56acc44f7a22a44ecad2"
QUEUE = "0x89362a53a10ed13d9a9da5347b9fad9f044a7b1e"
ESCROW = "0xf3503da2961ff5118adaa2c4ff8d9a6fb28a411f"
ORACLE_REPORTER = "0xa33b05f68a51c67ec24c08c42f2cbeef05df5860"
ATTACKER = "0x1111111111111111111111111111111111111111"
