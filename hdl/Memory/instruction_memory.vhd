-------------------------------------------------------
--! @file instruction_memory.vhd
--! @brief implementação da ROM de instruções do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-14
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;
use std.textio.all;

entity instruction_memory is
    generic(
        addressable_range   : natural := 8;
        program             : string  := "program.dat"
    );
    port(
        instruction_address : in  bit_vector(63 downto 0);
        instruction         : out bit_vector(31 downto 0)
    );
end entity instruction_memory;

architecture instruction_memory_operation of instruction_memory is

    type instruction_memory_type is array(0 to 2**addressable_range - 1) of bit_vector(31 downto 0);

    -- file-reader function --
    impure function initialize(filename : in string) return instruction_memory_type is

        file     file_to_be_read  : text open read_mode is filename;
        variable file_line        : line;
        variable temp_bv          : bit_vector(31 downto 0);
        variable temp_mem         : instruction_memory_type;

        begin
            for i in instruction_memory_type'range loop
                readline(file_to_be_read, file_line);
                read(file_line, temp_bv);
                temp_mem(i) := temp_bv;
            end loop;

            return temp_mem;
    end;
    -- end of function --

    constant program_instructions : instruction_memory_type := initialize(program);

    begin

        instruction <= program_instructions(to_integer(unsigned(instruction_address)) mod addressable_range);

end architecture instruction_memory_operation;
