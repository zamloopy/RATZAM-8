========================================
   GHDL + GTKWave Cheat Sheet
========================================

WORKFLOW
--------

1. Analyze (compile sources)
   ghdl -a file1.vhd file2.vhd ...

   - Compiles VHDL into work library.
   - Order matters (dependencies first).

2. Elaborate (build executable)
   ghdl -e testbench_entity_name

   - Use entity name, not filename.
   Example: ghdl -e tb_alu_8

3. Run simulation
   ./tb_alu_8

   Run with waveform dump:
   ghdl -r tb_alu_8 --vcd=waves.vcd
   ghdl -r tb_alu_8 --wave=waves.ghw

   Limit simulation time:
   ghdl -r tb_alu_8 --stop-time=500ns --wave=waves.ghw

4. View waveforms
   gtkwave waves.vcd
   gtkwave waves.ghw


GTKWave TIPS
------------

- Add signals: double-click in left pane.
- Change format: right-click → Data Format → Binary/Hex/Decimal/Analog.
- Zoom time: magnifying glass icons or mouse scroll.
- Zoom height: View → Zoom Height, or drag divider.
- Group buses: select signals → Edit → Combine Signals → Into Bus.


ONE-LINER WORKFLOW
------------------

ghdl -a alu-8.vhd tb_alu-8.vhd
ghdl -e tb_alu_8
ghdl -r tb_alu_8 --wave=alu.ghw
gtkwave alu.ghw


DEBUG TRICKS
------------

- Show integer values:
    signal A_int, B_int : integer;
    A_int <= to_integer(unsigned(A));

- Print debug messages:
    report "Message" severity note;

- Run with strict assertions:
    ghdl -r tb_alu_8 --assert-level=error

