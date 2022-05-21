-------------------------------------------------------
--! @file data_memory.vhd
--! @brief byte-addressable RAM
--! @author Joao Pedro Selva (jpselva@usp.br)
--! @date 2022-05-21
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity data_memory is 
    generic (
        word_size_bytes : natural := 8;
        addr_size       : natural := 16;
        busy_time       : time    := 10 ns
    ); 
    port (
        address                  : in  bit_vector(addr_size-1 downto 0);
        write_data               : in  bit_vector(word_size_bytes*8-1 downto 0);
        mem_enable, mem_write    : in  bit;
        busy                     : out bit;
        read_data                : out bit_vector(word_size_bytes*8-1 downto 0)
    );
end entity;

architecture arch of data_memory is
    constant mem_size : natural := 2**addr_size-1;
    type mem_type is array(0 to mem_size-1) of
        bit_vector(7 downto 0); 

    signal mem : mem_type;
    signal addr_number : natural;
    signal busy_in : bit; -- internal busy signal
begin
    addr_number <= to_integer(unsigned(address));
    busy <= busy_in;

    get_busy: process (mem_enable) is
    begin
        if mem_enable = '1' then
            busy_in <= '1';
            busy_in <= '0' after busy_time;
        end if;
    end process get_busy;

    finish: process (busy_in) is 
    begin
        if falling_edge(busy_in) then
            if mem_write = '1' then
                for byte in 0 to word_size_bytes-1 loop
                    mem((addr_number + byte) mod mem_size) <= write_data((byte+1)*8-1 downto byte*8);
                end loop;
            end if;

            for byte in 0 to word_size_bytes-1 loop
                read_data((byte+1)*8-1 downto byte*8) <= mem((addr_number + byte) mod mem_size);
            end loop;
        end if;
    end process finish;

end architecture;
