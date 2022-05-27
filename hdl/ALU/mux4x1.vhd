-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief mux 4 para 1 
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

entity mux4x1 is
    generic(
        size: natural := 32
    );
    port(
        A: in bit_vector(size - 1 downto 0);
        B: in bit_vector(size - 1 downto 0);
        C: in bit_vector(size - 1 downto 0);
        D: in bit_vector(size - 1 downto 0);
        S: in bit_vector(1 downto 0);
        Y: out bit_vector(size - 1 downto 0)
    );
end entity mux4x1;

architecture structural of mux4x1 is
begin
    Y <= A when S = "00" else
         B when S = "01" else
         C when S = "10" else
         D;
end architecture structural;