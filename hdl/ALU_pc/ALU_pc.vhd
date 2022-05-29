
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief ALU responsável por incrementar o pc
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

entity ALU_pc is
    generic(
        size: natural := 64
    );
    port(
        PC: in bit_vector(size - 1 downto 0);
        increment: in bit_vector(size - 1 downto 0);
        PC_register_in: out bit_vector(size - 1 downto 0)
    );
end entity ALU_pc;

architecture adder of ALU_pc is

    component PFA is
        generic(
            size: natural := 4
        );
        port(
            A_vector: in bit_vector(size - 1 downto 0);
            B_vector: in bit_vector(size - 1 downto 0);
            Carry_in: in bit;
            S_vector: out bit_vector(size - 1 downto 0);
            Carry_out: out bit
        );
    end component PFA;

begin

    adder: component PFA generic map(size) port map(PC, increment, '0', PC_register_in, open);

end architecture adder;