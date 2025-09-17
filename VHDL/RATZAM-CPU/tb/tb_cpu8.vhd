library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_cpu8 is
end tb_cpu8;

architecture sim of tb_cpu8 is

    -- Clock & reset
    signal clk, rst : std_logic := '0';

    -- CPU <-> Memory signals
    signal mem_addr     : std_logic_vector(7 downto 0);
    signal mem_data_in  : std_logic_vector(7 downto 0);
    signal mem_data_out : std_logic_vector(7 downto 0);
    signal mem_we       : std_logic;
    signal mem_re       : std_logic;

    -- CPU <-> I/O
    signal io_data_in  : std_logic_vector(7 downto 0) := (others=>'0');
    signal io_data_out : std_logic_vector(7 downto 0);
    signal io_we       : std_logic;
    signal io_re       : std_logic;

    -- Interrupt
    signal interrupt : std_logic := '0';

    -- Simple 256-byte memory
    type ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
    signal RAM : ram_type := (others => (others=>'0'));

begin

    -- Clock generation: 10 ns period
    clk <= not clk after 5 ns;

    -- Instantiate CPU
    DUT: entity work.cpu8
        port map(
            clk          => clk,
            rst          => rst,
            mem_addr     => mem_addr,
            mem_data_in  => mem_data_in,
            mem_data_out => mem_data_out,
            mem_we       => mem_we,
            mem_re       => mem_re,
            io_data_in   => io_data_in,
            io_data_out  => io_data_out,
            io_we        => io_we,
            io_re        => io_re,
            interrupt    => interrupt
        );

    -- Memory model process
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_we='1' then
                RAM(to_integer(unsigned(mem_addr))) <= mem_data_out;
            end if;

            if mem_re='1' then
                mem_data_in <= RAM(to_integer(unsigned(mem_addr)));
            else
                mem_data_in <= (others=>'0');
            end if;
        end if;
    end process;

    -- Test sequence
    process
    begin
        -- Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- Load a small program into RAM
        -- Example: LD 0x10, ADD 0x11, PUSH ACC, POP ACC, JZ 0x20, I/O output
        RAM(0)  <= x"01"; RAM(1)  <= x"10"; -- LD 0x10
        RAM(2)  <= x"20"; RAM(3)  <= x"11"; -- ADD 0x11
        RAM(4)  <= x"10";                 -- PUSH ACC
        RAM(5)  <= x"11";                 -- POP ACC
        RAM(6)  <= x"02"; RAM(7)  <= x"20"; -- JZ 0x20
        RAM(8)  <= x"F0";                 -- I/O output

        -- Initialize data
        RAM(16) <= x"05"; -- operand 0x10
        RAM(17) <= x"03"; -- operand 0x11

        -- Let CPU run for a while
        wait for 500 ns;

        -- Trigger interrupt
        interrupt <= '1';
        wait for 20 ns;
        interrupt <= '0';

        wait for 200 ns;

        -- Finish simulation
        wait;
    end process;

end architecture;

