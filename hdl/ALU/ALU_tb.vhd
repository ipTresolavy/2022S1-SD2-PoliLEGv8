
-------------------------------------------------------
--! @file ALU_tb.vhd
--! @brief testbench da ALU
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

library ieee;
use ieee.math_real.all;
use ieee.numeric_bit.all;

entity ALU_tb is
end entity ALU_tb;

architecture testbench of ALU_tb is
    
    component ALU is
        generic(
            word_size: natural := 64
        );
        port (
            clock: in bit;
            reset: in bit;
            A: in bit_vector(word_size - 1 downto 0); -- ALU A
            B: in bit_vector(word_size - 1 downto 0); -- ALU B
            alu_control: in bit_vector(2 downto 0); -- ALU Control's signal
            set_flags: in bit;
            shift_amount: in bit_vector(integer(log2(real(word_size))) - 1 downto 0);
            Y: out bit_vector(word_size - 1 downto 0); -- ALU Result
            Zero: out bit; -- Vale 1, caso Y = 0
            -- Registradores de flags
            Zero_r: out bit;
            Overflow_r: out bit;
            Carry_out_r: out bit;
            Negative_r: out bit
        );
    end component;

    type test_record is record
        A: bit_vector(7 downto 0);
        B: bit_vector(7 downto 0);
        alu_control: bit_vector(2 downto 0);
        set_flags: bit;
        shift_amount: bit_vector(2 downto 0);
        Y: bit_vector(7 downto 0);
        Zero: bit;
        Zero_r: bit;
        Overflow_r: bit;
        Carry_out_r: bit;
        Negative_r: bit;
    end record;

    type test_array is array(natural range <>) of test_record;

    constant test_bench: test_array := 
    (("11010111", "11011100", "000", '0', "000", "10110011", '0', '0', '0', '0', '0'), -- ADD
     ("01110011", "01101111", "000", '1', "010", "10001000", '0', '0', '1', '0', '1'), -- ADDS LSL 2
     ("11110000", "01010100", "001", '0', "000", "01010000", '0', '0', '1', '0', '1'), -- AND
     ("11100000", "00010000", "000", '1', "100", "00000000", '1', '1', '0', '0', '0'), -- ADDS LSL 4
     ("10000001", "01110000", "010", '0', "001", "11100010", '0', '1', '0', '0', '0'), -- OR LSL 1
     ("11111111", "00000001", "000", '1', "111", "00000000", '1', '1', '0', '1', '0'), -- ADDS LSL 7 
     ("00000000", "11010001", "011", '0', "010", "01000100", '0', '1', '0', '1', '0'), -- LSL 2
     ("11111111", "00000000", "100", '1', "000", "11111111", '0', '0', '0', '1', '1'), -- SUBS
     ("00010101", "10101101", "101", '0', "000", "10111000", '0', '0', '0', '1', '1'), -- XOR
     ("00001111", "11000111", "100", '1', "001", "10010000", '0', '0', '0', '0', '1'), -- SUBS LSL 1  
     ("10000001", "11110001", "110", '0', "000", "00001110", '0', '0', '0', '0', '1'), -- NOR
     ("11000101", "11000111", "111", '0', "110", "00000011", '0', '0', '0', '0', '1'), -- LSR 6
     ("11110000", "10000111", "111", '0', "011", "00010000", '0', '0', '0', '0', '1'), -- LSR 3
     ("10011111", "00011110", "001", '1', "000", "00011110", '0', '0', '0', '0', '0'), -- ANDS
     ("10000111", "11110001", "111", '0', "001", "01111000", '0', '0', '0', '0', '0')); -- LSR 1 

    signal clock: bit;
    signal reset: bit;
    signal A: bit_vector(7 downto 0);
    signal B: bit_vector(7 downto 0);
    signal alu_control: bit_vector(2 downto 0);
    signal set_flags: bit;
    signal shift_amount: bit_vector(2 downto 0);
    signal Y: bit_vector(7 downto 0);
    signal alu_out_p: bit_vector(7 downto 0);
    signal Zero: bit;
    signal Zero_r: bit;
    signal Overflow_r: bit;
    signal Carry_out_r: bit;
    signal Negative_r: bit;

begin

    DUT: component ALU generic map(8) port map(clock, reset, A, B, alu_control, set_flags, shift_amount, Y, Zero, 
        Zero_r, Overflow_r, Carry_out_r, Negative_r);

    clock_process: process is
    begin
        clock <= '0';
        wait for 1 ns;
        clock <= '1';
        wait for 1 ns;
    end process clock_process;

    reset_process: process is
    begin
        reset <= '1';
        wait for 0.5 ns;
        reset <= '0';
        wait for 500 ns;
    end process reset_process;

    stimulus_process: process is
    begin

        wait for 0.6 ns;

        for i in test_bench'range loop

            assert false report "test " & integer'image(i) severity note;

            A <= test_bench(i).A;
            B <= test_bench(i).B;
            alu_control <= test_bench(i).alu_control;
            set_flags <= test_bench(i).set_flags;
            shift_amount <= test_bench(i).shift_amount;

            wait for 1 ns;

            assert Y = test_bench(i).Y report "bad Y" severity error;
            assert Zero = test_bench(i).Zero report "bad Zero" severity error;
            assert Zero_r = test_bench(i).Zero_r report "bad Zero_r" severity error;
            assert Overflow_r = test_bench(i).Overflow_r report "bad Overflow_r" severity error;
            assert Carry_out_r = test_bench(i).Carry_out_r report "bad CarryOut_r" severity error;
            assert Negative_r = test_bench(i).Negative_r report "bad Negative_r" severity error;
        
            wait for 1 ns;
        end loop;
        
        assert false report "EOT" severity note;
        wait;

    end process stimulus_process;

end architecture testbench;