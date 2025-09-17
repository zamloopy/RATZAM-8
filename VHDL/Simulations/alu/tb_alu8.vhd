library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_alu8 is
-- Testbenches have no ports
end tb_alu8;

architecture Behavioral of tb_alu8 is

    -- Component under test
    component alu8
        Port (
            A      : in  STD_LOGIC_VECTOR(7 downto 0);
            B      : in  STD_LOGIC_VECTOR(7 downto 0);
            Cin    : in  STD_LOGIC := '0';
            ADD    : in  STD_LOGIC;
            SUB    : in  STD_LOGIC;
            SHL    : in  STD_LOGIC;
            SHR    : in  STD_LOGIC;
            XOR_OP : in  STD_LOGIC;
            OR_OP  : in  STD_LOGIC;
            AND_OP : in  STD_LOGIC;
            NOT_OP : in  STD_LOGIC;
            RESULT : out STD_LOGIC_VECTOR(7 downto 0);
            Z      : out STD_LOGIC;
            N      : out STD_LOGIC;
            C      : out STD_LOGIC;
            V      : out STD_LOGIC;
            H      : out STD_LOGIC
        );
    end component;

    -- Test signals
    signal A, B : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal Cin : STD_LOGIC := '0';
    signal ADD, SUB, SHL, SHR, XOR_OP, OR_OP, AND_OP, NOT_OP : STD_LOGIC := '0';
    signal RESULT : STD_LOGIC_VECTOR(7 downto 0);
    signal Z, N, C, V, H : STD_LOGIC;

begin

    -- Instantiate the ALU
    DUT: alu8
        Port map (
            A => A,
            B => B,
            Cin => Cin,
            ADD => ADD,
            SUB => SUB,
            SHL => SHL,
            SHR => SHR,
            XOR_OP => XOR_OP,
            OR_OP => OR_OP,
            AND_OP => AND_OP,
            NOT_OP => NOT_OP,
            RESULT => RESULT,
            Z => Z,
            N => N,
            C => C,
            V => V,
            H => H
        );

    -- Test process
    stim_proc: process
    begin
        -- ADD test
        A <= "00001111"; B <= "00000001"; Cin <= '0';
        ADD <= '1'; wait for 10 ns;
        ADD <= '0'; wait for 5 ns;

        -- ADD with carry
        A <= "11110000"; B <= "00001111"; Cin <= '1';
        ADD <= '1'; wait for 10 ns;
        ADD <= '0'; wait for 5 ns;

        -- SUB test
        A <= "00001111"; B <= "00000101"; Cin <= '1';
        SUB <= '1'; wait for 10 ns;
        SUB <= '0'; wait for 5 ns;

        -- SHL test
        A <= "10000001"; B <= (others => '0'); -- B unused
        SHL <= '1'; wait for 10 ns;
        SHL <= '0'; wait for 5 ns;

        -- SHR test
        A <= "10000001"; B <= (others => '0');
        SHR <= '1'; wait for 10 ns;
        SHR <= '0'; wait for 5 ns;

        -- XOR test
        A <= "10101010"; B <= "11001100";
        XOR_OP <= '1'; wait for 10 ns;
        XOR_OP <= '0'; wait for 5 ns;

        -- OR test
        A <= "10101010"; B <= "01010101";
        OR_OP <= '1'; wait for 10 ns;
        OR_OP <= '0'; wait for 5 ns;

        -- AND test
        A <= "11110000"; B <= "10101010";
        AND_OP <= '1'; wait for 10 ns;
        AND_OP <= '0'; wait for 5 ns;

        -- NOT test
        A <= "10101010"; B <= (others => '0');
        NOT_OP <= '1'; wait for 10 ns;
        NOT_OP <= '0'; wait for 5 ns;

        -- Finish simulation
        wait;
    end process;

end Behavioral;

