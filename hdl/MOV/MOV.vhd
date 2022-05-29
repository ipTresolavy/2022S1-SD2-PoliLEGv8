
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief Entidade responsável pelas instruções LSL e LSR
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

entity MOV is
    generic(
        word_size : natural := 64
    );
    port(
        A: in bit_vector(word_size - 1 downto 0);
        B: out bit_vector(word_size - 1 downto 0);
        imediato: in bit_vector(word_size/4 - 1 downto 0);
        shift: in bit_vector(1 downto 0); -- tamanho do shift a ser realizado
        mov_enable: in bit; -- UC signal: habilita a operação MOV
        z_k: in bit -- UC signal: 0 gera um MOVZ, 1 gera um MOVK
    );
end entity MOV;

architecture movz_k of MOV is

    component mux4x1
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
    end component;

    signal mov_result: bit_vector(word_size - 1 downto 0);
    signal zero: bit_vector(word_size/4 - 1 downto 0);
    type signal_array is array(3 downto 0) of bit_vector(1 downto 0);
    signal mux_selector: signal_array;

begin

    B <= A when mov_enable = '0' else
         mov_result;
    
    -- uso esse lsb mux selector para poder usar o for generate
    mux_selector(0) <= z_k & (not shift(1) and not shift(0));
    mux_selector(1) <= z_k & (not shift(1) and shift(0));
    mux_selector(2) <= z_k & (shift(1) and not shift(0));
    mux_selector(3) <= z_k & (shift(1) and shift(0));

    -- gera o hardware responsável pelo MOVZ e MOVk
    mux_unit_generate: for i in 3 downto 0 generate
        shift_unit: component mux4x1 generic map(word_size/4) 
            port map(zero, imediato, A((i + 1)*word_size/4 - 1 downto 0), imediato, mux_selector(i), mov_result((i + 1)*word_size/4 - 1 downto 0));
    end generate mux_unit_generate;

end architecture movz_k;