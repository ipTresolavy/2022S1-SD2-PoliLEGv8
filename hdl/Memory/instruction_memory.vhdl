
library ieee;
use ieee.numeric_bit.all;
library std;
use std.textio.all;

entity instruction_memory is
    generic(
        address_size: natural := 16;
        word_size: natural := 8;
        instruction_size: natural := 32;
        file_name: string := "instruction.mif"; -- arquivo de carga inicial 
        busy_time: time := 100 ns -- tempo de atraso da memória 
    );
    port(
        read_address: in bit_vector(address_size - 1 downto 0);
        instruction_memory_enable: in bit;
        instruction: out bit_vector(instruction_size - 1 downto 0);
        instruction_busy: out bit
    );
end entity instruction_memory;

architecture memory of instruction_memory is

    type instruction_array is array(2**address_size - 1 downto 0) of bit_vector(word_size - 1 downto 0);
    
    -- função responsável pela carga inicial
    impure function init_instruction_memory(arquivo : in string) return instruction_array is
        file instruction_file : text open read_mode is arquivo;
        variable file_line : line;
        variable instruction_vector : bit_vector(word_size - 1 downto 0);
        variable memory_instruction: instruction_array;
    begin
        for i in instruction_array'range loop
            readline(instruction_file, file_line);
            read(file_line, instruction_vector);
            memory_instruction(i) := instruction_vector;
        end loop;
        return memory_instruction;
    end function;
    
    -- memória rom
    constant memory_instruction : instruction_array := init_instruction_memory(file_name);
    signal busy: bit;
    signal instruction_intermediary: bit_vector(instruction_size - 1 downto 0);

begin

    instruction_busy <= busy;
    
    -- uso for generate, pois precisamos acessar mais de 1 palavra da memória para obter todos os instruction_size bits
    access_memory_generate: for i in instruction_size/word_size - 1 downto 0 generate
        instruction_intermediary((i + 1)*word_size - 1 downto i*word_size) <= memory_instruction(to_integer(unsigned(read_address)) + i);
    end generate access_memory_generate;
    
    -- controla as saídas da memória levando em conta a temporização
    enable_process: process(instruction_memory_enable)
    begin
        if rising_edge(instruction_memory_enable) then
            busy <= '1';
            busy <= '0' after busy_time;
        end if;
    end process enable_process;
    
    busy_process: process(busy) 
    begin
        if falling_edge(busy) then
            instruction <= instruction_intermediary;
        end if;
    end process busy_process;

end architecture memory;