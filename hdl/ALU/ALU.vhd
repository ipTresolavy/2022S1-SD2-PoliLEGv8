
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief ALU do polilegv8
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

entity ALU is
    generic(
        word_size: natural := 64
    );
    port (
        A: in bit_vector(word_size - 1 downto 0); -- ALU A
        B: in bit_vector(word_size - 1 downto 0); -- ALU B
        alu_op: in bit_vector(4 downto 0); -- ALU Control's signal
        Y: out bit_vector(word_size - 1 downto 0); -- ALU Result
        Zero: out bit; -- Vale 1, caso Y = 0
        -- Registradores de flags
        Zero_r: out bit;
        Overflow_r: out bit;
        Carry_out_r: out bit;
        Negative_r: out bit;
    );
end entity ALU;
