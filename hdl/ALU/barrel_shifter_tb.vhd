
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief testbench do barrel shifter
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

library ieee;
use ieee.math_real.all;

entity barrel_shifter_tb is
end entity barrel_shifter_tb;

architecture testbench of barrel_shifter_tb is

    component barrel_shifter is
        generic(
            size: natural := 8
        );
        port(
            A: in bit_vector(size - 1 downto 0);
            S: out bit_vector(size - 1 downto 0);
            shift: in bit_vector(integer(floor(log2(real(size)))) - 1 downto 0)
        );
    end component barrel_shifter;

    type test_type is record
        a: bit_vector(15 downto 0);
        s: bit_vector(15 downto 0);
        shift: bit_vector(3 downto 0);
    end record;

    type test_array is array(natural range <>) of test_type;
    constant tests: test_array :=
    (("1101010100101111", "0101010010111100", "0010"),
     ("0000110100111001", "1101001110010000", "0100"),
     ("0011011101011001", "1011001000000000", "1001"),
     ("0010010010000100", "0010010010000100", "0000"),
     ("1111111011111001", "1000000000000000", "1111"));

    signal a: bit_vector(15 downto 0);
    signal s: bit_vector(15 downto 0);
    signal shift: bit_vector(3 downto 0);

begin

    DUT: component barrel_shifter generic map(16) port map(a, s, shift);

    stimulus_process: process is
    begin
        for k in tests'range loop
            assert false report "test: " & integer'image(k) severity note;
            
            a <= tests(k).a;
            shift <= tests(k).shift;

            wait for 1 ns;

            assert s = tests(k).s report "bad s" severity error;
        end loop;
        assert false report "EOT" severity note;
        wait;
    end process stimulus_process;

end architecture testbench;