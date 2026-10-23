#!/usr/bin/env python3
A="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n=0
    for c in s: n=n*58+A.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    return b'\x00'*(len(s)-len(s.lstrip('1')))+b
for s in ["YS","46QTA5xDo9Xr5xy1ntsiYAChQPL3CnssaZg3nHCNpN8JUqSo","aHVU6ogcZvaFHDfHNExUhHLbXyrbHo6hH5V8sSVZaWzcyrrSVZYRF5By2Wfi8e4TEgsrKEDvhB6rJMF2","46Rm7jcZXuGASRyAmemoNJg9iAiaY4i5YAk291uE1emS4BHq","46T5KEnoLSpceZh6wktgD15843nYUz5uDt1A9gN6um3qCAHd","aHVU6ogcZvaFHDhH1muxayPsPyNHkFXB4DXivP3R9GqaXc7Z2YqLK1oRHoW1k1KGdEiCr6666xpvu6hY","aHVU6ogcZvaFHDjGY17HfhPeynQZcxvGp49x6KayY2E6ZnzBkVFrnNiQzw8nyeaoeNZhXt1U9ow6qvij"]:
    b=b58d(s)
    print(f"{s[:12]:12} len={len(b)} hex={b.hex()}")
