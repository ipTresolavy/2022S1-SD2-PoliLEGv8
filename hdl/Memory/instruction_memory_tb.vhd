-------------------------------------------------------
--! @file instruction_memory_tb.vhd
--! @brief testbench for the instruction memory
--! @author Joao Pedro Selva (jpselva@usp.br)
--! @date 2022-05-22
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity instruction_memory_tb is
end entity;

architecture testbench of instruction_memory_tb is
    constant ADDRESS_SIZE     : natural := 7;
    constant WORD_SIZE        : natural := 8;
    constant INSTRUCTION_SIZE : natural := 32;
    constant FILE_NAME        : string  := "../../tools/fibonacci.dat";
    constant BUSY_TIME        : time    := 100 ns;

    component instruction_memory is
        generic(
            address_size     : natural := 16;
            word_size        : natural := 8;
            instruction_size : natural := 32;
            file_name        : string  := "instruction.dat";
            busy_time        : time    := 100 ns
        );
        port(
            read_address       : in  bit_vector(address_size - 1 downto 0);
            instruction_enable : in  bit;
            instruction        : out bit_vector(instruction_size - 1 downto 0);
            instruction_busy   : out bit
        );
    end component;

    signal read_address_number : natural; 
    signal read_address        : bit_vector(ADDRESS_SIZE-1 downto 0);
    signal instruction_enable  : bit;
    signal instruction         : bit_vector(INSTRUCTION_SIZE-1 downto 0);
    signal instruction_busy    : bit;
begin
    dut: instruction_memory    
        generic map (
            address_size => ADDRESS_SIZE,
            word_size => WORD_SIZE,
            instruction_size => INSTRUCTION_SIZE,
            file_name => FILE_NAME,
            busy_time => BUSY_TIME
        )
        port map (
            read_address => read_address,
            instruction_enable => instruction_enable,
            instruction => instruction,
            instruction_busy => instruction_busy
        );

    read_address <= bit_vector(to_unsigned(read_address_number, ADDRESS_SIZE));

    tb: process is
    begin
        wait for BUSY_TIME;

        -- read at memory[0]
        instruction_enable <= '1';        
        read_address_number <= 0;
        wait until instruction_busy = '1';
        wait until instruction_busy = '0';

        instruction_enable <= '0';        
        assert (instruction = "11010010100000000000001010010011")
            report "read at memory[0] failed" severity error;

        wait for BUSY_TIME; -- wait random amount of time

        -- read at memory[4]
        instruction_enable <= '1';        
        read_address_number <= 4;
        wait until instruction_busy = '1';
        wait until instruction_busy = '0';

        instruction_enable <= '0';        
        assert (instruction = "10001011000111110000001111110001")
            report "read at memory[0] failed" severity error;

        wait;
    end process tb;
end architecture;
