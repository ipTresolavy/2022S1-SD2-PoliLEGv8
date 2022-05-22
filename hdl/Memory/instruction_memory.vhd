
-------------------------------------------------------
--! @file instruction_memory.vhdl
--! @brief memória de instrução do tipo MROM
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-21
-------------------------------------------------------

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

     -- memória rom
    type instruction_array is array(2**address_size - 1 downto 0) of bit_vector(word_size - 1 downto 0);
    signal memory_instruction : instruction_array;
    attribute instruction_init_file: string;
    attribute instruction_init_file of memory_instruction: signal is file_name;

    -- sinais intermediários
    signal busy: bit;
    signal instruction_intermediary: bit_vector(instruction_size - 1 downto 0);

begin

    instruction_busy <= busy;
    
    -- uso for generate, pois precisamos acessar mais de 1 palavra da memória para obter todos os instruction_size bits
    access_memory_generate: for i in instruction_size/word_size - 1 downto 0 generate
        instruction_intermediary((i + 1)*word_size - 1 downto i*word_size) <= memory_instruction(to_integer(unsigned(read_address)) + i);
    end generate access_memory_generate;
    
    -- controla as saídas da memória levando em conta a temporização
    enable_process: process
    begin
        if rising_edge(instruction_memory_enable) then
            busy <= '1';
        end if;
        wait for BUSY_TIME;
        busy <= '0';
        instruction <= instruction_intermediary;
        wait on instruction_memory_enable;
    end process enable_process;
    
end architecture memory;
