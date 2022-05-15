-------------------------------------------------------
--! @file alu.vhd
--! @brief implementação das ULAs do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-14
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;

entity alu is
    port (
        a           : in bit_vector(63 downto 0);
        b           : in bit_vector(63 downto 0);
        alu_op      : in bit_vector(3 downto 0);

        zero        : out bit;
        result      : out bit_vector(63 downto 0);
        overflow    : out bit;
        carry_out   : out bit
    );
end entity alu;

architecture alu_operation of alu is

    component full_adder is
        port (
            a           : in bit;
            b           : in bit;
            alu_op      : in bit_vector(3 downto 0);
            carry_in    : in bit;
            less        : in bit;

            carry_out   : out bit;
            result      : out bit;
            set         : out bit
        );
    end component full_adder;

    signal carrys   : bit_vector(64 downto 0);
    signal ground   : bit_vector(62 downto 0); -- to wire first and middle adders' "set" signal
    signal set      : bit; -- used in LESS THAN operations

    -- mask of zeroes and ula result copy for zero flag checking
    constant mask   : bit_vector(63 downto 0) := (others => '0');
    signal result_copy : bit_vector(63 downto 0);

    begin

        -- if subtracting, initial carry is 1 because of two's complement
        with alu_op select
            carrys(0) <= '1' when "0110",
                         '0' when others;

        first_adder:
        full_adder port map (a(0), b(0), alu_op, carrys(0), set, carrys(1), result_copy(0), ground(0));

        middle_full_adders:
        for i in 62 downto 1 generate
           full_adder_bit: full_adder port map (a(i), b(i), alu_op, carrys(i), '0', carrys(i+1), result_copy(i), ground(i)) ;
        end generate middle_full_adders;

        last_adder:
        full_adder port map (a(63), b(63), alu_op, carrys(63), '0', carrys(64), result_copy(63), set) ;

        carry_out <= carrys(64);
        overflow <= carrys(64) xor carrys(63);

        result <= result_copy;
        zero <= '1' when (result_copy = mask) else
                '0';

end architecture alu_operation;
