
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief Flip-flop tipo D com enable e reset assíncrono para binários
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity register_d_bin is
    port (
        D: in bit;
        clock: in bit;
        enable: in bit;
        reset: in bit;
        Q: out bit
    );
end entity register_d_bin;

architecture ffd of register_d_bin is
begin

    flip_flop: process(clock, enable, reset) is
    begin
        if(reset = '1') then
            Q <= '0';
        elsif(enable = '1' and rising_edge(clock)) then
            Q <= D;
        end if;
    end process;

end architecture ffd;
