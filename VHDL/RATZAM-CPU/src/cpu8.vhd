library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu8 is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        -- Memory interface
        mem_addr     : out std_logic_vector(7 downto 0);
        mem_data_in  : in  std_logic_vector(7 downto 0);
        mem_data_out : out std_logic_vector(7 downto 0);
        mem_we       : out std_logic;
        mem_re       : out std_logic;
        -- I/O interface
        io_data_in   : in  std_logic_vector(7 downto 0);
        io_data_out  : out std_logic_vector(7 downto 0);
        io_we        : out std_logic;
        io_re        : out std_logic;
        -- Interrupt input
        interrupt    : in  std_logic
    );
end entity;

architecture rtl of cpu8 is

    -- CPU registers
    signal PC          : std_logic_vector(7 downto 0) := (others=>'0');
    signal CIR_opcode  : std_logic_vector(7 downto 0) := (others=>'0');
    signal TMP_operand : std_logic_vector(7 downto 0) := (others=>'0');
    signal ACC         : std_logic_vector(7 downto 0) := (others=>'0');
    signal SP          : std_logic_vector(7 downto 0) := x"FF";
    signal HP          : std_logic_vector(7 downto 0) := x"00";
    signal STATUS      : std_logic_vector(4 downto 0) := (others=>'0'); -- Z,N,C,V,I
    signal TMP_data    : std_logic_vector(7 downto 0) := (others=>'0');

    -- Memory interface signals
    signal mem_addr_r     : std_logic_vector(7 downto 0);
    signal mem_data_out_r : std_logic_vector(7 downto 0);
    signal mem_we_r       : std_logic := '0';
    signal mem_re_r       : std_logic := '0';

    -- I/O interface internal signals
    signal io_data_out_r  : std_logic_vector(7 downto 0);
    signal io_we_r        : std_logic := '0';
    signal io_re_r        : std_logic := '0';

    -- ALU control signals
    signal alu_A, alu_B   : std_logic_vector(7 downto 0);
    signal alu_RESULT     : std_logic_vector(7 downto 0);
    signal alu_C, alu_Z, alu_N, alu_V, alu_H : std_logic;
    signal alu_ADD, alu_SUB, alu_SHL, alu_SHR, alu_XOR, alu_OR, alu_AND, alu_NOT : std_logic;

    -- CPU FSM states (INTERRUPT renamed to INT_STATE)
    type state_type is (FETCH_OP, FETCH_OPERAND, EXECUTE, MEMORY_ACCESS, WRITEBACK, INT_STATE);
    signal state : state_type := FETCH_OP;

