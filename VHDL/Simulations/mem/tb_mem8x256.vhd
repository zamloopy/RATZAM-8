-- tb_mem8x256.vhd
-- Testbench for mem8x256.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mem8x256 is
end entity;

architecture sim of tb_mem8x256 is
    signal clk   : std_logic := '0';
    signal we    : std_logic := '0';
    signal re    : std_logic := '0';
    signal addr  : std_logic_vector(7 downto 0) := (others => '0');
    signal din   : std_logic_vector(7 downto 0) := (others => '0');
    signal dout  : std_logic_vector(7 downto 0);

    -- DUT
    component mem8x256
        port(
            clk  : in  std_logic;
            we   : in  std_logic;
            re   : in  std_logic;
            addr : in  std_logic_vector(7 downto 0);
            din  : in  std_logic_vector(7 downto 0);
            dout : out std_logic_vector(7 downto 0)
        );
    end component;

begin
    -- clock generator: 10 ns period
    clk <= not clk after 5 ns;

    -- instantiate DUT
    dut: mem8x256
        port map(
            clk  => clk,
            we   => we,
            re   => re,
            addr => addr,
            din  => din,
            dout => dout
        );

    -- stimulus
    stim_proc: process
    begin
        -- Write value 0xAA at address 0x10
        addr <= x"10";
        din  <= x"AA";
        we   <= '1';
        wait until rising_edge(clk);
        we <= '0';

        -- Read back from 0x10
        re <= '1';
        wait until rising_edge(clk);
        re <= '0';

        -- Write value 0x55 at address 0x20
        addr <= x"20";
        din  <= x"55";
        we   <= '1';
        wait until rising_edge(clk);
        we <= '0';

        -- Read back from 0x20
        re <= '1';
        wait until rising_edge(clk);
        re <= '0';

        -- Try simultaneous write+read at addr 0x30
        addr <= x"30";
        din  <= x"F0";
        we   <= '1';
        re   <= '1';
        wait until rising_edge(clk);
        we <= '0';
        re <= '0';

        -- Read back from 0x30 (should still be F0)
        re <= '1';
        wait until rising_edge(clk);
        re <= '0';

        wait for 20 ns;
        assert false report "Simulation finished" severity failure;
    end process;
end architecture;
