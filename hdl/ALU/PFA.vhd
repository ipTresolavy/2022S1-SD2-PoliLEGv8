
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief Somador do tipo Prefix Adder
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

-- As três primeiras entidades representam as três estruturas básicas do Prefix Adder
entity P_G_block is
    generic(
        size: natural := 4
    );
    port(
        A: in bit_vector(size - 1 downto 0);
        B: in bit_vector(size - 1 downto 0);
        P: out bit_vector(size - 1 downto 0);
        G: out bit_vector(size - 1 downto 0)
    );
end entity P_G_block;

architecture P_G_structural of P_G_block is
begin
    P <= A or B;
    G <= A and B;
end architecture P_G_structural;

entity black_block is
    port(
        P_i: in bit;
        P_j: in bit;
        G_i: in bit;
        G_j: in bit;
        P_i_j: out bit;
        G_i_j: out bit
    );
end entity black_block;

architecture black_structural of black_block is
begin
    P_i_j <= P_i and P_j;
    G_i_j <= G_i or (P_i and G_j);
end architecture black_structural;

entity S_block is
    generic(
        size: natural := 4
    );
    port (
        A: in bit_vector(size - 1 downto 0);
        B: in bit_vector(size - 1 downto 0);
        G: in bit_vector(size - 1 downto 0);
        S: out bit_vector(size - 1 downto 0)
    );
end entity S_block;

architecture S_structural of S_block is
begin
    S <= G xor A xor B;
end architecture S_structural;

-- Conjunto de black blocks que será utilizado no generate do PFA
entity black_unit is
    generic(
        size: natural := 2
    );
    port(
        P_vector_i : in bit_vector(size/2 downto 0);
        G_vector_i: in bit_vector(size/2 downto 0);
        P_vector_o: out bit_vector(size/2 - 1 downto 0);
        G_vector_o: out bit_vector(size/2 - 1 downto 0)
    );
end entity black_unit;

architecture black_unit_structural of black_unit is
    component black_block
        port(
            P_i: in bit;
            P_j: in bit;
            G_i: in bit;
            G_j: in bit;
            P_i_j: out bit;
            G_i_j: out bit
        );
    end component black_block;
begin
    unit_generate: for i in size/2 - 1 downto 0 generate
        box: black_block port map(P_vector_i(i + 1), P_vector_i(0), G_vector_i(i + 1),
             G_vector_i(0), P_vector_o(i), G_vector_o(i));
    end generate unit_generate;
end architecture black_unit_structural;

library ieee;
use ieee.math_real.all;

entity PFA is
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
end entity PFA;

architecture PFA_structural of PFA is
    component P_G_block is
        generic(
            size: natural := 4
        );
        port(
            A: in bit_vector(size - 1 downto 0);
            B: in bit_vector(size - 1 downto 0);
            P: out bit_vector(size - 1 downto 0);
            G: out bit_vector(size - 1 downto 0)
        );
    end component P_G_block;
    component black_unit is
        generic(
            size: natural := 2
        );
        port(
            P_vector_i : in bit_vector(size/2 downto 0);
            G_vector_i: in bit_vector(size/2 downto 0);
            P_vector_o: out bit_vector(size/2 - 1 downto 0);
            G_vector_o: out bit_vector(size/2 - 1 downto 0)
        );
    end component black_unit;
    component S_block is
        generic(
            size: natural := 4
        );
        port(
            A: in bit_vector(size - 1 downto 0);
            B: in bit_vector(size - 1 downto 0);
            G: in bit_vector(size - 1 downto 0);
            S: out bit_vector(size - 1 downto 0)
        );
    end component S_block;
    constant expoente : natural := integer(floor(log2(real(size))));
    type signal_array is array(expoente downto 0) of bit_vector(size - 1 downto 0);
    signal p_array: signal_array;
    signal g_array: signal_array;

begin

    g_array(0)(0) <= Carry_in;
    p_array(0)(0) <= '1';
    -- Calcula os P's e G's
    P_G_box: P_G_block generic map(size - 1) port map(A_vector(size - 2 downto 0), B_vector(size - 2 downto 0), p_array(0)(size - 1 downto 1), g_array(0)(size - 1 downto 1));
    -- Calcula as saídas
    S_box: S_block generic map(size) port map(A_vector, B_vector, g_array(expoente), S_vector);

    Carry_out <= (A_vector(size - 1) and B_vector(size - 1)) or ((A_vector(size - 1) or B_vector(size - 1)) and g_array(expoente)(size - 1));
    
    -- Gera os black blocks do PFA
    black_generate: for k in expoente downto 1 generate
        k_line_generate: for i in size - 1 downto 0 generate
            black_line_k: if (i mod 2**k) = (2**k - 1) generate
                -- gero as black units de cada linha de acordo com o padrão da entidade
                black_unit_k: black_unit generic map(2**k) port map(p_array(k - 1)(i downto (i - 2**(k - 1))),g_array(k - 1)(i downto (i - 2**(k - 1))),
                    p_array(k)(i downto (i - 2**(k - 1) + 1)),g_array(k)(i downto (i - 2**(k - 1) + 1)));
            end generate black_line_k;
            -- conecto os fios internos de forma a manter a regularidade da descrição do generate acima
            signals_k: if (i mod 2**k) < 2**(k - 1) generate
                p_array(k)(i) <= p_array(k - 1)(i);
                g_array(k)(i) <= g_array(k - 1)(i);
            end generate signals_k;
        end generate k_line_generate;
    end generate black_generate;
end architecture PFA_structural;