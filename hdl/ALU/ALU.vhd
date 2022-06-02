
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
        clock: in bit;
        reset: in bit;
        A: in bit_vector(word_size - 1 downto 0); -- ALU A
        B: in bit_vector(word_size - 1 downto 0); -- ALU B
        alu_control: in bit_vector(2 downto 0); -- ALU Control's signal
        set_flags: in bit;
        shift_amount: in bit_vector(integer(log2(real(word_size))) - 1 downto 0);
        Y: out bit_vector(word_size - 1 downto 0); -- ALU Result
        Zero: out bit; -- Vale 1, caso Y = 0
        -- Registradores de flags
        Zero_r: out bit;
        Overflow_r: out bit;
        Carry_out_r: out bit;
        Negative_r: out bit
    );
end entity ALU;

architecture operations of ALU is

    component register_d_bin is
        generic (
            reset_value: natural := 0
        );
        port (
            D: in bit;
            clock: in bit;
            enable: in bit;
            reset: in bit;
            Q: out bit
        );
    end component register_d_bin;

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

    component barrel_shifter is
        generic(
            size: natural := 8
        );
        port(
            A: in bit_vector(size - 1 downto 0);
            S: out bit_vector(size - 1 downto 0);
            shift: in bit_vector(integer(log2(real(size))) - 1 downto 0)
        );
    end component barrel_shifter;

    signal xor_B: bit_vector(word_size - 1 downto 0);
    signal pfa_out: bit_vector(word_size - 1 downto 0);
    signal barrel_shifter_in: bit_vector(word_size - 1 downto 0);
    signal barrel_shifter_out: bit_vector(word_size - 1 downto 0);
    signal alu_operation_out: bit_vector(word_size - 1 downto 0);
    signal alu_out: bit_vector(word_size - 1 downto 0);

    -- flags signals
    signal zero_vector: bit_vector(word_size - 1 downto 0);
    signal zero_in: bit;
    signal carry_out_in: bit;
    signal overflow_in: bit;
    signal negative_in: bit;

begin

    -- alu_control(2) = '1' -> operação com sinal
    xor_B_generate: for i in word_size - 1 downto 0 generate
        xor_B(i) <= B(i) xor alu_control(2);
    end generate xor_B_generate;
    
    somador: component PFA generic map(word_size) port map(A, xor_B, alu_control(3), pfa_out, carry_out_in);

    -- Mux seletor de operação
    alu_operation_out <= pfa_out when alu_control(2 downto 0) = "000" else
                         A and B when alu_control(2 downto 0) = "001" else
                         A or B when alu_control(2 downto 0) = "010" else
                         B when alu_control(2 downto 0) = "011" else -- LSL
                         pfa_out when alu_control(2 downto 0) = "100" else
                         A xor B when alu_control(2 downto 0) = "101" else
                         A nor B when alu_control(2 downto 0) = "110" else
                         B; -- LSR
          
    -- Barrel Shifter
    barrel_shifter_in <= alu_operation_out(0 to word_size - 1) when alu_control(2 downto 0) = "111" else
                         alu_operation_out;
    
    shifter: component barrel_shifter generic map(word_size) port map(barrel_shifter_in, barrel_shifter_out, shift_amount);

    -- Saída da ula
    alu_out <= barrel_shifter_out(0 to word_size - 1) when alu_control(2 downto 0) = "111" else
               barrel_shifter_out;
    Y <= alu_out;

    -- Registradores de flags
    registrador_zero: component register_d_bin port map(zero_in, set_flags, reset, Zero_r);
    zero_vector(0) <= alu_out(0);
    z_generate: for i in size - 1 downto 1 generate
        zero_vector(i) <= (zero_vector(i - 1) or alu_out(i));
    end generate z_generate;
    zero_in <= not zero_vector(size - 1);
    Zero <= zero_in;
    registrador_co: component register_d_bin port map(carry_out_in, set_flags, reset, Carry_out_r);
    registrador_ov: component register_d_bin port map(overflow_in, set_flags, reset, Overflow_r);
    overflow_in <= (not (alu_control(2) xor A(size - 1) xor B(size - 1))) and (A(size - 1) xor alu_operation_out(size - 1));
    registrador_neg: component register_d_bin port map(negative_in, set_flags, reset, Negative_r);
    negative_in <= alu_out(word_size - 1);

end architecture operations;