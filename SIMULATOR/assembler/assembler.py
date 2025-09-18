#!/usr/bin/env python3
"""
Simple assembler for the notebook CPU described by the user.

Usage:
    python assembler.py input.asm output.mem
"""

import sys
import re

# ----- Opcode map -----
OPCODES = {
    'NOP': 0x00,
    'HLT': 0x01,

    'LDA_ADDR': 0x02,
    'STA_ADDR': 0x03,
    'LDA_IMM': 0x04,

    'ADD_ACC_TMP': 0x05,
    'ADD_ACC_MDR': 0x06,
    'SUB_ACC_TMP': 0x07,
    'SUB_ACC_MDR': 0x08,
    'INC_ACC': 0x09,
    'DEC_ACC': 0x0A,
    'AND_ACC_TMP': 0x0B,
    'OR_ACC_TMP': 0x0C,
    'XOR_ACC_TMP': 0x0D,
    'NOT_ACC': 0x0E,
    'SHL_ACC': 0x0F,

    'SHR_ACC': 0x10,
    'CLR_ACC': 0x11,
    'LDT_ADDR': 0x12,
    'JMP_ADDR': 0x13,
    'JZ_ADDR': 0x14,
    'JNZ_ADDR': 0x15,
    'JC_ADDR': 0x16,

    'AND_ACC_MDR': 0x17,
    'OR_ACC_MDR': 0x18,
    'XOR_ACC_MDR': 0x19,

    'CMP_ACC_TMP': 0x1A,
    'CMP_ACC_MDR': 0x1B,

    'PSH_ACC': 0x1C,
    'POP_ACC': 0x1D,

    'OUT_PORT': 0x1E,
    'IN_PORT': 0x1F,
}

# helper functions
def parse_number(tok):
    tok = tok.strip()
    if tok.startswith('&'):
        tok2, base = tok[1:], 16
    elif tok.startswith('#'):
        tok2, base = tok[1:], 16
    else:
        tok2 = tok
        if tok2.lower().startswith('0x'):
            tok2, base = tok2[2:], 16
        elif re.search(r'[A-Fa-f]', tok2):
            base = 16
        else:
            base = 10
    if tok2 == '':
        raise ValueError("Empty numeric token")
    return int(tok2, base) & 0xFF

def canonicalize(s):
    return s.strip().upper()