begin

    ----------------------------------------------------------------------
    -- ALU instance
    ----------------------------------------------------------------------
    alu_inst : entity work.alu8
        port map(
            A      => alu_A,
            B      => alu_B,
            Cin    => '0',
            ADD    => alu_ADD,
            SUB    => alu_SUB,
            SHL    => alu_SHL,
            SHR    => alu_SHR,
            XOR_OP => alu_XOR,
            OR_OP  => alu_OR,
            AND_OP => alu_AND,
            NOT_OP => alu_NOT,
            RESULT => alu_RESULT,
            Z      => alu_Z,
            N      => alu_N,
            C      => alu_C,
            V      => alu_V,
            H      => alu_H
        );

    ----------------------------------------------------------------------
    -- CPU main process
    ----------------------------------------------------------------------
    process(clk,rst)
    begin
        if rst='1' then
            PC <= (others=>'0');
            ACC <= (others=>'0');
            SP <= x"FF";
            HP <= x"00";
            STATUS <= (others=>'0');
            TMP_operand <= (others=>'0');
            TMP_data <= (others=>'0');
            CIR_opcode <= (others=>'0');
            state <= FETCH_OP;

            mem_we_r <= '0';
            mem_re_r <= '0';
            io_we_r <= '0';
            io_re_r <= '0';

            -- Clear ALU signals
            alu_ADD <= '0'; alu_SUB <= '0'; alu_SHL <= '0'; alu_SHR <= '0';
            alu_XOR <= '0'; alu_OR <= '0'; alu_AND <= '0'; alu_NOT <= '0';

        elsif rising_edge(clk) then

            -- Interrupt detection
            if STATUS(0)='1' and interrupt='1' then
                state <= INT_STATE;
            end if;

            case state is

                when FETCH_OP =>
                    mem_addr_r <= PC;
                    mem_re_r <= '1';
                    state <= FETCH_OPERAND;

                when FETCH_OPERAND =>
                    CIR_opcode <= mem_data_in;
                    PC <= std_logic_vector(unsigned(PC)+1);
                    mem_addr_r <= PC;
                    mem_re_r <= '1';
                    state <= EXECUTE;

                when EXECUTE =>
                    TMP_operand <= mem_data_in;
                    mem_re_r <= '0';

                    -- Clear ALU signals
                    alu_ADD <= '0'; alu_SUB <= '0'; alu_SHL <= '0'; alu_SHR <= '0';
                    alu_XOR <= '0'; alu_OR <= '0'; alu_AND <= '0'; alu_NOT <= '0';
                    alu_A <= ACC;
                    alu_B <= TMP_operand;

                    case CIR_opcode is
                        when x"01" =>  -- LD addr
                            mem_addr_r <= TMP_operand;
                            mem_re_r <= '1';
                            state <= MEMORY_ACCESS;

                        when x"02" =>  -- JZ addr
                            if STATUS(4)='1' then -- Zero flag
                                PC <= TMP_operand;
                            end if;
                            state <= FETCH_OP;

                        when x"10" =>  -- PUSH ACC
                            mem_addr_r <= SP;
                            mem_data_out_r <= ACC;
                            mem_we_r <= '1';
                            SP <= std_logic_vector(unsigned(SP)-1);
                            state <= FETCH_OP;

                        when x"11" =>  -- POP ACC
                            SP <= std_logic_vector(unsigned(SP)+1);
                            mem_addr_r <= SP;
                            mem_re_r <= '1';
                            state <= MEMORY_ACCESS;

                        -- ALU instructions
                        when x"20" =>  -- ADD
                            alu_ADD <= '1';
                            state <= WRITEBACK;

                        when x"21" =>  -- SUB
                            alu_SUB <= '1';
                            state <= WRITEBACK;

                        when x"22" =>  -- AND
                            alu_AND <= '1';
                            state <= WRITEBACK;

                        when x"23" =>  -- OR
                            alu_OR <= '1';
                            state <= WRITEBACK;

                        when x"24" =>  -- XOR
                            alu_XOR <= '1';
                            state <= WRITEBACK;

                        when x"25" =>  -- NOT
                            alu_NOT <= '1';
                            state <= WRITEBACK;

                        when others =>
                            state <= FETCH_OP;
                    end case;

                when MEMORY_ACCESS =>
                    TMP_data <= mem_data_in;
                    ACC <= TMP_data;
                    mem_re_r <= '0';
                    mem_we_r <= '0';
                    state <= FETCH_OP;

                when WRITEBACK =>
                    ACC <= alu_RESULT;
                    -- Update CPU STATUS flags from ALU
                    STATUS(4) <= STATUS(4); -- interrupt enable unchanged
                    STATUS(3) <= alu_V;
                    STATUS(2) <= alu_C;
                    STATUS(1) <= alu_N;
                    STATUS(0) <= alu_Z;
                    state <= FETCH_OP;

                when INT_STATE =>
                    -- Push PC to stack, disable interrupt
                    mem_addr_r <= SP;
                    mem_data_out_r <= PC;
                    mem_we_r <= '1';
                    SP <= std_logic_vector(unsigned(SP)-1);
                    PC <= x"F2"; -- ISR address
                    STATUS(0) <= '0'; -- disable interrupts
                    state <= FETCH_OP;

                when others =>
                    state <= FETCH_OP;
            end case;

        end if;
    end process;

    ----------------------------------------------------------------------
    -- Output assignments
    ----------------------------------------------------------------------
    mem_addr <= mem_addr_r;
    mem_data_out <= mem_data_out_r;
    mem_we <= mem_we_r;
    mem_re <= mem_re_r;

    io_data_out <= io_data_out_r;
    io_we <= io_we_r;
    io_re <= io_re_r;

end architecture;

