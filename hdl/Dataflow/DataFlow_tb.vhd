-------------------------------------------------------
--! @file DataFlow_tb.vhd
--! @brief Testbench for LegV8 dataflow 
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
            write_register_src       : in bit;
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
    signal write_register_src       : bit;
    signal write_register_data_src  : bit_vector (1 downto 0);
    signal write_register_enable    : bit;
    signal data_memory_src          : bit_vector (1 downto 0);

    -- tb signals
    constant clk_period : time := 50 ns;
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

    stimuli : process
    begin
        -- INITIALIZATION 
        set_flags <= '0';
        pc_enable <= '0';
        write_register_enable <= '0';
        mul_div_enable <= '0';

        ticking <= '1';
        reset <= '1';
        wait for clk_period*2;
        reset <= '0';

        -- POPULATE REGISTERS
        data_memory_src <= "11";         -- get doubleword 
        write_register_data_src <= "01"; -- read from memory
        write_register_src <= '0';       -- write_register comes from instruction
        mov_enable <= '0';               -- dont change data from memory with MOV
        write_register_enable <= '1';

        instruction(4 downto 0) <= "00001";
        read_data <= "0000000000000000000000000000000000000000000000000000000000001101"; -- +13
        wait for clk_period;

        instruction(4 downto 0) <= "00010";
        read_data <= "1111111111111111111111111111111111111111111111111111111111111110"; -- -2
        wait for clk_period;

        instruction(4 downto 0) <= "00011";
        read_data <= "1000000000000000000000000000000000000000000000000000000000000000"; -- -2^63
        wait for clk_period;

        instruction(4 downto 0) <= "00100";
        read_data <= "1000000000000000000000000000000000000000000000000000000000000001"; -- -2^63 + 1
        wait for clk_period;

        instruction(4 downto 0) <= "00101";
        read_data <= "1111111111111111111111111111111111111111111111111111111111111111"; -- -1
        wait for clk_period;

        instruction(4 downto 0) <= "00110";
        read_data <= "0000000000000000000000000000000000000000000000000000000000000001"; -- 1
        wait for clk_period;

        instruction(4 downto 0) <= "00111";
        read_data <= "0000000000000000000000000000000000000000000000000000000000001100"; -- +12
        wait for clk_period;

        write_register_enable <= '0';

        report "SOT" severity note;

        -- TEST TYPE R ALU WITHOUT FLAGS
        report "test 1" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "11001011000"&"00111"&"000000"&"00001"&"01000"; -- ADD
        read_register_a_src <= '0';       -- instruction[9:5]
        read_register_b_src <= '0';       -- instruction[20:16]
        alu_b_src <= "00";                -- read_data 2
        alu_control <= "100";             -- add
        shift_amount <= "000000";
        write_register_src <= '0';        -- instruction[4:0]
        write_register_data_src <= "00";  -- alu_out
        write_register_enable <= '1';
        wait for clk_period;        

        write_register_enable <= '0';
        instruction(9 downto 5) <= "01000";  -- rt
        instruction(20 downto 16) <= "00000"; -- XZR
        wait for clk_period;

        assert to_integer(signed(data_memory_address)) = 1
            report "bad alu_out" severity error;

        -- TEST TYPE R WITH FLAGS
        -- ???

        -- TEST TYPE R MUL/DIV
        report "test 2" severity note;
        --                   op        rm     shamt     rn      rt
        instruction <= "10011010110"&"00010"&"000010"&"00111"&"01000"; --SDIV
        read_register_a_src <= '0';       -- instruction[9:5]
        read_register_b_src <= '0';       -- instruction[20:16]
        mul_div_src <= '0'; -- get div
        mul_div_enable <= '1';
        wait until mul_div_busy = '1';
        wait until mul_div_busy = '0';
        mul_div_enable <= '0';

        write_register_src <= '0';
        write_register_data_src <= "10";
        write_register_enable <= '1';
        wait until rising_edge(clk);
         
        write_register_enable <= '0';
        instruction(9 downto 5) <= "01000";   -- rt
        instruction(20 downto 16) <= "00000"; -- XZR
        wait for clk_period;
        
        assert to_integer(signed(data_memory_address)) = -6
            report "bad alu_out" severity error;

        ticking <= '0';
        wait;
    end process;
end tb;
