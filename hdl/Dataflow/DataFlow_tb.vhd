-------------------------------------------------------
--! @file DataFlow_tb.vhd
--! @brief Testbench for LegV8 dataflow
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @author Joao Pedro Selva Bernardino (jpselva@usp.br)
--! @date 2022-06-22
-------------------------------------------------------
library ieee;
use ieee.math_real.all;
use ieee.numeric_bit.all;

entity DataFlow_tb is
end DataFlow_tb;

architecture tb of DataFlow_tb is
    constant WORD_SIZE : natural := 64;
    constant DATA_MEMORY_SIZE : natural := 1024;
    constant INSTRUCTION_MEMORY_SIZE : natural := 128;
    constant REG_RESET_VALUE : natural := 0;

    component DataFlow
        generic(
            word_size: natural := 64;
            data_memory_size: natural := 1024;
            instruction_memory_size: natural := 128;
            reg_reset_value: natural := 0
        );
        port (
            clock                    : in bit;
            reset                    : in bit;
            instruction              : in bit_vector (31 downto 0);
            instruction_read_address : out bit_vector (integer(log2(real(instruction_memory_size))) - 1 downto 0);
            read_data                : in bit_vector (word_size - 1 downto 0);
            write_data               : out bit_vector (word_size - 1 downto 0);
            data_memory_address      : out bit_vector (integer(log2(real(data_memory_size))) - 1 downto 0);
            opcode                   : out bit_vector (10 downto 0);
            zero                     : out bit;
            zero_r                   : out bit;
            carry_out_r              : out bit;
            overflow_r               : out bit;
            negative_r               : out bit;
            stxr_try_out             : out bit;
            mov_enable               : in bit;
            alu_control              : in bit_vector (2 downto 0);
            set_flags                : in bit;
            shift_amount             : in bit_vector (integer(log2(real(word_size))) - 1 downto 0);
            alu_b_src                : in bit_vector (1 downto 0);
            mul_div_src              : in bit;
            mul_div_busy             : out bit;
            mul_div_enable           : in bit;
            alu_pc_b_src             : in bit;
            pc_src                   : in bit;
            pc_enable                : in bit;
            monitor_enable           : in bit;
            read_register_a_src      : in bit;
            read_register_b_src      : in bit;
            write_register_src       : in bit_vector(1 downto 0);
            write_register_data_src  : in bit_vector (1 downto 0);
            write_register_enable    : in bit;
            data_memory_src          : in bit_vector (1 downto 0));
    end component;

    -- DUT signals
    signal reset                    : bit;
    signal instruction              : bit_vector (31 downto 0);
    signal instruction_read_address : bit_vector (integer(log2(real(instruction_memory_size))) - 1 downto 0);
    signal read_data                : bit_vector (word_size - 1 downto 0);
    signal write_data               : bit_vector (word_size - 1 downto 0);
    signal data_memory_address      : bit_vector (integer(log2(real(data_memory_size))) - 1 downto 0);
    signal opcode                   : bit_vector (10 downto 0);
    signal zero                     : bit;
    signal zero_r                   : bit;
    signal carry_out_r              : bit;
    signal overflow_r               : bit;
    signal negative_r               : bit;
    signal stxr_try_out             : bit;
    signal mov_enable               : bit;
    signal alu_control              : bit_vector (2 downto 0);
    signal set_flags                : bit;
    signal shift_amount             : bit_vector (integer(log2(real(word_size))) - 1 downto 0);
    signal alu_b_src                : bit_vector (1 downto 0);
    signal mul_div_src              : bit;
    signal mul_div_busy             : bit;
    signal mul_div_enable           : bit;
    signal alu_pc_b_src             : bit;
    signal pc_src                   : bit;
    signal pc_enable                : bit;
    signal monitor_enable           : bit;
    signal read_register_a_src      : bit;
    signal read_register_b_src      : bit;
    signal write_register_src       : bit_vector(1 downto 0);
    signal write_register_data_src  : bit_vector (1 downto 0);
    signal write_register_enable    : bit;
    signal data_memory_src          : bit_vector (1 downto 0);

    -- tb signals
    constant clk_period : time := 50 ps;
    signal clk : bit := '1';
    signal ticking : bit := '0';

