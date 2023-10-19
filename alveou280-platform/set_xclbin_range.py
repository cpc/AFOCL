#!/usr/bin/env python3

import sys

input_file = sys.argv[1]

with open(input_file, 'r') as f:
    lines = f.readlines()

for i,line in enumerate(lines):
    if "name=\"s_axi_control\"" in line:
        line = line.strip()
        o = line.split(' ')
        o[3] = "range=\"0x10000\""
        line = ' '.join(o) + '\n'
        lines[i] = line

with open(input_file, 'w') as f:
    f.writelines(lines)
