
-------------------------------------------------------
--! @file mul_div_unit_tb.vhd
--! @brief mul_div_unit testbench
--! @author Joao Pedro Cabral Miranda
--! @date 2022-06-11
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity mul_div_unit_tb is
end entity mul_div_unit_tb;

architecture testbench of mul_div_unit_tb is

    component mul_div_unit is
    generic (
        word_s : natural
    );
    port (
        operand_A, operand_B : in bit_vector(word_s-1 downto 0);
        enable, reset, clk : bit;
        div : in bit;   -- div = 1 if division
        unsgn : in bit; -- unsgn = 1 if unsigned operation
        busy : out bit;
        result_high, result_low : out bit_vector(word_s-1 downto 0)
    );
    end component;

    type test_record is record
        A: bit_vector(7 downto 0);
        B: bit_vector(7 downto 0);
        div: bit;
        unsgn: bit;
        result_high: bit_vector(7 downto 0);
        result_low: bit_vector(7 downto 0);
    end record test_record;

    type test_array is array(natural range<>) of test_record;
    
    constant tests: test_array := 
    (("10100001", "00010001", '0', '1', "00001010", "10110001"), -- Mul unsgn
     ("10101010", "10101010", '0', '1', "01110000", "11100100"), -- Mul unsgn
     ("11001000", "11111010", '0', '1', "11000011", "01010000"), -- Mul unsgn
     ("11010011", "10110001", '0', '0', "00001101", "11100011"), -- Mul sgn
     ("10000101", "01100111", '0', '0', "11001110", "10000011"), -- Mul sgn
     ("01111111", "01111111", '0', '0', "00111111", "00000001"), -- Mul sgn
     ("10000001", "00001111", '1', '1', "00001001", "00001000"), -- Div unsgn
     ("11111010", "00001001", '1', '1', "00000111", "00011011"), -- Div unsgn
     ("11101101", "11011110", '1', '1', "00001111", "00000001"), -- Div unsgn
     ("01101111", "11110011", '1', '0', "11111001", "11111000"), -- Div sgn
     ("10000100", "11111101", '1', '0', "00000001", "00101001"), -- Div sgn
     ("01111111", "00001100", '1', '0', "00000111", "00001010")); -- Div sgn

    signal A: bit_vector(7 downto 0);
    signal B: bit_vector(7 downto 0);
    signal enable, reset, clock: bit;
    signal div: bit;
    signal unsgn: bit;
    signal busy: bit;
    signal result_high, result_low: bit_vector(7 downto 0);

begin

    DUT: mul_div_unit generic map(8) port map(A, B, enable, reset, clock, div, unsgn, busy, result_high, result_low);

    clock_process: process is
    begin
        clock <= '0';
        wait for 0.1 ns;
        clock <= '1';
        wait for 0.1 ns;
    end process clock_process;

    reset_process: process is
    begin
        reset <= '1';
        wait for 0.01 ns;
        reset <= '0';
        wait for 100000 ms;
    end process reset_process;

    stimulus_process: process is
    begin

        assert false report "SOT" severity note;

        for i in tests'range loop

            assert false report "test: " & integer'image(i) severity note;

            A <= tests(i).A;
            B <= tests(i).B;
            div <= tests(i).div;
            unsgn <= tests(i).unsgn;
            enable <= '1';

            wait until busy = '1';

            enable <= '0';

            wait until busy = '0';

            assert result_high = tests(i).result_high report "bad result_high!" severity error;
            assert result_low = tests(i).result_low report "bad result_low!" severity error;

        end loop;

        assert false report "EOT" severity note;
        wait;

    end process stimulus_process;

end architecture testbench;
