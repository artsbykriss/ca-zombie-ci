#!/usr/bin/env python3
"""Extract scrollscan v2 smart-contract JSON into a source tree.
Usage: extract_sources.py <sc_json> <out_dir>
"""
import json, os, sys, re

def main():
    sc_path, out_dir = sys.argv[1], sys.argv[2]
    d = json.load(open(sc_path))
    os.makedirs(out_dir, exist_ok=True)
    # main file
    fp = d.get('file_path') or 'main.sol'
    # file_path sometimes like 'contracts/Pair.sol' with content in source_code
    def write_file(rel, content):
        rel = rel.lstrip('/')
        p = os.path.join(out_dir, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w') as f:
            f.write(content or '')
    if d.get('source_code'):
        write_file(fp, d['source_code'])
    for a in d.get('additional_sources') or []:
        # shape: {file_path, source_code} or {path, content}
        rel = a.get('file_path') or a.get('path') or a.get('filename')
        content = a.get('source_code') or a.get('content')
        if rel:
            write_file(rel, content)
    with open(os.path.join(out_dir, '_meta.json'), 'w') as f:
        json.dump({k: d.get(k) for k in ('name','is_verified','compiler_version','optimization_enabled','optimization_runs','verified_twin_address_hash','implementations','decoded_constructor_args')}, f, indent=1)
    print('extracted to', out_dir, 'files:')
    for root, _, files in os.walk(out_dir):
        for fn in files:
            print('  ', os.path.join(root, fn).replace(out_dir + '/', ''))

if __name__ == '__main__':
    main()
