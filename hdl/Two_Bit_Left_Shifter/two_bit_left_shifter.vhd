-------------------------------------------------------
--! @file two_bit_left_shifter.vhd
--! @brief implementação do deslocador de dois bit para a esquerda
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-06-11
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;

entity two_bit_left_shifter is
    generic(
        double_word_width : natural := 64
    );
    port(
        in_doubleword  : in  bit_vector(double_word_width-1 downto 0);
        out_doubleword : out bit_vector(double_word_width-1 downto 0)
);
end entity two_bit_left_shifter;

architecture shifter of two_bit_left_shifter is
begin
    out_doubleword <= in_doubleword sll 2;
end architecture shifter;


