{{
  "language": "Vyper",
  "sources": {
    "contracts/CryptopoolLPOracle.vy": {
      "content": "# @version 0.4.3\n\n\"\"\"\n@title CryptopoolLPOracle\n@notice LP oracle for Curve cryptopools\n@author Scientia Spectra AG\n@license Copyright (c) 2025\n\"\"\"\n\ninterface Cryptopool:\n    def lp_price() -> uint256: view\n    def virtual_price() -> uint256: view\n    def price_scale() -> uint256: view\n\ninterface PriceOracle:\n    def price() -> uint256: view\n    def price_w() -> uint256: nonpayable\n\n\nPOOL: public(immutable(Cryptopool))\nAGG: public(immutable(PriceOracle))\n\n\n@deploy\ndef __init__(pool: Cryptopool, agg: PriceOracle):\n    \"\"\"\n    @param pool Cryptopool crvUSD/crypto\n    @param agg Price aggregator returning price of crvUSD in aggregated USD\n    \"\"\"\n    POOL = pool\n    AGG = agg\n\n\n@internal\n@view\ndef lp_price() -> uint256:\n    virtual_price: uint256 = staticcall POOL.virtual_price()\n    p_scale: uint256 = staticcall POOL.price_scale()\n    return 2 * virtual_price * isqrt(p_scale * 10**18) // 10**18\n\n\n@external\n@view\ndef price() -> uint256:\n    return self.lp_price() * staticcall AGG.price() // 10**18\n\n\n@external\ndef price_w() -> uint256:\n    return self.lp_price() * extcall AGG.price_w() // 10**18\n",
      "sha256sum": "f2489920a9c4733095287a5de899e2535103da10254e9b38568da9abb9fb6cd7"
    }
  },
  "settings": {
    "outputSelection": {
      "contracts/CryptopoolLPOracle.vy": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    },
    "search_paths": [
      "."
    ]
  },
  "compiler_version": "v0.4.3+commit.bff19ea2",
  "integrity": "8bdf57f7f35d1080e69abe42d66a369bcf94b3287f87ce7e963692f7e9001f59"
}}