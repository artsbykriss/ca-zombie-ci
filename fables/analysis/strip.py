import re, sys
def strip(src):
    # remove block comments and line comments (naive but adequate for these files), collapse ws
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    out = []
    for line in src.split('\n'):
        # remove // comments not inside strings (adequate here)
        line = re.sub(r'//.*$', '', line)
        line = line.strip()
        if line: out.append(line)
    return '\n'.join(out)
if __name__ == "__main__":
    print(strip(open(sys.argv[1]).read()))
