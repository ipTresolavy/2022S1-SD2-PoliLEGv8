
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief mux 2 para 1
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

entity mux2x1 is
    generic(
        size: natural := 32
    );
    port(
        A: in bit_vector(size - 1 downto 0);
        B: in bit_vector(size - 1 downto 0);
        S: in bit;
        Y: out bit_vector(size - 1 downto 0)
    );
end entity mux2x1;

architecture structural of mux2x1 is
begin
    Y <= A when S = '0' else
        B;
end architecture structural;