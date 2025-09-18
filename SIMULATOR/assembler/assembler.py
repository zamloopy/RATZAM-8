#!/usr/bin/env python3
"""
Simple assembler for the notebook CPU described by the user.

Usage:
    python assembler.py input.asm output.mem

Assembly syntax (examples):
    NOP
    HLT
    LDA &E3        ; load from memory address 0xE3
    LDA #0A        ; load immediate value 0x0A
    STA &77
    ADD ACC,TMP
    ADD ACC,MDR
    JMP label
    label:
    OUT &02
    IN &02

Operand formats:
    &xx   -> hex address/port (also accepts decimal if no 0-9A-F chars)
    #xx   -> immediate value (hex)
    plain decimal numbers are accepted too
    Labels: "loop:" then refer to "JMP loop" etc.

Output:
    A text file with one line per byte: 0xNN
"""

import sys
import re

# ----- Opcode map -----
# Map mnemonic (with operand type) to opcode byte (0-255).
# Based on the notebook image (left and right columns).
OPCODES = {
    # single-byte instructions (no operand)
    'NOP': 0x00,
    'HLT': 0x01,

    # LDA: two variants:
    'LDA_ADDR': 0x02,   # LDA &addr
    'STA_ADDR': 0x03,   # STA &addr
    'LDA_IMM': 0x04,    # LDA #value

    # Arithmetic / A-register ops (left column)
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

    # Right column opcodes (0x10..0x1F)
    'SHR_ACC': 0x10,
    'CLR_ACC': 0x11,
    'LDT_ADDR': 0x12,   # LDT &addr
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

# Which mnemonics require a following byte (address/value/port)
# We'll identify them by base mnemonic and operand rules below.
TWO_BYTE_INSTR = {
    'LDA_ADDR', 'STA_ADDR', 'LDA_IMM',
    'LDT_ADDR',
    'JMP_ADDR', 'JZ_ADDR', 'JNZ_ADDR', 'JC_ADDR',
    'OUT_PORT', 'IN_PORT'
}

# Helper parsing & number conversion
def parse_number(tok):
    """Parse a token representing a number:
       - if starts with 0x or contains A-F (hex) -> hex
       - if starts with & treat as hex address (strip &)
       - if starts with # treat as immediate (strip #)
       - otherwise treat as decimal
       Returns integer (0-255).
    """
    tok = tok.strip()
    if tok.startswith('&'):
        tok2 = tok[1:]
        base = 16
    elif tok.startswith('#'):
        tok2 = tok[1:]
        base = 16
    else:
        tok2 = tok
        # heuristic: has hex digits A-F or starts with 0x
        if tok2.lower().startswith('0x'):
            tok2 = tok2[2:]
            base = 16
        elif re.search(r'[A-Fa-f]', tok2):
            base = 16
        else:
            base = 10
    if tok2 == '':
        raise ValueError("Empty numeric token")
    return int(tok2, base) & 0xFF

def canonicalize(s):
    return s.strip().upper()

# Instruction parsing
def assemble_lines(lines):
    """
    Two-pass assembler:
      pass 1: record labels -> addresses
      pass 2: emit opcodes & operands
    """
    # Remove comments and blank lines, keep tokens
    # We accept inline comments starting with ';' or '//'
    def strip_comment(line):
        line = re.split(r';|//', line, 1)[0]
        return line.strip()

    cleaned = []
    for raw in lines:
        line = strip_comment(raw)
        if not line:
            continue
        cleaned.append(line)

    # pass 1: find labels and compute addresses
    labels = {}
    address = 0
    tokens_per_line = []  # (orig_line, tokens, is_label_line flag)
    for line in cleaned:
        # label-only line: "label:"
        if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:$', line):
            label = line.rstrip(':').strip()
            if label in labels:
                raise ValueError(f"Duplicate label: {label}")
            labels[label] = address
            tokens_per_line.append((line, [], True))
            continue

        # otherwise tokenise
        parts = re.split(r'[\s,]+', line.strip())
        mnemonic = canonicalize(parts[0])
        args = parts[1:] if len(parts) > 1 else []
        # determine instruction size
        size = 1
        # decide which opcode key we'll map to (some mnemonics share names)
        # We'll just simulate size inference:
        # If mnemonic requires operand -> size 2
        # For instructions like ADD ACC,TMP -> single byte
        # We'll detect forms below in pass 2 too
        # For now, set size=2 if line contains an operand token like & or # or a label reference
        if any(a for a in args):
            # Some mnemonics still single byte but have args (like ADD ACC,TMP) -> still 1 byte
            # We'll handle exact size in pass 2 but to compute labels we can estimate:
            # If any arg startswith '&' or '#' or looks like a hex number or is a label -> size 2
            need2 = False
            for a in args:
                if a.startswith('&') or a.startswith('#') or re.match(r'^[0-9]+$', a) or re.match(r'^0x[0-9A-Fa-f]+$', a) or re.search(r'[A-Fa-f]', a) or re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', a):
                    # could be label or numeric; some will be register names though
                    need2 = True
            if need2:
                size = 2
        tokens_per_line.append((line, [mnemonic] + args, False))
        address += size
        if address > 0xFFFF:
            raise ValueError("Program too large")

    # pass 2: generate bytes
    out_bytes = []
    address = 0
    for line, toks, is_label in tokens_per_line:
        if is_label:
            continue
        if not toks:
            continue
        mnemonic = toks[0]
        args = toks[1:]

        # Map mnemonics + arg forms to OPCODES keys:
        # We'll support many variants: e.g. "ADD ACC, TMP" or "ADD ACC,TMP"
        # Normalize args spacing and upper-case.
        # Build a key string that matches our OPCODES keys.
        upper_mn = canonicalize(mnemonic)

        # Simple no-operand instructions
        if upper_mn in ('NOP','HLT','INC','DEC','NOT','SHL','SHR','CLR','PSH','POP'):
            if upper_mn == 'INC':
                opcode = OPCODES['INC_ACC']
            elif upper_mn == 'DEC':
                opcode = OPCODES['DEC_ACC']
            elif upper_mn == 'NOT':
                opcode = OPCODES['NOT_ACC']
            elif upper_mn == 'SHL':
                opcode = OPCODES['SHL_ACC']
            elif upper_mn == 'SHR':
                opcode = OPCODES['SHR_ACC']
            elif upper_mn == 'CLR':
                opcode = OPCODES['CLR_ACC']
            elif upper_mn == 'PSH':
                opcode = OPCODES['PSH_ACC']
            elif upper_mn == 'POP':
                opcode = OPCODES['POP_ACC']
            elif upper_mn == 'NOP':
                opcode = OPCODES['NOP']
            elif upper_mn == 'HLT':
                opcode = OPCODES['HLT']
            else:
                raise ValueError(f"Unhandled no-operand mnemonic: {upper_mn} (line: {line})")
            out_bytes.append(opcode)
            address += 1
            continue

        # Two-operand ALU forms (ADD, SUB, AND, OR, XOR, CMP)
        if upper_mn in ('ADD','SUB','AND','OR','XOR','CMP'):
            # expect form: <MN> ACC,TMP  or ACC,MDR
            if len(args) == 0:
                raise ValueError(f"{upper_mn} expects operands (e.g. {upper_mn} ACC,TMP)")
            argline = ' '.join(args)
            # remove whitespace around comma
            argline = argline.replace(' ', '')
            if argline.upper() == 'ACC,TMP':
                key = {
                    'ADD':'ADD_ACC_TMP', 'SUB':'SUB_ACC_TMP',
                    'AND':'AND_ACC_TMP', 'OR':'OR_ACC_TMP', 'XOR':'XOR_ACC_TMP',
                    'CMP':'CMP_ACC_TMP'
                }[upper_mn]
                opcode = OPCODES[key]
                out_bytes.append(opcode)
                address += 1
                continue
            elif argline.upper() == 'ACC,MDR':
                key = {
                    'ADD':'ADD_ACC_MDR', 'SUB':'SUB_ACC_MDR',
                    'AND':'AND_ACC_MDR', 'OR':'OR_ACC_MDR', 'XOR':'XOR_ACC_MDR',
                    'CMP':'CMP_ACC_MDR'
                }[upper_mn]
                opcode = OPCODES[key]
                out_bytes.append(opcode)
                address += 1
                continue
            else:
                raise ValueError(f"Unknown operand form for {upper_mn}: '{argline}' (line: {line})")

        # Single-operand instructions that take an address/imm or port: LDA, STA, LDT, JMP, JZ, JNZ, JC, OUT, IN
        if upper_mn == 'LDA':
            if not args:
                raise ValueError("LDA requires an operand (#imm or &addr)")
            op = args[0].strip()
            if op.startswith('#'):
                out_bytes.append(OPCODES['LDA_IMM'])
                value = parse_number(op)
                out_bytes.append(value)
                address += 2
                continue
            else:
                # address (or label)
                if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', op):
                    if op not in labels:
                        raise ValueError(f"Undefined label: {op}")
                    addr = labels[op]
                else:
                    addr = parse_number(op if op.startswith('&') else '&' + op)
                out_bytes.append(OPCODES['LDA_ADDR'])
                out_bytes.append(addr & 0xFF)
                address += 2
                continue

        if upper_mn == 'STA':
            if not args:
                raise ValueError("STA requires an address operand (&addr or label)")
            op = args[0].strip()
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', op):
                if op not in labels:
                    raise ValueError(f"Undefined label: {op}")
                addr = labels[op]
            else:
                addr = parse_number(op if op.startswith('&') else '&' + op)
            out_bytes.append(OPCODES['STA_ADDR'])
            out_bytes.append(addr & 0xFF)
            address += 2
            continue

        if upper_mn == 'LDT':
            if not args:
                raise ValueError("LDT requires an address operand")
            op = args[0].strip()
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', op):
                if op not in labels:
                    raise ValueError(f"Undefined label: {op}")
                addr = labels[op]
            else:
                addr = parse_number(op if op.startswith('&') else '&' + op)
            out_bytes.append(OPCODES['LDT_ADDR'])
            out_bytes.append(addr & 0xFF)
            address += 2
            continue

        if upper_mn in ('JMP','JZ','JNZ','JC'):
            if not args:
                raise ValueError(f"{upper_mn} requires an address or label")
            op = args[0].strip()
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', op):
                if op not in labels:
                    raise ValueError(f"Undefined label: {op}")
                addr = labels[op]
            else:
                addr = parse_number(op if op.startswith('&') else '&' + op)
            key = {'JMP':'JMP_ADDR','JZ':'JZ_ADDR','JNZ':'JNZ_ADDR','JC':'JC_ADDR'}[upper_mn]
            out_bytes.append(OPCODES[key])
            out_bytes.append(addr & 0xFF)
            address += 2
            continue

        if upper_mn in ('OUT','IN'):
            if not args:
                raise ValueError(f"{upper_mn} requires a port number (&xx or numeric)")
            op = args[0].strip()
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', op):
                if op not in labels:
                    raise ValueError(f"Undefined label: {op}")
                port = labels[op]
            else:
                port = parse_number(op if op.startswith('&') else '&' + op)
            key = {'OUT':'OUT_PORT','IN':'IN_PORT'}[upper_mn]
            out_bytes.append(OPCODES[key])
            out_bytes.append(port & 0xFF)
            address += 2
            continue

        # Additional known mnemonics with fixed forms, e.g. CLR ACC (CLR has ACC)
        if upper_mn == 'CLR':
            # we already handled CLR above as no-operand. Accept "CLR ACC" form too.
            out_bytes.append(OPCODES['CLR_ACC'])
            address += 1
            continue

        # HLT handled earlier - fallback error
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
    in_fn = sys.argv[1]
    out_fn = sys.argv[2]
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

