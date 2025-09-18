#!/usr/bin/env python3
"""
Enhanced assembler for the RATZAM-8 CPU.

Usage:
    python assembler.py input.asm output.mem
"""

import sys, re

# ----- OPCODES -----
OPCODES = {
    # --- NOP / HALT ---
    'NOP': 0x00, 'HLT': 0x01,

    # --- Load / Store ---
    'LDA_ADDR': 0x02, 'STA_ADDR': 0x03, 'LDA_IMM': 0x04,
    'LDT_ADDR': 0x05, 'LD_TMP': 0x06,  # optional temp loads
    'INC_MEM': 0x07, 'DEC_MEM': 0x08,  # direct memory inc/dec

    # --- ALU: register-register ---
    'ADD_ACC_TMP': 0x09, 'ADD_ACC_MDR': 0x0A,
    'SUB_ACC_TMP': 0x0B, 'SUB_ACC_MDR': 0x0C,
    'AND_ACC_TMP': 0x0D, 'AND_ACC_MDR': 0x0E,
    'OR_ACC_TMP': 0x0F, 'OR_ACC_MDR': 0x10,
    'XOR_ACC_TMP': 0x11, 'XOR_ACC_MDR': 0x12,
    'CMP_ACC_TMP': 0x13, 'CMP_ACC_MDR': 0x14,

    # --- ALU: immediate variants ---
    'ADD_ACC_IMM': 0x15, 'SUB_ACC_IMM': 0x16, 'CMP_ACC_IMM': 0x17,
    'AND_ACC_IMM': 0x18, 'OR_ACC_IMM': 0x19, 'XOR_ACC_IMM': 0x1A,

    # --- ALU: single operand / bit ops ---
    'INC_ACC': 0x1B, 'DEC_ACC': 0x1C,
    'NOT_ACC': 0x1D, 'SHL_ACC': 0x1E, 'SHR_ACC': 0x1F, 'CLR_ACC': 0x20,

    # --- Jump / conditional ---
    'JMP_ADDR': 0x21, 'JZ_ADDR': 0x22, 'JNZ_ADDR': 0x23, 'JC_ADDR': 0x24, 'JLT_ADDR': 0x25,

    # --- Stack ---
    'PSH_ACC': 0x26, 'POP_ACC': 0x27,

    # --- I/O ---
    'OUT_PORT': 0x28, 'IN_PORT': 0x29,
}

# ----- HELPERS -----
def parse_number(tok):
    tok = tok.strip()
    if tok.startswith('&') or tok.startswith('#'):
        return int(tok[1:], 16) & 0xFF
    if tok.lower().startswith('0x'):
        return int(tok[2:], 16) & 0xFF
    if re.search(r'[A-Fa-f]', tok):
        return int(tok, 16) & 0xFF
    return int(tok) & 0xFF

def canonicalize(s):
    return s.strip().upper()

