-------------------------------------------------------
--! @file data_memory_tb.vhd
--! @brief testbench da memória RAM do Polilegv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-30
-------------------------------------------------------
library IEEE;
use ieee.numeric_bit.all;
use ieee.math_real.all;

entity data_memory_tb is
end entity data_memory_tb;

architecture TB of data_memory_tb is

    component data_memory is
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
    end component;

    constant word_size_bytes : natural := 8; -- tamanho da palavra armazenada em cada endereço da memória RAM
    constant addr_size       : natural := 10; -- memória tem 2^10 = 1024 endereços
    constant busy_time       : time    := 2 ns;
    constant data_file_name  : string  := "../../tools/data_memory_arquivo.dat"; -- random file, only for testing

    signal address                : bit_vector(addr_size-1 downto 0);
    signal write_data             : bit_vector(word_size_bytes*8-1 downto 0);
    signal mem_enable, mem_write  : bit;
    signal busy                   : bit;
    signal read_data              : bit_vector(word_size_bytes*8-1 downto 0);

    impure function rand_time(min_val, max_val : time; unit : time := ns)
      return time is
      variable r, r_scaled, min_real, max_real : real;
      variable seed1, seed2 : positive;
    begin
      seed1 := 8#777#;
      seed2 := 16#FADA#;
      uniform(seed1, seed2, r);
      min_real := real(min_val / unit);
      max_real := real(max_val / unit);
      r_scaled := r * (max_real - min_real) + min_real;
      return real(r_scaled) * unit;
    end function;

begin

    DUT:
    data_memory generic map (word_size_bytes, addr_size, busy_time, data_file_name)
                port map (address, write_data, mem_enable, mem_write, busy, read_data);

    testbench:
    process
    begin
        -- leitura alinhada
        address <= "0000000000";
        mem_write <= '0';
        mem_enable <= '1';
        wait until busy = '1';
        wait until busy ='0';
        mem_enable <= '0';
        assert read_data = x"40FD98AF9820B538"
            report "Erro na leitura alinhada" severity error;
        wait for rand_time(0 ns, busy_time, ns); -- espera uma quantidade aleatória de tempo entre 0 e busy_time ns

        -- escrita alinhada
        address <= "1111111100";
        write_data <= x"AAAAAAAAAAAAAAAA";
        mem_write <= '1';
        mem_enable <= '1';
        wait until busy = '1';
        wait until busy = '0';
        mem_write <= '0';
        mem_enable <= '0';
        wait for rand_time(0 ns, busy_time, ns); -- espera uma quantidade aleatória de tempo entre 0 e busy_time ns

        -- leitura no endereço escrito
        address <= "1111111100";
        mem_enable <= '1';
        wait until busy = '1';
        wait until busy = '0';
        mem_enable <= '0';
        assert read_data = x"AAAAAAAAAAAAAAAA"
            report "Error on aligned read" severity error;
        wait for rand_time(0 ns, busy_time, ns); -- espera uma quantidade aleatória de tempo entre 0 e busy_time ns

        wait;
    end process testbench;

end architecture TB;
