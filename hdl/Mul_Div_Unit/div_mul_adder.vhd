
library ieee;
use ieee.numeric_bit.all;

entity div_mul_adder is
    generic (
        word_s : natural := 64
    );
    port (
        operand_A, operand_B : in bit_vector(word_s-1 downto 0);
        c_out  : out bit;
        c_in   : in bit;
        result : out bit_vector(word_s-1 downto 0)
    );
end entity;

architecture behav of div_mul_adder is
    signal temp : bit_vector(word_s downto 0);
begin
    temp <= bit_vector(unsigned("0"&operand_A) + unsigned("0"&operand_B)) when c_in = '0' else
            bit_vector(unsigned("0"&operand_A) + unsigned("0"&operand_B) + to_unsigned(1, word_s));

    result <= temp(word_s-1 downto 0);
    c_out <= temp(word_s);
end architecture;
