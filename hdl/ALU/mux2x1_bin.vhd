-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief mux 2 para 1 para binários
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

entity mux2x1_bin is
    port(
        A: in bit;
        B: in bit;
        S: in bit;
        Y: out bit
    );
end entity mux2x1_bin;

architecture structural of mux2x1_bin is
begin
    Y <= A when S = '0' else
        B;
end architecture structural;