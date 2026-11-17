#!/usr/bin/env python3
"""Read-only IOKit call-site scanner for extracted dyld cache images.

Uses otool -tV. It records the last immediate writes to the SysV argument
registers in a sliding window before each IOKit call. No files are modified.
"""
import os
import re
import subprocess
import sys
from collections import deque

CALL_RE = re.compile(r'^(?P<addr>[0-9a-fA-F]+)\s+callq?\s+(?P<target>0x[0-9a-fA-F]+|\*)')
IMM_RE = re.compile(r'\bmov(?:l|q|w|b)?\s+\$(?P<val>0x[0-9a-fA-F]+|[0-9]+),\s+%(?P<reg>e?[abcd]x|e?[sd]i|e?[sb]p|r(?:8|9|10|11|12|13|14|15)d?)\b')
SYM_RE = re.compile(r'##\s*symbol stub for:\s*(\S+)')
ADDR_RE = re.compile(r'^([0-9a-fA-F]+)\s+')

WANTED = {'_IOConnectCallMethod', '_IOConnectCallStructMethod', '_IOConnectCallScalarMethod',
          '_IOConnectCallAsyncMethod', '_IOConnectCallAsyncStructMethod',
          '_IOConnectCallAsyncScalarMethod'}


def norm_reg(r):
    return r.lstrip('%').lower()


def parse_imm(v):
    try:
        return int(v, 16) if v.lower().startswith('0x') else int(v, 10)
    except ValueError:
        return None


def scan(path):
    p = subprocess.Popen(['/usr/bin/otool', '-tV', path],
                         stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                         text=True, errors='replace')
    window = deque(maxlen=45)
    calls = []
    for line in p.stdout:
        m = CALL_RE.match(line)
        if m:
            sym = SYM_RE.search(line)
            if sym and sym.group(1) in WANTED:
                # last immediate writes in the window
                imms = {}
                for old in window:
                    for im in IMM_RE.finditer(old):
                        imms[norm_reg(im.group('reg'))] = parse_imm(im.group('val'))
                calls.append({
                    'addr': m.group('addr'),
                    'target': m.group('target'),
                    'symbol': sym.group(1),
                    'esi': imms.get('esi'),
                    'ecx': imms.get('ecx'),
                    'r9d': imms.get('r9d') if 'r9d' in imms else imms.get('r9'),
                    'r8d': imms.get('r8d') if 'r8d' in imms else imms.get('r8'),
                })
        window.append(line.rstrip('\n'))
    p.wait()
    return calls


def main():
    paths = sys.argv[1:]
    out = sys.stdout
    out.write('file\tcall_addr\tsymbol\tesi\t ecx\tr9d\tr8d\n')
    for path in paths:
        calls = scan(path)
        base = os.path.basename(path)
        if not calls:
            continue
        for c in calls:
            out.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (
                base, c['addr'], c['symbol'], c['esi'], c['ecx'], c['r9d'], c['r8d']))


if __name__ == '__main__':
    main()
