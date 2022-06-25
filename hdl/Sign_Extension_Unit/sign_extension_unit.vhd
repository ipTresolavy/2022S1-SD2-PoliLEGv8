-------------------------------------------------------
--! @file sign_extension_unit.vhd
--! @brief implementação da unidade de extensão de sinal do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-15
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;

entity sign_extension_unit is
    generic(
        doubleword_width : natural := 64
    );
    port(
        legv8_instruction    : in bit_vector(31 downto 0);
        signExt_imm          : out bit_vector(doubleword_width-1 downto 0)
    );
end entity sign_extension_unit;

architecture signExt of sign_extension_unit is


    -- bit fields to be sign extended, depending on the instruction type
    signal ALU_immediate    : bit_vector(11 downto 0);
    signal DT_address       : bit_vector(8 downto 0);
    signal BR_address       : bit_vector(25 downto 0);
    signal COND_BR_address  : bit_vector(18 downto 0);
    signal MOV_immediate    : bit_vector(15 downto 0);

    -- mux source controller signals for bit field selection
    signal D_type, CB_type, IM_type, B_type, STXR : boolean;
    -- if none of the above are asserted, I_type is assumed

    begin

        ALU_immediate <= legv8_instruction(21 downto 10);
        DT_address <= legv8_instruction(20 downto 12);
        BR_address <= legv8_instruction(25 downto 0);
        COND_BR_address <= legv8_instruction(23 downto 5);
        MOV_immediate <= legv8_instruction(20 downto 5);

        D_type <= true when (legv8_instruction(27 downto 24) & legv8_instruction(21) = "10000") else
                  false;

        STXR <= true when (legv8_instruction(31 downto 21) = "11001000000") else
                false;

        CB_type <= true when (legv8_instruction(28 downto 25) = "1010") else
                   false;

        IM_type <= true when (legv8_instruction(31 downto 30) & legv8_instruction(28 downto 23) = "11100101") else
                  false;

        B_type <= true when (legv8_instruction(30 downto 26) = "00101") else
                 false;

        signExt_imm <= bit_vector(resize(signed(BR_address), doubleword_width))     when B_type else
                       bit_vector(resize(signed(MOV_immediate), doubleword_width))  when IM_type else
                       bit_vector(resize(signed(COND_BR_address), doubleword_width))when CB_type else
                       bit_vector(to_unsigned(0, doubleword_width)) when (D_type and STXR) else
                       bit_vector(resize(signed(DT_address), doubleword_width))     when (D_type and not STXR) else
                       bit_vector(resize(signed(ALU_immediate), doubleword_width));

end architecture signExt;
