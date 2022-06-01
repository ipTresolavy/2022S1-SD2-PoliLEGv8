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
        busy_time       : time    := 10 ns;
        data_file_name  : string  := "mem.dat"
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
    constant mem_size : natural := 2**addr_size;
    type mem_type is array(0 to mem_size-1) of
        bit_vector(7 downto 0);

    impure function load_file(filename : string) return mem_type is
        file     read_file : text open read_mode is filename;
        variable file_line : line;
        variable temp_vec  : mem_type;
    begin
        for k in temp_vec'range loop
            readline(read_file, file_line); 
            read(file_line, temp_vec(k));
        end loop;
        return temp_vec;
    end function; 

    signal mem : mem_type := load_file(data_file_name);
    signal addr_number : natural;
begin
    addr_number <= to_integer(unsigned(address));

    raise_busy: process is
    begin
        if mem_enable = '1' then
            busy <= '1';
            wait for busy_time;

            if mem_write = '1' then
                -- copy input to memory and to output
                for byte in 0 to word_size_bytes-1 loop
                    mem((addr_number + word_size_bytes - byte - 1) mod mem_size) <= write_data((byte+1)*8-1 downto byte*8);
                    read_data((byte+1)*8-1 downto byte*8) <= write_data((byte+1)*8-1 downto byte*8);
                end loop;
            else
                -- copy memory to output
                for byte in 0 to word_size_bytes-1 loop
                    read_data((byte+1)*8-1 downto byte*8) <= mem((addr_number + word_size_bytes - byte - 1) mod mem_size);
                end loop;
            end if;

            busy <= '0';
        end if;
        wait on mem_enable;
    end process raise_busy;

end architecture;