begin

    dut : DataFlow
    generic map (
        word_size => WORD_SIZE,
        data_memory_size => DATA_MEMORY_SIZE,
        instruction_memory_size => INSTRUCTION_MEMORY_SIZE,
        reg_reset_value => REG_RESET_VALUE
    )
    port map (
        clock                    => clk,
        reset                    => reset,
        instruction              => instruction,
        instruction_read_address => instruction_read_address,
        read_data                => read_data,
        write_data               => write_data,
        data_memory_address      => data_memory_address,
        opcode                   => opcode,
        zero                     => zero,
        zero_r                   => zero_r,
        carry_out_r              => carry_out_r,
        overflow_r               => overflow_r,
        negative_r               => negative_r,
        stxr_try_out             => stxr_try_out,
        mov_enable               => mov_enable,
        alu_control              => alu_control,
        set_flags                => set_flags,
        shift_amount             => shift_amount,
        alu_b_src                => alu_b_src,
        mul_div_src              => mul_div_src,
        mul_div_busy             => mul_div_busy,
        mul_div_enable           => mul_div_enable,
        alu_pc_b_src             => alu_pc_b_src,
        pc_src                   => pc_src,
        pc_enable                => pc_enable,
        monitor_enable           => monitor_enable,
        read_register_a_src      => read_register_a_src,
        read_register_b_src      => read_register_b_src,
        write_register_src       => write_register_src,
        write_register_data_src  => write_register_data_src,
        write_register_enable    => write_register_enable,
        data_memory_src          => data_memory_src
    );

    -- Clock generation
    clk <= not clk after clk_period/2 when ticking = '1';

    stimuli : process is
        -- procedure reset_test_signals() is
        procedure reset_test_signals is
        begin
            mov_enable <= '0';
            alu_control <= "000";
            set_flags <= '0';
            shift_amount <= (others => '0');
            alu_b_src <= "00";
            mul_div_src <= '0';
            mul_div_enable <= '0';
            alu_pc_b_src <= '0';
            pc_src <= '0';
            pc_enable <= '0';
            monitor_enable <= '0';
            read_register_a_src <= '0';
            read_register_b_src <= '0';
            write_register_src <= "00";
            write_register_data_src <= "00";
            write_register_enable <= '0';
            data_memory_src <= "00";
        end procedure;

        -- assert reg_file[reg_num] = value
        procedure assert_register_integer (
            constant reg_num : in natural range 0 to 31;
            constant value   : in integer;
            constant message : String
            ) is
        begin
            reset_test_signals;
            read_register_b_src <= '0'; -- instruction[20:16]
            instruction(20 downto 16) <= bit_vector(to_unsigned(reg_num, 5));
            data_memory_src <= "11";    -- read register 2
            wait until rising_edge(clk);

            assert to_integer(signed(write_data)) = value
                report message severity error;
        end procedure;

        -- assert reg_file[reg_num] = value
        procedure assert_register_bit_vector (
            constant reg_num : in natural range 0 to 31;
            constant value   : in bit_vector(63 downto 0);
            constant message : String
            ) is
        begin
            reset_test_signals;
            read_register_b_src <= '0'; -- instruction[20:16]
            instruction(20 downto 16) <= bit_vector(to_unsigned(reg_num, 5));
            data_memory_src <= "11";    -- read register 2
            wait until rising_edge(clk);

            assert write_data = value
                report message severity error;
        end procedure;

        -- reg_file[reg_num] <= value
        procedure store_register_integer (
            constant reg_num : in natural range 0 to 30;
            constant value   : in integer
        ) is
        begin
            reset_test_signals;
            data_memory_src <= "11";         -- get doubleword
            write_register_data_src <= "01"; -- read from memory
            write_register_src <= "00";      -- write at instruction[4:0]
            write_register_enable <= '1';

            instruction(4 downto 0) <= bit_vector(to_unsigned(reg_num, 5));
            read_data <= bit_vector(to_signed(value, word_size));
            wait until rising_edge(clk);
        end procedure;

        -- reg_file[reg_num] <= value
        procedure store_register_bit_vector (
            constant reg_num : in natural range 0 to 30;
            constant value   : in bit_vector(word_size-1 downto 0)
        ) is
        begin
            reset_test_signals;
            data_memory_src <= "11";         -- get doubleword
            write_register_data_src <= "01"; -- read from memory
            write_register_src <= "00";      -- write at instruction[4:0]
            write_register_enable <= '1';

            instruction(4 downto 0) <= bit_vector(to_unsigned(reg_num, 5));
            read_data <= value;
            wait until rising_edge(clk);
        end procedure;
    begin
        -- INITIALIZATION
        reset_test_signals;
        reset <= '1';
        ticking <= '1'; -- activate clock
        wait for clk_period*2;
        reset <= '0';

        -- POPULATE REGISTERS
        store_register_integer(1, 13);
        store_register_integer(2, -2);
        store_register_bit_vector(3, x"8000000000000000"); -- -2^63
        store_register_bit_vector(4, x"8000000000000001");  -- -2^63 + 1
        store_register_integer(5, -1);
        store_register_integer(6, 1);
        store_register_integer(7, 12);
        store_register_integer(8, 2);

        reset_test_signals;

        report "SOT" severity note;

        -- TEST TYPE R ALU WITHOUT FLAGS
        report "test 1" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "11001011000"&"00111"&"000000"&"00001"&"00000"; -- ADD
        read_register_a_src <= '0';       -- instruction[9:5]
        read_register_b_src <= '0';       -- instruction[20:16]
        alu_b_src <= "00";                -- read_data 2
        alu_control <= "100";             -- add
        shift_amount <= "000000";
        write_register_src <= "00";        -- instruction[4:0]
        write_register_data_src <= "00";  -- alu_out
        write_register_enable <= '1';
        wait until rising_edge(clk);

        assert_register_integer(0, 1, "bad alu_out");
        reset_test_signals;

        -- TEST TYPE R WITH FLAGS 1
        report "test 2" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "11101011000"&"00110"&"000000"&"00011"&"00000"; -- SUBS
        read_register_a_src <= '0';       -- instruction[9:5]
        read_register_b_src <= '0';       -- instruction[20:16]
        alu_b_src <= "00";                -- read_data 2
        alu_control <= "100";             -- sub
        shift_amount <= "000000";
        write_register_src <= "00";        -- instruction[4:0]
        write_register_data_src <= "00";  -- alu_out
        write_register_enable <= '1';
        set_flags <= '1';
        wait until rising_edge(clk);

        wait for clk_period/2;
        assert (carry_out_r = '1') and (overflow_r = '1') and (zero_r = '0') and (negative_r = '0')
            report "bad flags" severity error;
        wait for clk_period/2;
        reset_test_signals;

        -- TEST TYPE R WITH FLAGS 2
        report "test 3" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "10101011000"&"00101"&"000000"&"00110"&"00000"; -- ADDS
        read_register_a_src <= '0';       -- instruction[9:5]
        read_register_b_src <= '0';       -- instruction[20:16]
        alu_b_src <= "00";                -- read_data 2
        alu_control <= "000";             -- add
        shift_amount <= "000000";
        write_register_src <= "00";        -- instruction[4:0]
        write_register_data_src <= "00";  -- alu_out
        write_register_enable <= '1';
        set_flags <= '1';
        wait until rising_edge(clk);

        wait for clk_period/2;
        assert (carry_out_r = '1') and (overflow_r = '0') and (zero_r = '1') and (negative_r = '0')
            report "bad flags" severity error;
        wait for clk_period/2;
        reset_test_signals;

        -- TEST TYPE R WITH FLAGS 3
        report "test 4" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "10101011000"&"00101"&"000000"&"00101"&"00000"; -- ADDS
        read_register_a_src <= '0';       -- instruction[9:5]
        read_register_b_src <= '0';       -- instruction[20:16]
        alu_b_src <= "00";                -- read_data 2
        alu_control <= "000";             -- add
        shift_amount <= "000000";
        write_register_src <= "00";        -- instruction[4:0]
        write_register_data_src <= "00";  -- alu_out
        write_register_enable <= '1';
        set_flags <= '1';
        wait until rising_edge(clk);

        wait for clk_period/2;
        assert (carry_out_r = '1') and (overflow_r = '0') and (zero_r = '0') and (negative_r = '1')
            report "bad flags" severity error;
        wait for clk_period/2;
        reset_test_signals;

        -- TEST TYPE R MUL/DIV LOW
        report "test 5" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "10011010110"&"00010"&"000010"&"00111"&"00000"; --SDIV
        read_register_a_src <= '0';     -- instruction[9:5]
        read_register_b_src <= '0';     -- instruction[20:16]
        mul_div_src <= '0';             -- get low register
        mul_div_enable <= '1';
        wait until mul_div_busy = '1';
        wait until mul_div_busy = '0';
        mul_div_enable <= '0';

        write_register_src <= "00";
        write_register_data_src <= "10";
        write_register_enable <= '1';
        wait until rising_edge(clk);

        assert_register_integer(0, -6, "bad div low");
        reset_test_signals;

        -- TEST TYPE R MUL/DIV HIGH
        report "test 6" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "10011011110"&"01000"&"000010"&"00101"&"00000"; --UMULH
        read_register_a_src <= '0';     -- instruction[9:5]
        read_register_b_src <= '0';     -- instruction[20:16]
        mul_div_src <= '1';             -- get high register
        mul_div_enable <= '1';
        wait until mul_div_busy = '1';
        wait until mul_div_busy = '0';
        mul_div_enable <= '0';

        write_register_src <= "00";
        write_register_data_src <= "10";
        write_register_enable <= '1';
        wait until rising_edge(clk);

        assert_register_integer(0, 1, "bad mul high");
        reset_test_signals;

        -- TEST TYPE R BR
        report "test 7" severity note;
        store_register_integer(1, INSTRUCTION_MEMORY_SIZE/2);
        --                   op        rm     shamt     rn      rt
        instruction <= "11010110000"&"11111"&"000000"&"00001"&"00000"; --BR X1
        read_register_a_src <= '0';     -- instruction[9:5]
        read_register_b_src <= '0';     -- instruction[20:16] (always XZR)
        alu_b_src <= "00";              -- read register 2
        alu_control <= "000";           -- ADD
        pc_src <= '0';                  -- alu_out
        pc_enable <= '1';
        wait until rising_edge(clk);

        wait for clk_period/2;
        assert to_integer(unsigned(instruction_read_address)) = INSTRUCTION_MEMORY_SIZE/2
            report "bad PC" severity error;
        wait for clk_period/2;
        reset_test_signals;

        -- TEST TYPE R LDXR
        report "test 8" severity note;
        store_register_integer(2, 0); 
        --                   op        rm     shamt     rn      rt
        instruction <= "11001000010"&"11111"&"000000"&"00010"&"00001"; --LDXR X1, X2
        read_register_a_src <= '0';     -- instruction[9:5]
        read_register_b_src <= '0';     -- instruction[20:16] (always XZR)
        alu_b_src <= "00";              -- read register 2
        alu_control <= "000";           -- ADD
        read_data <= bit_vector(to_unsigned(42, word_size));
        write_register_enable <= '1';
        monitor_enable <= '1';
        wait until rising_edge(clk);

        -- TEST TYPE R STXR
        report "test 9" severity note;
        store_register_integer(3, 0); 
        --                   op        rs                   rn      rt
        instruction <= "11001000000"&"00011"&"0"&"11111"&"00010"&"00001"; --STXR X3, X1, X2
        read_register_a_src <= '0'; -- instruction[9:5] 
        alu_b_src <= "11";          -- TODO: tem que ser zero kkk
        alu_control <= "000";
        wait until rising_edge(clk);
        read_data <= bit_vector(to_unsigned(42, word_size));

        assert (stxr_try_out = '0')
            report "bad stxr_try_out" severity error;

        write_register_enable <= '1';
        write_register_data_src <= "11";
        wait until rising_edge(clk);
        write_register_enable <= '0';

        read_register_a_src <= '0'; -- instruction[9:5] 
        alu_b_src <= "11";          -- TODO: tem que ser zero kkk
        alu_control <= "000";
        assert (to_integer(unsigned(write_data)) = 3) 
            report "bad write data" severity error;

        reset_test_signals;

        assert_register_integer(1, 42, "load failed");
        
        -- TEST TYPE R STXR
        --                   op        rm     shamt     rn      rt
        instruction <= "11001000010"&"11111"&"000000"&"00001"&"00000"; --BR X1


        -- TEST OF I-FORMAT INSTRUCTIONS
        report "test 8" severity note;
        reset_test_signals;

        --                   op     ALU_immediate    rn      rd
        instruction <= "1011000100"&"111111111100"&"11111"&"01001"; --ADDIS X9, XZR, #-4
        set_flags <= '1'; -- <-- enable flag registers
        alu_b_src <= "11"; -- alu_b <-- ALU_immediate
        write_register_enable <= '1';
        wait until rising_edge(clk);
        assert_register_integer(9, -4, "Error on ADDIS register value");
        assert negative_r = '1' report "Error on ADDIS negative flag register"
            severity error;

        reset_test_signals;

        --                   op     ALU_immediate    rn      rd
        instruction <= "1111000100"&"111111111100"&"01001"&"01001"; --SUBIS X9, X9, #-4
        alu_control <= "100"; -- <-- ALU SUB (subtraction) operation
        set_flags <= '1'; -- <-- enable flag registers
        alu_b_src <= "11"; -- alu_b <-- ALU_immediate
        write_register_enable <= '1';
        wait until rising_edge(clk);
        assert zero = '1' report "Error on SUBIS zero ALU flag"
            severity error;
        assert_register_integer(9, 0, "Error on first SUBIS register value");
        assert zero_r = '1' report "Error on SUBIS zero flag register"
            severity error;
        assert carry_out_r = '1' report "Error on SUBIS first carry out flag register"
            severity error;

        reset_test_signals;

        -- Preparing the overflow flag register test
        -- X9 <-- -2^63
        data_memory_src <= "11";         -- get doubleword
        write_register_data_src <= "01"; -- read from memory
        write_register_enable <= '1';
        instruction(4 downto 0) <= "01001"; -- X9
        read_data <= x"8000000000000000"; -- -2^63
        wait until rising_edge(clk);

        reset_test_signals;

        --                   op     ALU_immediate    rn      rd
        instruction <= "1111000100"&"000000000001"&"01001"&"01001"; --SUBIS X9, X9, #1
        alu_control <= "100"; -- <-- ALU SUB (subtraction) operation
        set_flags <= '1'; -- <-- enable flag registers
        alu_b_src <= "11"; -- alu_b <-- ALU_immediate
        write_register_enable <= '1';
        wait until rising_edge(clk);
        assert_register_bit_vector(9, x"7FFFFFFFFFFFFFFF", "Error on second SUBIS register value");
        assert carry_out_r = '1' report "Error on second SUBIS carry out flag register"
            severity error;
        assert overflow_r = '1' report "Error on SUBIS overflow flag register"
            severity error;

        -- TEST OF B-FORMAT INSTRUCTIONS
        report "test 9" severity note;
        reset_test_signals;

        --                op     BR_address
        instruction <= "000101"&"00"&x"00007F"; -- B (2^7 - 1)
        alu_control <= "011"; -- ALU pass-b operation
        alu_b_src <= "11"; -- alu_b <-- ALU_immediate
        pc_enable <= '1';
        wait until rising_edge(clk);
        wait for clk_period/2;
        assert instruction_read_address = "1111111" report "Error on PC during branch instruction"
            severity error;
        wait for clk_period/2;

        reset_test_signals;

        --                op     BR_address
        instruction <= "100101"&"00"&x"000000"; -- BL #0
        -- link:
        alu_control <= "011";
        alu_b_src <= "10";
        write_register_src <= "01";
        write_register_enable <= '1';
        wait until rising_edge(clk);
        reset_test_signals;

        -- branch
        alu_control <= "011"; -- ALU pass-b operation
        alu_b_src <= "11"; -- alu_b <-- ALU_immediate
        pc_enable <= '1';
        wait until rising_edge(clk);
        wait for clk_period/2;
        assert instruction_read_address = "0000000" report "Error on PC during branch-and-link instruction"
            severity error;
        wait for clk_period/2;
        assert_register_bit_vector(30, x"000000000000007F", "Error on link register value during branch-and-link");

        -- TEST OF CB-FORMAT INSTRUCTIONS
        report "test 10" severity note;
        reset_test_signals;

        --                  op   COND_BR_address   rt
        instruction <= "10110100"&"000"&x"007F"&"11111"; -- CBZ XZR, #(2^16 -1)
        alu_control <= "011";
        alu_pc_b_src <= '1';
        pc_src <= '1';
        pc_enable <= '1';
        read_register_b_src <= '1';
        wait until rising_edge(clk);
        wait for clk_period/2;
        assert instruction_read_address = "1111100" report "Error on PC during compare-and-branch-if-zero instruction"
            severity error;
        wait for clk_period/2;

        reset_test_signals;

        --                 op   COND_BR_address   rt
        instruction <= "10110101"&"111"&x"FFFF"&"01001"; -- CBNZ X9, #-1
        alu_control <= "011";
        alu_pc_b_src <= '1';
        pc_src <= '1';
        pc_enable <= '1';
        read_register_b_src <= '1';
        wait until rising_edge(clk);
        assert instruction_read_address = "1111000" report "Error on PC during compare-and-branch-if-not-zero instruction"
            severity error;

        -- TEST OF IW/IM-FORMAT INSTRUCTIONS
        report "test 11" severity note;
        reset_test_signals;

        --                  op     lsl MOV_immediate rd
        instruction <= "110100101"&"11"&x"FFFF"&"01001"; -- MOVZ X9, #(2^16 -1), LSL #48
        mov_enable <= '1';
        alu_control <= "011";
        shift_amount <= "11" & "0000";
        read_register_b_src <= '1';
        write_register_enable <= '1';
        wait until rising_edge(clk);
        assert_register_bit_vector(9, x"FFFF000000000000", "Error on MOVZ instruction");

        reset_test_signals;

        --                  op     lsl MOV_immediate rd
        instruction <= "111100101"&"00"&x"FFFF"&"01001"; -- MOVK X9, #(2^16 -1), LSL #0
        mov_enable <= '1';
        alu_control <= "011";
        shift_amount <= "00" & "0000";
        read_register_b_src <= '1';
        write_register_enable <= '1';
        wait until rising_edge(clk);
        assert_register_bit_vector(9, x"FFFF00000000FFFF", "Error on MOVK instruction");


        ticking <= '0';
        wait;
    end process;
end tb;
