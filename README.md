=======================================================================================

&nbsp;														Zachary M Allen

&nbsp;						'RATZAM-8'						Ryan T Allen

&nbsp;														9/16/2025

=======================================================================================



&nbsp;	This folder's contents relates to the design, development, and use of a custom-DIY

computer implemented in the game Minecraft, created by brothers Ryan (RAT) and Zack 

(ZAM) Allen. It's an 8-bit system utilizing the Von Neumann Architecture with 256 bytes of

total system-memory (MEM).

&nbsp;	Programs are loaded from ROM onto an allocated MEM partition.

The other main allocation of MEM is the system RAM, though MEM will also contain an

allocation for the User-Input/Output system (e.g. store a sequence of input or output data

to operate on over a chunk. The IOP (input output port control register) contains 0xPiPo.

Pi and Po are nibbles that set the mode of input fetching and output displaying. One mode

could continuously display processed outputs, or perhaps only outputs when the user send 

a signal. There could also be input/output IOP modes to perform the Double Dabble 

algorithm on the input/output before processing- so the user can interact with the computer 

using base-10 instead of binary. There could be a small ROM containing the needed CPU

instructions to perform the binary-BCD conversion in the CPU itself, activated by the 

Control Unit when a DD (double dabble) command is given. Alternatively, a pipelined 

look-ahead circuit that concurrently processes double dabble would be quicker, but 

physically larger. There is also an allocation of MEM for a Stack, which values are 

"pushed" to or "popped" from.

&nbsp;	The ALU's output flags are used to implement conditional logic within programs.

For example, if the result of A-B is 0, jump the program counter to address 0xXX...

The CPU has working registers rA and rB for most operations, the program counter rPC,

and a general-purpose register rX. These are the registers that the Opcodes operate on. 

The final register is just the instruction register (IR) that reads the control bus and stores

the next instruction in the CPU's control unit. The instruction loaded into the IR is decoded 

into activation signals that appropriately controls the CPU. Each instruction could take an

arbitrary number of clock cycles, so a "CIC" (current instruction complete) signal is used 

to monitor each instruction's evaluation. The next instruction isn't loaded until the CIC signal

goes high.  



=======================================================================================

This Minecraft redstone computer is designed for:

* Java 1.20.1
* Forge 47.4.0
* Project Red Mods 1.20.1-4.21.0

&nbsp;	- core, expansion, exploration, fabrication, illumination, integration, transmission







