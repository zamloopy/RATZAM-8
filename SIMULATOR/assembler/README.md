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

| Mnemonic      | Opcode | Bytes | Description                          |
|---------------|--------|-------|--------------------------------------|
| NOP           | 0x00   | 1     | No operation                         |
| HLT           | 0x01   | 1     | Halt execution                       |
| LDA #imm      | 0x04   | 2     | Load immediate into ACC              |
| LDA &addr     | 0x02   | 2     | Load from memory into ACC            |
| STA &addr     | 0x03   | 2     | Store ACC into memory                |
| ADD ACC,TMP   | 0x05   | 1     | ACC = ACC + TMP                      |
| ADD ACC,MDR   | 0x06   | 1     | ACC = ACC + MDR                      |
| SUB ACC,TMP   | 0x07   | 1     | ACC = ACC - TMP                      |
| SUB ACC,MDR   | 0x08   | 1     | ACC = ACC - MDR                      |
| INC ACC       | 0x09   | 1     | Increment ACC                        |
| DEC ACC       | 0x0A   | 1     | Decrement ACC                        |
| AND ACC,TMP   | 0x0B   | 1     | ACC = ACC & TMP                       |
| OR ACC,TMP    | 0x0C   | 1     | ACC = ACC | TMP                       |
| XOR ACC,TMP   | 0x0D   | 1     | ACC = ACC ^ TMP                       |
| NOT ACC       | 0x0E   | 1     | Bitwise NOT ACC                       |
| SHL ACC       | 0x0F   | 1     | Shift ACC left                        |
| SHR ACC       | 0x10   | 1     | Shift ACC right                       |
| CLR ACC       | 0x11   | 1     | Clear ACC                             |
| LDT &addr     | 0x12   | 2     | Load TMP from memory                  |
| JMP &addr     | 0x13   | 2     | Unconditional jump                    |
| JZ &addr      | 0x14   | 2     | Jump if ACC == 0                      |
| JNZ &addr     | 0x15   | 2     | Jump if ACC != 0                      |
| JC &addr      | 0x16   | 2     | Jump if carry                          |
| AND ACC,MDR   | 0x17   | 1     | ACC = ACC & MDR                        |
| OR ACC,MDR    | 0x18   | 1     | ACC = ACC | MDR                        |
| XOR ACC,MDR   | 0x19   | 1     | ACC = ACC ^ MDR                        |
| CMP ACC,TMP   | 0x1A   | 1     | Compare ACC with TMP                   |
| CMP ACC,MDR   | 0x1B   | 1     | Compare ACC with MDR                   |
| PSH ACC       | 0x1C   | 1     | Push ACC to stack                      |
| POP ACC       | 0x1D   | 1     | Pop stack to ACC                        |
| OUT &port     | 0x1E   | 2     | Output ACC to port                      |
| IN &port      | 0x1F   | 2     | Input from port into ACC                |

