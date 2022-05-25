
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief Unidade extensora de imediatos da instrução
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-21
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity sign_extended is
    port(
        instruction: in bit_vector(31 downto 0);
        imediate_extended: out bit_vector(63 downto 0)
    );
end entity sign_extended;

architecture extender of sign_extended is

    signal selector: bit_vector(2 downto 0);

begin

    selector <= "000" when instruction(31 downto 26) = "000101" else -- B type
                "001" when (instruction(31 downto 24) = "01010100" or instruction(31 downto 24) = "10110100"
                    or instruction(31 downto 24) = "10110101") else -- CB type
                "010" when (instruction(31 downto 23) = "110100101" or instruction(31 downto 23) = "111100101") else -- IW Type
                "011" when (instruction(31 downto 22) = "1001000100" or instruction(31 downto 22) = "1001001000" 
                    or instruction(31 downto 22) = "1011000100" or instruction(31 downto 22) = "1011001000"
                    or instruction(31 downto 22) = "1101000100" or instruction(31 downto 22) = "1101001000" 
                    or instruction(31 downto 22) = "1111000100" or instruction(31 downto 22) = "1111001000") else -- I type
                "100"; -- D type

    imediate_extended <= bit_vector(resize(signed(instruction(25 downto 0)), 64))  when selector = "000" else
                         bit_vector(resize(signed(instruction(23 downto 5)), 64))  when selector = "001" else
                         bit_vector(resize(signed(instruction(20 downto 5)), 64))  when selector = "010" else
                         bit_vector(resize(signed(instruction(21 downto 10)), 64)) when selector = "011" else
                         bit_vector(resize(signed(instruction(20 downto 12)), 64));

end architecture extender;