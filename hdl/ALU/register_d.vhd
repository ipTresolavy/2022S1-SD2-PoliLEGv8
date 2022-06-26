
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief Flip-flop tipo D com enable e reset assíncrono
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity register_d is
    generic (
        size: natural := 8;
        reset_value: natural := 0
    );
    port (
        D: in bit_vector(size - 1 downto 0);
        clock: in bit;
        enable: in bit;
        reset: in bit;
        Q: out bit_vector(size - 1 downto 0)
    );
end entity register_d;

architecture ffd of register_d is
begin

    flip_flop: process(clock, enable, reset) is
    begin
        if(reset = '1') then
            Q <= bit_vector(to_unsigned(reset_value, size));
        elsif(enable = '1' and rising_edge(clock)) then
            Q <= D;
        end if;
    end process;

end architecture ffd;
