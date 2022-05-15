-------------------------------------------------------
--! @file data_memory.vhd
--! @brief implementação da RAM de dados do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-14
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;

entity data_memory is
    generic(
        addressable_range   : natural := 16
    );
    port(
        clock               : in  bit;
        address, write_data : in  bit_vector(63 downto 0);
        mem_read, mem_write : in  bit;

        read_data           : out bit_vector(63 downto 0)
    );
end entity data_memory;

architecture data_memory_operation of data_memory is

    type data_memory_type is array(0 to 2**addressable_range - 1) of bit_vector(63 downto 0);
    signal programs_dynamic_data : data_memory_type;

    signal read_data_copy : bit_vector(63 downto 0);

    begin

        write_to_mem:
        process(clock)
            begin
                if (clock'event and clock = '1' and mem_write = '1') then
                    programs_dynamic_data(to_integer(unsigned(address)) mod addressable_range) <= write_data;
                end if;
        end process;

        with mem_read select
            read_data_copy <= programs_dynamic_data(to_integer(unsigned(address)) mod addressable_range) when '1',
                              read_data_copy when others;

        read_data <= read_data_copy;



end architecture data_memory_operation;