# ----- ASSEMBLER -----
def assemble_lines(lines):
    def strip_comment(line):
        return re.split(r';|//', line, 1)[0].strip()

    cleaned = [strip_comment(line) for line in lines if strip_comment(line)]
    labels = {}
    address = 0
    tokens_per_line = []

    # Pass 1: gather labels
    for line in cleaned:
        if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:$', line):
            label = line.rstrip(':')
            if label in labels:
                raise ValueError(f"Duplicate label: {label}")
            labels[label] = address
            tokens_per_line.append((line, [], True))
            continue
        parts = re.split(r'\s+', line.strip())
        mnemonic = canonicalize(parts[0])
        args = parts[1:]
        size = 2 if args else 1
        tokens_per_line.append((line, [mnemonic]+args, False))
        address += size
        if address > 0xFFFF:
            raise ValueError("Program too large")

    # Pass 2: encode
    out_bytes = []
    for line, toks, is_label in tokens_per_line:
        if is_label or not toks:
            continue
        mnemonic, args = toks[0], toks[1:]
        upper_mn = canonicalize(mnemonic)

        # Single-byte instructions
        if upper_mn in ('NOP','HLT','INC','DEC','NOT','SHL','SHR','CLR','PSH','POP'):
            opcode = {
                'INC':'INC_ACC','DEC':'DEC_ACC','NOT':'NOT_ACC','SHL':'SHL_ACC','SHR':'SHR_ACC',
                'CLR':'CLR_ACC','PSH':'PSH_ACC','POP':'POP_ACC','NOP':'NOP','HLT':'HLT'
            }[upper_mn]
            out_bytes.append(OPCODES[opcode])
            continue

        # ALU: reg/reg or reg/imm
        if upper_mn in ('ADD','SUB','AND','OR','XOR','CMP'):
            if not args:
                raise ValueError(f"{upper_mn} expects operands")
            argline = ''.join(args).replace(' ','')
            # immediate
            if argline.startswith('ACC,#') or argline.startswith('#'):
                val = parse_number(argline.split('#')[-1])
                key = {
                    'ADD':'ADD_ACC_IMM','SUB':'SUB_ACC_IMM','CMP':'CMP_ACC_IMM',
                    'AND':'AND_ACC_IMM','OR':'OR_ACC_IMM','XOR':'XOR_ACC_IMM'
                }[upper_mn]
                out_bytes += [OPCODES[key], val]
                continue
            # register variants
            if argline.upper() == 'ACC,TMP':
                key = {
                    'ADD':'ADD_ACC_TMP','SUB':'SUB_ACC_TMP','CMP':'CMP_ACC_TMP',
                    'AND':'AND_ACC_TMP','OR':'OR_ACC_TMP','XOR':'XOR_ACC_TMP'
                }[upper_mn]
                out_bytes.append(OPCODES[key])
                continue
            elif argline.upper() == 'ACC,MDR':
                key = {
                    'ADD':'ADD_ACC_MDR','SUB':'SUB_ACC_MDR','CMP':'CMP_ACC_MDR',
                    'AND':'AND_ACC_MDR','OR':'OR_ACC_MDR','XOR':'XOR_ACC_MDR'
                }[upper_mn]
                out_bytes.append(OPCODES[key])
                continue
            raise ValueError(f"Unknown operand form: {argline}")

        # single operand
        def resolve_val(op):
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', op):
                if op not in labels:
                    raise ValueError(f"Undefined label: {op}")
                return labels[op]
            return parse_number(op if op.startswith('&') else '&'+op)

        if upper_mn == 'LDA':
            op = args[0]
            if op.startswith('#'):
                out_bytes += [OPCODES['LDA_IMM'], parse_number(op)]
            else:
                out_bytes += [OPCODES['LDA_ADDR'], resolve_val(op)]
            continue

        if upper_mn == 'STA':
            out_bytes += [OPCODES['STA_ADDR'], resolve_val(args[0])]
            continue

        if upper_mn == 'LDT':
            out_bytes += [OPCODES['LDT_ADDR'], resolve_val(args[0])]
            continue

        if upper_mn in ('JMP','JZ','JNZ','JC','JLT'):
            key = {'JMP':'JMP_ADDR','JZ':'JZ_ADDR','JNZ':'JNZ_ADDR','JC':'JC_ADDR','JLT':'JLT_ADDR'}[upper_mn]
            out_bytes += [OPCODES[key], resolve_val(args[0])]
            continue

        if upper_mn in ('OUT','IN'):
            key = {'OUT':'OUT_PORT','IN':'IN_PORT'}[upper_mn]
            out_bytes += [OPCODES[key], resolve_val(args[0])]
            continue

        raise ValueError(f"Unknown instruction: {mnemonic}")

    return out_bytes

def write_mem_file(out_bytes, filename):
    with open(filename,'w') as f:
        for b in out_bytes:
            f.write(f"0x{b:02X}\n")

def main():
    if len(sys.argv)<3:
        print("Usage: python assembler.py input.asm output.mem")
        sys.exit(1)
    in_fn, out_fn = sys.argv[1], sys.argv[2]
    with open(in_fn,'r') as fh:
        lines = fh.readlines()
    try:
        out_bytes = assemble_lines(lines)
    except Exception as e:
        print("Assembly error:", e)
        sys.exit(2)
    write_mem_file(out_bytes, out_fn)
    print(f"Wrote {len(out_bytes)} bytes to {out_fn}")

if __name__=='__main__':
    main()

