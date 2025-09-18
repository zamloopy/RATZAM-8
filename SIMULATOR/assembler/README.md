# RATZAM-8 Assembler

`assembler.py` is a Python script that assembles human-readable `.asm` source code into machine code (`.mem`) for the **RATZAM-8** CPU and simulation.  
It supports labels, comments, immediate values, direct addressing, I/O operations, and array definitions.

---

## Assembly Language Syntax

1. Comments
- Begin with `;` and run to the end of the line.  
- Ignored by the assembler.

Example:
LDA #05    ; Load 5 into accumulator

2. Labels
- A word followed by `:` defines a label at the current program counter (PC).  
- Labels are symbolic addresses, useful for jumps and loops.

Example:
loop:  DEC
       JNZ loop   ; jump back to "loop"

3. Operands
- Immediate (`#`): literal constant.
Example:
LDA #10     ; ACC = 10

- Direct (`&`): memory or I/O address.
Example:
STA &30     ; RAM[0x30] = ACC

- Label: symbolic address, resolved at assembly time.
Example:
JNZ loop

4. Arrays
- Define arrays using the `@` symbol: `@name #XX` creates an array of length 0xXX starting at the memory location assigned to `name`.
- After definition, the array contents can be accessed using `@name[#index]`.
- Using `@name` alone gives the starting memory address of the array.

Example:
@myarray #10          ; define array of length 0x10
ADD ACC, @myarray[0x03] ; add contents at index 3 to ACC

Arrays are defined using @name #length.
Array contents can be accessed via name[index].
@name returns the starting memory address of the array.
Indexing is zero-based; accessing beyond the array length will raise an error.
Example usage:

		@myarray #10        ; define array of 16 bytes
		LDA #05
		STA myarray[0x03]   ; store 5 in element 3
		ADD ACC, myarray[0x03] ; add element 3 to ACC
		LDA @myarray        ; load start address of array

---

## Usage

Assemble a program:
python3 assembler.py program.asm program.mem

- `program.asm` = input assembly source file  
- `program.mem` = output memory image (one byte per line in hex, e.g., `0xNN`)  

Run with GHDL Simulation:
ghdl -r tb_cpu8 --wave=out.ghw --mem=program.mem

*(Adjust depending on your testbench options.)*

---

## Example

countdown.asm:
; Countdown demo
LDA #05
loop: OUT &01
      DEC
      JNZ loop
      HLT

Assemble:
python3 assembler.py countdown.asm countdown.mem

Result (countdown.mem):
0x04 0x05   ; LDA #05
0x32 0x01   ; OUT &01
0x20        ; DEC
0x27 0x01   ; JNZ loop
0x01        ; HLT

---

## Features
- Labels and forward references resolved automatically  
- Supports immediate (`#`), direct (`&`), label operands, and arrays  
- Outputs compact `.mem` file suitable for GHDL testbenches  
- Comments (`;`) ignored gracefully  

---

## Limitations
- Only supports RATZAM-8 ISA (custom 8-bit instruction set)  
- No macros, expressions, or complex directives (yet)  
- All instructions assumed to be 1–2 bytes  

---

## Opcode Table (RATZAM-8 ISA)

| Category         | Instruction       | Opcode |
| ---------------- | ----------------- | ------ |
| NOP/Halt         | NOP               | 0x00   |
|                  | HLT               | 0x01   |
| Load/Store       | LDA ADDR          | 0x02   |
|                  | STA ADDR          | 0x03   |
|                  | LDA #imm          | 0x04   |
|                  | LDT ADDR          | 0x05   |
|                  | LD TMP            | 0x06   |
|                  | INC MEM           | 0x07   |
|                  | DEC MEM           | 0x08   |
| ALU reg, reg     | ADD ACC, TMP      | 0x09   |
|                  | ADD ACC, MDR      | 0x0A   |
|                  | SUB ACC, TMP      | 0x0B   |
|                  | SUB ACC, MDR      | 0x0C   |
|                  | AND ACC, TMP      | 0x0D   |
|                  | AND ACC, MDR      | 0x0E   |
|                  | OR ACC, TMP       | 0x0F   |
|                  | OR ACC, MDR       | 0x10   |
|                  | XOR ACC, TMP      | 0x11   |
|                  | XOR ACC, MDR      | 0x12   |
|                  | CMP ACC, TMP      | 0x13   |
|                  | CMP ACC, MDR      | 0x14   |
| ALU reg, imm     | ADD ACC, #imm     | 0x15   |
|                  | SUB ACC, #imm     | 0x16   |
|                  | CMP ACC, #imm     | 0x17   |
|                  | AND ACC, #imm     | 0x18   |
|                  | OR ACC, #imm      | 0x19   |
|                  | XOR ACC, #imm     | 0x1A   |
|                  | INC ACC, #imm     | 0x1B   |
|                  | DEC ACC, #imm     | 0x1C   |
|                  | NEG ACC           | 0x1D   |
|                  | SWAP ACC          | 0x1E   |
| ALU single       | INC ACC           | 0x1F   |
|                  | DEC ACC           | 0x20   |
|                  | NOT ACC           | 0x21   |
|                  | SHL ACC           | 0x22   |
|                  | SHR ACC           | 0x23   |
|                  | CLR ACC           | 0x24   |
| Jump/Conditional | JMP ADDR          | 0x25   |
|                  | JZ ADDR           | 0x26   |
|                  | JNZ ADDR          | 0x27   |
|                  | JC ADDR           | 0x28   |
|                  | JLT ADDR          | 0x29   |
|                  | JGT ADDR          | 0x2A   |
|                  | JLE ADDR          | 0x2B   |
|                  | JGE ADDR          | 0x2C   |
| Stack            | PSH ACC           | 0x2D   |
|                  | POP ACC           | 0x2E   |
|                  | CALL ADDR         | 0x2F   |
|                  | RET               | 0x30   |
| I/O              | OUT PORT          | 0x31   |
|                  | IN PORT           | 0x32   |

---

## Notes

The 2 MSBs of the Opcode are currently free to be used.  
They can flag data-types, or both be high to mark a range in memory: from `11xx xxxx` --> `11xx xxxx`.  
Until the second `11` is shown, every byte following the first `11xxxxxx` is grouped together into an *array*.  

- `@myarray #XX` defines a new array called `myarray` of length 0xXX starting at the memory location assigned to `myarray`.  
- After definition, array contents can be accessed with `@myarray[#val]`.  
- Using `@myarray` alone gives the starting memory address of the array.  

Example:
```asm
@myarray #10          ; define array of length 0x10
ADD ACC, @myarray[0x03] ; add contents at index 3 to ACC

