
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief testbench do PFA
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

entity PFA_tb is
end entity PFA_tb;

architecture testbench of PFA_tb is
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

    type pattern_type is record
        a: bit_vector(7 downto 0);
        b: bit_vector(7 downto 0);
        c_in: bit;
        s: bit_vector(7 downto 0);
        c_out: bit;
    end record;

    type pattern_array is array(natural range <>) of pattern_type;

    constant patterns: pattern_array := 
    (("00101000", "00111111", '0', "01100111", '0'),
     ("00111001", "01111101", '1', "10110111", '0'),
     ("10111001", "01111101", '0', "00110110", '1'),
     ("10111100", "01101101", '1', "00101010", '1'),
     ("00000000", "00001101", '0', "00001101", '0'));

    signal a: bit_vector(7 downto 0);
    signal b: bit_vector(7 downto 0);
    signal c_in: bit;
    signal s: bit_vector(7 downto 0);
    signal c_out: bit;

begin

    DUT: PFA generic map(8) port map(a, b, c_in, s, c_out);

    stimulus_process: process is
    begin
        for k in patterns'range loop

            assert false report "test" severity note;

            a <= patterns(k).a;
            b <= patterns(k).b;
            c_in <= patterns(k).c_in;

            wait for 1 ns;

            assert s = patterns(k).s report "bad s" severity error;
            assert c_out = patterns(k).c_out report "bad c_out" severity error;

        end loop;
        assert false report "end of test" severity note;
        wait;
    end process stimulus_process;
end architecture testbench;