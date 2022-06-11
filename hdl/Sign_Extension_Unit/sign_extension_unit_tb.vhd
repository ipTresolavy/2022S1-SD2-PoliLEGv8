-------------------------------------------------------
--! @file sign_extension_unit_tb.vhd
--! @brief testbench da unidade de extensão de sinal do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-06-11
-------------------------------------------------------
library IEEE;
use ieee.numeric_bit.all;

entity sign_extension_unit_tb is
end entity sign_extension_unit_tb;

architecture TB of sign_extension_unit_tb is

    component sign_extension_unit is
        generic(
            doubleword_width : natural := 64
        );
        port(
            legv8_instruction    : in bit_vector(31 downto 0);
            signExt_imm          : out bit_vector(doubleword_width-1 downto 0)
        );
    end component sign_extension_unit;


    -- generic
    constant doubleword_width : natural := 64;

    --port
    signal legv8_instruction : bit_vector(31 downto 0);
    signal signExt_imm       : bit_vector(doubleword_width-1 downto 0);

begin

    DUT:
    sign_extension_unit generic map (doubleword_width) port map (legv8_instruction, signExt_imm);

    testbench:
    process
    begin
        legv8_instruction <= "10010001000000000000001111101001"; -- ADDI X9, XZR, #0
        wait for 100 ps;
        assert signExt_imm = bit_vector(to_signed(0, signExt_imm'length))
            report "Error on I-format instruction" severity error;

        legv8_instruction <= "11111000010000010000001110011110"; -- LDUR LR, [SP, #16]
        wait for 100 ps;
        assert signExt_imm = bit_vector(to_signed(16, signExt_imm'length))
            report "Error on D-format instruction" severity error;


        legv8_instruction <= "10010100000000000000000000000100"; -- BL #4
        wait for 100 ps;
        assert signExt_imm = bit_vector(to_signed(4, signExt_imm'length))
            report "Error on B-format instruction" severity error;


        legv8_instruction <= "10110101000000000000000011101010"; -- CBNZ X10, #7
        wait for 100 ps;
        assert signExt_imm = bit_vector(to_signed(7, signExt_imm'length))
            report "Error on CB-format instruction" severity error;

        legv8_instruction <= "11010010100111111111111110010011"; -- MOVZ X19, #-4, LSL 0
        wait for 100 ps;
        assert signExt_imm = bit_vector(to_signed(-4, signExt_imm'length))
            report "Error on IW/IM-format instruction" severity error;
    wait;
    end process testbench;

end architecture TB;
