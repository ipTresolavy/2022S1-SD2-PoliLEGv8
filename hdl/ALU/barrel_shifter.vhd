
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief Entidade responsável pelos shifts na saída do mux da ALU
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

library ieee;
use ieee.math_real.all;

entity barrel_shifter is
    generic(
        size: natural := 8
    );
    port(
        A: in bit_vector(size - 1 downto 0);
        S: out bit_vector(size - 1 downto 0);
        shift: in bit_vector(integer(floor(log2(real(size)))) - 1 downto 0)
    );
end entity barrel_shifter;

architecture shift of barrel_shifter is

    component mux2x1_bin
        port(
            A: in bit;
            B: in bit;
            S: in bit;
            Y: out bit
        );
    end component;

    constant expoente: natural := integer(floor(log2(real(size))));
    -- uso essa matriz de bits para facilitar na construção do for generate
    type signal_array is array(expoente downto 0) of bit_vector(size - 1 downto 0);
    signal shift_array: signal_array;

begin

    shift_array(0) <= A;
    S <= shift_array(expoente)(size - 1 downto 0);

    -- gera o hardware responsável pelos shifts
    line_generate: for i in expoente - 1 downto 0 generate
        column_generate: for k in size - 1 downto 0 generate
            -- multiplexadores com uma entrada ligada no gcc
            mux_with_0: if k < 2**i generate
                mux_0: component mux2x1_bin port map(shift_array(i)(k), '0', shift(i), shift_array(i + 1)(k));
            end generate mux_with_0;
            -- multiplexadores com as duas entradas provindas de outros multiplexadores ou da entrada da entidade
            mux_without_0: if k >= 2**i generate
                mux_not_0: component mux2x1_bin port map(shift_array(i)(k), shift_array(i)(k - 2**i), shift(i), shift_array(i + 1)(k));
            end generate mux_without_0;
        end generate column_generate;
    end generate line_generate;

end architecture shift;