# ----- Assembler -----
def assemble_lines(lines):
    def strip_comment(line):
        return re.split(r';|//', line, 1)[0].strip()

    cleaned = [strip_comment(raw) for raw in lines if strip_comment(raw)]

    labels = {}
    address = 0
    tokens_per_line = []

    # pass 1: gather labels
    for line in cleaned:
        if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:$', line):
            label = line.rstrip(':').strip()
            if label in labels:
                raise ValueError(f"Duplicate label: {label}")
            labels[label] = address
            tokens_per_line.append((line, [], True))
            continue

        # --- FIX HERE: only split on whitespace, not commas ---
        parts = re.split(r'\s+', line.strip())
        mnemonic = canonicalize(parts[0])
        args = [a.strip() for a in parts[1:]]
        size = 1
        if args:
            for a in args:
                if (a.startswith('&') or a.startswith('#') or
                    re.match(r'^[0-9]+$', a) or
                    re.match(r'^0x[0-9A-Fa-f]+$', a) or
                    re.search(r'[A-Fa-f]', a) or
                    re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', a)):
                    size = 2
        tokens_per_line.append((line, [mnemonic] + args, False))
        address += size
        if address > 0xFFFF:
            raise ValueError("Program too large")

    # pass 2: encode
    out_bytes = []
    address = 0
    for line, toks, is_label in tokens_per_line:
        if is_label or not toks:
            continue
        mnemonic, args = toks[0], toks[1:]
        upper_mn = canonicalize(mnemonic)

        # no-operand instructions
        if upper_mn in ('NOP','HLT','INC','DEC','NOT','SHL','SHR','CLR','PSH','POP'):
            opcode = {
                'INC':OPCODES['INC_ACC'], 'DEC':OPCODES['DEC_ACC'],
                'NOT':OPCODES['NOT_ACC'], 'SHL':OPCODES['SHL_ACC'],
                'SHR':OPCODES['SHR_ACC'], 'CLR':OPCODES['CLR_ACC'],
                'PSH':OPCODES['PSH_ACC'], 'POP':OPCODES['POP_ACC'],
                'NOP':OPCODES['NOP'], 'HLT':OPCODES['HLT'],
            }[upper_mn]
            out_bytes.append(opcode); address += 1; continue

        # two-operand ALU
        if upper_mn in ('ADD','SUB','AND','OR','XOR','CMP'):
            if not args:
                raise ValueError(f"{upper_mn} expects operands (e.g. {upper_mn} ACC,TMP)")
            argline = ' '.join(args).replace(' ', '')
            if argline.upper() == 'ACC,TMP':
                key = {
                    'ADD':'ADD_ACC_TMP','SUB':'SUB_ACC_TMP',
                    'AND':'AND_ACC_TMP','OR':'OR_ACC_TMP','XOR':'XOR_ACC_TMP',
                    'CMP':'CMP_ACC_TMP'
                }[upper_mn]
            elif argline.upper() == 'ACC,MDR':
                key = {
                    'ADD':'ADD_ACC_MDR','SUB':'SUB_ACC_MDR',
                    'AND':'AND_ACC_MDR','OR':'OR_ACC_MDR','XOR':'XOR_ACC_MDR',
                    'CMP':'CMP_ACC_MDR'
                }[upper_mn]
            else:
                raise ValueError(f"Unknown operand form for {upper_mn}: '{argline}' (line: {line})")
            out_bytes.append(OPCODES[key]); address += 1; continue

        # single-operand with address/imm/port
        def resolve_val(op):
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', op):
                if op not in labels: raise ValueError(f"Undefined label: {op}")
                return labels[op]
            return parse_number(op if op.startswith('&') else '&' + op)

        if upper_mn == 'LDA':
            op = args[0]
            if op.startswith('#'):
                out_bytes += [OPCODES['LDA_IMM'], parse_number(op)]
            else:
                out_bytes += [OPCODES['LDA_ADDR'], resolve_val(op) & 0xFF]
            address += 2; continue

        if upper_mn == 'STA':
            op = args[0]
            out_bytes += [OPCODES['STA_ADDR'], resolve_val(op) & 0xFF]
            address += 2; continue

        if upper_mn == 'LDT':
            op = args[0]
            out_bytes += [OPCODES['LDT_ADDR'], resolve_val(op) & 0xFF]
            address += 2; continue

        if upper_mn in ('JMP','JZ','JNZ','JC'):
            op = args[0]
            key = {'JMP':'JMP_ADDR','JZ':'JZ_ADDR','JNZ':'JNZ_ADDR','JC':'JC_ADDR'}[upper_mn]
            out_bytes += [OPCODES[key], resolve_val(op) & 0xFF]
            address += 2; continue

        if upper_mn in ('OUT','IN'):
            op = args[0]
            key = {'OUT':'OUT_PORT','IN':'IN_PORT'}[upper_mn]
            out_bytes += [OPCODES[key], resolve_val(op) & 0xFF]
            address += 2; continue

        raise ValueError(f"Unknown or unhandled instruction: {mnemonic} (line: {line})")

    return out_bytes

def write_mem_file(out_bytes, filename):
    with open(filename, 'w') as f:
        for b in out_bytes:
            f.write(f"0x{b:02X}\n")

def main():
    if len(sys.argv) < 3:
        print("Usage: python assembler.py input.asm output.mem")
        sys.exit(1)
    in_fn, out_fn = sys.argv[1], sys.argv[2]
    with open(in_fn, 'r') as fh:
        lines = fh.readlines()
    try:
        out_bytes = assemble_lines(lines)
    except Exception as e:
        print("Assembly error:", e)
        sys.exit(2)
    write_mem_file(out_bytes, out_fn)
    print(f"Wrote {len(out_bytes)} bytes to {out_fn}")

if __name__ == '__main__':
    main()

