# RATZAM-8 Assembler

`assembler.py` is a Python script that assembles human-readable `.asm` source code into machine code (`.mem`) for the **RATZAM-8** CPU and simulation.  
It supports labels, comments, immediate values, direct addressing, and I/O operations.

---

## Assembly Language Syntax

### 1. Comments
- Begin with `;` and run to the end of the line.  
- Ignored by the assembler.

Example:
LDA #05    ; Load 5 into accumulator

### 2. Labels
- A word followed by `:` defines a label at the current program counter (PC).  
- Labels are symbolic addresses, useful for jumps and loops.

Example:
loop:  DEC
       JNZ loop   ; jump back to "loop"

### 3. Opcodes
Each instruction maps to a machine code defined in the ISA (Instruction Set Architecture). Examples:

LDA #05    ; Load immediate
STA &20    ; Store ACC into memory at 0x20
OUT &01    ; Output ACC to port 1
IN  &02    ; Read from port 2 into ACC
HLT        ; Halt execution

### 4. Operands
- Immediate (`#`): literal constant.
Example:
LDA #10     ; ACC = 10

- Direct (`&`): memory or I/O address.
Example:
STA &30     ; RAM[0x30] = ACC

- Label: symbolic address, resolved at assembly time.
Example:
JNZ loop

---

## Usage

### Assemble a program
python3 assembler.py program.asm program.mem

- `program.asm` = input assembly source file  
- `program.mem` = output memory image (one byte per line in hex, e.g., `0xNN`)  

### Run with GHDL Simulation
The `.mem` file can be loaded directly into the RATZAM-8 simulation:

ghdl -r tb_cpu8 --wave=out.ghw --mem=program.mem

*(Adjust depending on your testbench options.)*

---

## Example

### `countdown.asm`
; Countdown demo
LDA #05
loop: OUT &01
      DEC
      JNZ loop
      HLT

### Assemble
python3 assembler.py countdown.asm countdown.mem

### Result (`countdown.mem`)
0x04 0x05   ; LDA #05
0x1E 0x01   ; OUT &01
0x0A        ; DEC
0x14 0x01   ; JNZ loop
0x01        ; HLT

---

## Features
- Labels and forward references resolved automatically  
- Supports immediate (`#`), direct (`&`), and label operands  
- Outputs compact `.mem` file suitable for GHDL testbenches  
- Comments (`;`) ignored gracefully  

---

## Limitations
- Only supports RATZAM-8 ISA (custom 8-bit instruction set)  
- No macros, expressions, or complex directives (yet)  
- All instructions assumed to be 1–2 bytes  

---

## Opcode Table (RATZAM-8 ISA)

| Category         | Instruction   | Opcode |
| ---------------- | ------------- | ------ |
| NOP/Halt         | NOP           | 0x00   |
|                  | HLT           | 0x01   |
| Load/Store       | LDA\_ADDR     | 0x02   |
|                  | STA\_ADDR     | 0x03   |
|                  | LDA\_IMM      | 0x04   |
|                  | LDT\_ADDR     | 0x05   |
|                  | LD\_TMP       | 0x06   |
|                  | INC\_MEM      | 0x07   |
|                  | DEC\_MEM      | 0x08   |
| ALU reg/reg      | ADD\_ACC\_TMP | 0x09   |
|                  | ADD\_ACC\_MDR | 0x0A   |
|                  | SUB\_ACC\_TMP | 0x0B   |
|                  | SUB\_ACC\_MDR | 0x0C   |
|                  | AND\_ACC\_TMP | 0x0D   |
|                  | AND\_ACC\_MDR | 0x0E   |
|                  | OR\_ACC\_TMP  | 0x0F   |
|                  | OR\_ACC\_MDR  | 0x10   |
|                  | XOR\_ACC\_TMP | 0x11   |
|                  | XOR\_ACC\_MDR | 0x12   |
|                  | CMP\_ACC\_TMP | 0x13   |
|                  | CMP\_ACC\_MDR | 0x14   |
| ALU reg/imm      | ADD\_ACC\_IMM | 0x15   |
|                  | SUB\_ACC\_IMM | 0x16   |
|                  | CMP\_ACC\_IMM | 0x17   |
|                  | AND\_ACC\_IMM | 0x18   |
|                  | OR\_ACC\_IMM  | 0x19   |
|                  | XOR\_ACC\_IMM | 0x1A   |
| ALU single       | INC\_ACC      | 0x1B   |
|                  | DEC\_ACC      | 0x1C   |
|                  | NOT\_ACC      | 0x1D   |
|                  | SHL\_ACC      | 0x1E   |
|                  | SHR\_ACC      | 0x1F   |
|                  | CLR\_ACC      | 0x20   |
| Jump/Conditional | JMP\_ADDR     | 0x21   |
|                  | JZ\_ADDR      | 0x22   |
|                  | JNZ\_ADDR     | 0x23   |
|                  | JC\_ADDR      | 0x24   |
|                  | JLT\_ADDR     | 0x25   |
| Stack            | PSH\_ACC      | 0x26   |
|                  | POP\_ACC      | 0x27   |
| I/O              | OUT\_PORT     | 0x28   |
|                  | IN\_PORT      | 0x29   |

## NOTES

Including imm loads for TMP and ACC lowered program mem by 20%
