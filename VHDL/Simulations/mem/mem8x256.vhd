-- mem8x256.vhd
-- 8-bit wide, 256-depth single-port RAM
-- Synchronous write, synchronous (registered) read.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem8x256 is
    port(
        clk  : in  std_logic;
        -- Control
        we   : in  std_logic;  -- write enable (active '1')
        re   : in  std_logic;  -- read enable  (active '1')
        addr : in  std_logic_vector(7 downto 0); -- 8-bit address (0..255)
        din  : in  std_logic_vector(7 downto 0); -- data in (write)
        dout : out std_logic_vector(7 downto 0)  -- data out (read, registered)
    );
end entity;

architecture rtl of mem8x256 is
    type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
    signal ram     : ram_t := (others => (others => '0'));
    signal dout_r  : std_logic_vector(7 downto 0) := (others => '0');
begin
    -- synchronous process: handle write and registered read
    process(clk)
        variable idx : integer;
    begin
        if rising_edge(clk) then
            idx := to_integer(unsigned(addr));
            -- write (if enabled)
            if we = '1' then
                ram(idx) <= din;
            end if;

            -- read (if enabled) - write-first behavior if both asserted:
            if re = '1' then
                if we = '1' then
                    -- If write and read same cycle, return the new data
                    dout_r <= din;
                else
                    dout_r <= ram(idx);
                end if;
            end if;
        end if;
    end process;

    dout <= dout_r;

end architecture;

