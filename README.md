# RATZAM-8			   
# 8-BIT Minecraft Computer		   
# Zachary M. Allen & Ryan T. Allen      
# Project start-date: 9/16/2025	   

This folder contains the design, development, and use of a custom DIY computer implemented in Minecraft, created by brothers Ryan (RAT) and Zack (ZAM) Allen. It's an **8-bit system** utilizing the **Von Neumann Architecture**, with **256 bytes** of total system memory (MEM).  

Programs are loaded from ROM onto an allocated MEM partition. The other main allocation of MEM is the system RAM, though MEM also contains an allocation for the User Input/Output (IOP) system. For example, it can store a sequence of input or output data to operate on over a chunk. The IOP (Input/Output Port control register) contains `0xPiPo`. Pi and Po are nibbles that set the mode of input fetching and output displaying.  

- One mode could continuously display processed outputs.  
- Another mode could display outputs only when the user sends a signal.  
- Input/output IOP modes could perform the Double Dabble algorithm on input/output before processing, so users can interact with the computer using base-10 instead of binary.  

A small ROM can contain CPU instructions to perform binary-to-BCD conversion in the CPU itself, activated by the Control Unit when a DD (Double Dabble) command is given. Alternatively, a pipelined look-ahead circuit can concurrently process Double Dabble faster but requires more space.  

MEM also contains an allocation for a Stack, where values are "pushed" or "popped".  

The ALU's output flags are used to implement conditional logic within programs. For example, if the result of `A - B` is 0, the program counter (rPC) jumps to address `0xXX`.  

The CPU has the following 8 registers, r1-r8:
[A, B, X, PC, IR, ACC, MAR, MDR] = [r1, r2, r3, r4, r5, r6, r7, r8]
- `A` and `B` — working registers for most operations  
- `PC` — program counter  
- `X` — general-purpose register  
- `IR` — instruction register, which reads the control bus and stores the next instruction.  
- 'MAR' — memory address register
- 'MDR' — memory data register
- 'ACC' — accumulator register for ALU feedback

Instructions loaded into the IR are decoded into activation signals that control the CPU. Each Op-Code can take an arbitrary number of instruction cycles, so a *CIC (Current Instruction Complete)* signal monitors each instruction’s evaluation. The next instruction is not loaded until the CIC signal goes high. Some Op-Codes require multiple instruction cycles, so the control unit places the appropriate sequence of instructions in the *Instruction Queue* (~4 long). 

To store a result from the ALU into RAM at an arbitrary (for example address 0xE5) &0xE5, the ALU output gets loaded into MDR, and the value 0xE5 gets loaded into MAR, which would have been a value programmed and then interpreted by the control unit. With data and address loaded, a command is given to write the data to the selected RAM location.

The Accumulator is the ALU's data feedback register. The control unit saves the current result to ACC when that result is needed for the subsequent operation, though ACC can also be loaded from the CPU registers r1-r8. 

---

## RATZAM-8 Design Requirements

- **Java:** 1.20.1  
- **Forge:** 47.4.0  
- **Project Red Mods:** 1.20.1-4.21.0  
  - Core  
  - Expansion  
  - Exploration  
  - Fabrication  
  - Illumination  
  - Integration  
  - Transmission  

---
