library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu8 is
    Port (
        A      : in  STD_LOGIC_VECTOR(7 downto 0);
        B      : in  STD_LOGIC_VECTOR(7 downto 0);
        Cin    : in  STD_LOGIC := '0';
        -- Operation selects
        ADD    : in  STD_LOGIC;
        SUB    : in  STD_LOGIC;
        SHL    : in  STD_LOGIC;
        SHR    : in  STD_LOGIC;
        XOR_OP : in  STD_LOGIC;
        OR_OP  : in  STD_LOGIC;
        AND_OP : in  STD_LOGIC;
        NOT_OP : in  STD_LOGIC;
        -- Outputs
        RESULT : out STD_LOGIC_VECTOR(7 downto 0);
        Z      : out STD_LOGIC;  -- Zero flag
        N      : out STD_LOGIC;  -- Negative flag
        C      : out STD_LOGIC;  -- Carry flag
        V      : out STD_LOGIC;  -- Overflow flag
        H      : out STD_LOGIC   -- Half-carry (bit 3 to 4)
    );
end alu8;

architecture Behavioral of alu8 is
    signal A_unsigned, B_unsigned : UNSIGNED(7 downto 0);
    signal temp_result : UNSIGNED(8 downto 0); -- 9-bit for carry
    signal res8 : STD_LOGIC_VECTOR(7 downto 0);
begin
    A_unsigned <= UNSIGNED(A);
    B_unsigned <= UNSIGNED(B);

    process(A_unsigned, B_unsigned, Cin, ADD, SUB, SHL, SHR, XOR_OP, OR_OP, AND_OP, NOT_OP)
        variable Cin_int : integer;
    begin
        -- Convert Cin to integer
        if Cin = '0' then
            Cin_int := 0;
        else
            Cin_int := 1;
        end if;

        -- Defaults
        temp_result <= (others => '0');
        res8 <= (others => '0');
        C <= '0';
        V <= '0';
        H <= '0';

        -- ADD
        if ADD = '1' then
            temp_result <= ('0' & A_unsigned) + ('0' & B_unsigned);
            if Cin_int = 1 then
                temp_result <= temp_result + 1;
            end if;
            res8 <= STD_LOGIC_VECTOR(temp_result(7 downto 0));
            C <= temp_result(8);

            -- Half-carry: sum of lower nibble > 15
            if (to_integer(A_unsigned(3 downto 0)) + to_integer(B_unsigned(3 downto 0)) + Cin_int) > 15 then
                H <= '1';
            else
                H <= '0';
            end if;

            -- Overflow: signed addition
            if (A_unsigned(7) = B_unsigned(7)) and (res8(7) /= A_unsigned(7)) then
                V <= '1';
            else
                V <= '0';
            end if;

        -- SUB
        elsif SUB = '1' then
            temp_result <= ('0' & A_unsigned) + ('0' & (not B_unsigned));
            if Cin_int = 0 then
                temp_result <= temp_result + 1;
            end if;
            res8 <= STD_LOGIC_VECTOR(temp_result(7 downto 0));
            C <= temp_result(8);

            -- Half-carry for subtraction
            if (to_integer(A_unsigned(3 downto 0)) < to_integer(B_unsigned(3 downto 0)) + Cin_int) then
                H <= '1';
            else
                H <= '0';
            end if;

            -- Overflow: signed subtraction
            if (A_unsigned(7) /= B_unsigned(7)) and (res8(7) /= A_unsigned(7)) then
                V <= '1';
            else
                V <= '0';
            end if;

        -- SHL
        elsif SHL = '1' then
            res8 <= STD_LOGIC_VECTOR(A_unsigned(6 downto 0) & '0');
            C <= A_unsigned(7);

        -- SHR
        elsif SHR = '1' then
            res8 <= STD_LOGIC_VECTOR('0' & A_unsigned(7 downto 1));
            C <= A_unsigned(0);

        -- XOR
        elsif XOR_OP = '1' then
            res8 <= STD_LOGIC_VECTOR(A_unsigned xor B_unsigned);

        -- OR
        elsif OR_OP = '1' then
            res8 <= STD_LOGIC_VECTOR(A_unsigned or B_unsigned);

        -- AND
        elsif AND_OP = '1' then
            res8 <= STD_LOGIC_VECTOR(A_unsigned and B_unsigned);

        -- NOT
        elsif NOT_OP = '1' then
            res8 <= STD_LOGIC_VECTOR(not A_unsigned);

        else
            res8 <= (others => '0');
        end if;

        -- Flags
        if res8 = "00000000" then
            Z <= '1';
        else
            Z <= '0';
        end if;

        N <= res8(7);

    end process;

    RESULT <= res8;

end Behavioral;

