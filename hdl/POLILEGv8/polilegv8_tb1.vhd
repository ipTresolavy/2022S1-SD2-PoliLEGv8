-------------------------------------------------------
--! @file polilegv8_tb1.vhd
--! @brief testbench for the polilegv8 control unit 
--! @author Joao Pedro Selva (jpselva@usp.br)
--! @date 2022-05-21
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;
use std.textio.all;

entity polilegv8_tb is
end polilegv8_tb;

architecture testbench of polilegv8_tb is
    constant WORD_SIZE : natural := 64;
    constant DATA_MEMORY_SIZE : natural := 1024;
    constant INSTRUCTION_MEMORY_SIZE : natural := 128;
    constant DATA_MEMORY_IMAGE_PATH : string := "../../tools/data_memory_arquivo.dat";
    constant INSTRUCTION_MEMORY_IMAGE_PATH : string := "../../tools/print-decimal.dat";
    constant CLOCK_PERIOD : time := 100 ns;

    pure function bv_to_string(vec : bit_vector) return string is
        variable str : string(vec'length-1 downto 0);
    begin
        for k in vec'range loop
            str(k) := bit'image(vec(k))(2);
        end loop;
        return str;
    end function;

    component polilegv8
        generic(
            word_size: natural := 64;
            data_memory_size: natural := 1024;
            instruction_memory_size: natural := 128;
            reg_reset_value: natural := 0
        );
        port (
            clock                    : in bit;
            reset                    : in bit;
            data_mem_enable          : out bit;
            data_mem_write_en        : out bit;
            data_mem_busy            : in bit;
            data_memory_address      : out bit_vector (integer(ceil(log2(real(data_memory_size)))) - 1 downto 0);
            read_data                : in bit_vector (word_size - 1 downto 0);
            write_data               : out bit_vector (word_size - 1 downto 0);
            instruction_mem_enable   : out bit;
            instruction_mem_busy     : in bit;
            instruction_read_address : out bit_vector (integer(ceil(log2(real(instruction_memory_size)))) - 1 downto 0);
            instruction              : in bit_vector (31 downto 0));
    end component;

    component data_memory is
        generic (
            word_size_bytes : natural := 8;
            addr_size       : natural := 16;
            busy_time       : time    := 100 ns;
            data_file_name  : string  := "mem.dat"
        );
        port (
            address                  : in  bit_vector(addr_size-1 downto 0);
            write_data               : in  bit_vector(word_size_bytes*8-1 downto 0);
            mem_enable, mem_write    : in  bit;
            busy                     : out bit;
            read_data                : out bit_vector(word_size_bytes*8-1 downto 0)
        );
    end component;

    component instruction_memory is
        generic(
            address_size     : natural := 16;
            word_size        : natural := 8;
            instruction_size : natural := 32;
            file_name        : string  := "instruction.dat";
            busy_time        : time    := 1000 ns
        );
        port(
            read_address       : in  bit_vector(address_size - 1 downto 0);
            instruction_enable : in  bit;
            instruction        : out bit_vector(instruction_size - 1 downto 0);
            instruction_busy   : out bit
        );
    end component;

    -- data memory signals
    signal data_mem_enable : bit;
    signal data_mem_busy   : bit;

    -- DUT signals
    signal reset                    : bit;
    signal data_mem_enable_dut      : bit;
    signal data_mem_write_en        : bit;
    signal data_mem_busy_dut        : bit;
    signal data_memory_address      : bit_vector (integer(ceil(log2(real(data_memory_size)))) - 1 downto 0);
    signal read_data                : bit_vector (word_size - 1 downto 0);
    signal write_data               : bit_vector (word_size - 1 downto 0);
    signal instruction_mem_enable   : bit;
    signal instruction_mem_busy     : bit;
    signal instruction_read_address : bit_vector (integer(ceil(log2(real(instruction_memory_size)))) - 1 downto 0);
    signal instruction              : bit_vector (31 downto 0);

    -- tb signals
    signal testbench_io_busy : bit;
    signal testbench_io_enable : bit;
    signal clock : bit := '0';
    signal tb_clock_ticking : bit := '1';
begin
    data_mem: data_memory
    generic map (
        word_size_bytes => WORD_SIZE/8,
        addr_size => integer(ceil(log2(real(DATA_MEMORY_SIZE)))),
        busy_time => 500 ns,
        data_file_name => DATA_MEMORY_IMAGE_PATH
    )
    port map (
        address => data_memory_address,
        write_data => write_data,
        mem_enable => data_mem_enable,
        mem_write => data_mem_write_en,
        busy => data_mem_busy,
        read_data => read_data
    );

    instruction_mem: instruction_memory    
    generic map (
        address_size => integer(ceil(log2(real(INSTRUCTION_MEMORY_SIZE)))),
        word_size => 8,
        instruction_size => 32,
        file_name => INSTRUCTION_MEMORY_IMAGE_PATH,
        busy_time => 200 ns
    )
    port map (
        read_address => instruction_read_address,
        instruction_enable => instruction_mem_enable,
        instruction => instruction,
        instruction_busy => instruction_mem_busy
    );

    dut: polilegv8
    generic map (
        word_size => WORD_SIZE,
        data_memory_size => DATA_MEMORY_SIZE,
        instruction_memory_size => INSTRUCTION_MEMORY_SIZE,
        reg_reset_value => 0
    )
    port map (
        clock                    => clock,
        reset                    => reset,
        data_mem_enable          => data_mem_enable_dut,
        data_mem_write_en        => data_mem_write_en,
        data_mem_busy            => data_mem_busy_dut,
        data_memory_address      => data_memory_address,
        read_data                => read_data,
        write_data               => write_data,
        instruction_mem_enable   => instruction_mem_enable,
        instruction_mem_busy     => instruction_mem_busy,
        instruction_read_address => instruction_read_address,
        instruction              => instruction
    );

    clock <= not clock after clock_period/2 when tb_clock_ticking = '1';

    -- address 0x3FE is reserved for writing to screen,
    -- and writing to 0x3FF stops the testbench
    data_mem_enable <= data_mem_enable_dut when 
        data_memory_address(9 downto 1) /= "111111111" else '0';
    testbench_io_enable <= data_mem_enable_dut when 
        data_memory_address(9 downto 1) = "111111111" else '0';

    data_mem_busy_dut <= data_mem_busy or testbench_io_busy;
        
    tb_io: process is
    begin 
        if (testbench_io_enable = '1') then
            testbench_io_busy <= '1';
                wait for 200 ns;

            if (data_mem_write_en = '1') then
                if ("00"&data_memory_address = x"3FE") then -- write to screen
                    --report bv_to_string(write_data) severity note;
                    report integer'image(to_integer(unsigned(write_data))) severity note;
                else -- terminate simulation
                    tb_clock_ticking <= '0';
                    report "sim should end now!" severity note;
                end if;
            end if;
            testbench_io_busy <= '0';
        end if;
        wait on testbench_io_enable;
    end process tb_io;

    stimulus: process is
    begin
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        wait;
    end process stimulus;
end architecture testbench;
