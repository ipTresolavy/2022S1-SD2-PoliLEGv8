-------------------------------------------------------
--! @file full_adder.vhd
--! @brief implementação do somador completo das ULAs do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-14
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;

entity full_adder is
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
end entity full_adder;

architecture full_adder_operation of full_adder is

    signal a_mux_out, b_mux_out : bit;

    begin

        with alu_op(3) select
            a_mux_out <= a when '0',
                         (not a) when others;

        with alu_op(2) select
            b_mux_out <= b when '0',
                         (not b) when others;

        with alu_op(1 downto 0) select
            result <= (a_mux_out and b_mux_out)              when "00", -- AND operation
                      (a_mux_out or b_mux_out)               when "01", -- OR operation
                      (a_mux_out xor b_mux_out xor carry_in) when "10", -- arithmetic operations
                      less                                   when others; -- LESS THAN operation

        -- propagates and generates
        with alu_op(1 downto 0) select
            carry_out <= ( (a_mux_out and b_mux_out) or ( (a_mux_out xor b_mux_out) and carry_in) )  when "10", -- arithmetic operations
                         '0' when others;

        set <= (a_mux_out xor b_mux_out xor carry_in);

end architecture full_adder_operation;
