-------------------------------------------------------
--! @file data_memory_tb.vhd
--! @brief testbench of the byte-addressable data RAM memory
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-22
-------------------------------------------------------

entity data_memory_tb is
end entity data_memory_tb;

architecture TB of data_memory_tb is

    component data_memory is
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
    end component;

    constant word_size_bytes : natural := 2;
    constant addr_size       : natural := 4;
    constant busy_time       : time    := 2 ns;

    signal address                : bit_vector(addr_size-1 downto 0);
    signal write_data             : bit_vector(word_size_bytes*8-1 downto 0);
    signal mem_enable, mem_write  : bit;
    signal busy                   : bit;
    signal read_data              : bit_vector(word_size_bytes*8-1 downto 0);

begin

    DUT:
    data_memory generic map (word_size_bytes, addr_size, busy_time)
                port map (address, write_data, mem_enable, mem_write, busy, read_data);

    testbench:
    process
    begin

        -- aligned write
        address <= "0000";
        write_data <= "1010101000000000";
        mem_write <= '1';
        mem_enable <= '1';
        wait until busy = '1';
        wait until busy = '0';
        mem_write <= '0';
        mem_enable <= '0';
        wait for busy_time; -- wait random amount of time

        -- unaligned write
        address <= "0001";
        write_data <= "1111111111111111";
        mem_write <= '1';
        mem_enable <= '1';
        wait until busy = '1';
        wait until busy = '0';
        mem_write <= '0';
        mem_enable <= '0';
        wait for busy_time; -- wait random amount of time

        -- aligned read
        address <= "0000";
        mem_enable <= '1';
        wait until busy = '1';
        wait until busy = '0';
        mem_enable <= '0';
        wait for busy_time; -- wait random amount of time

        assert read_data = "1010101011111111"
            report "Error on aligned read" severity error;

        -- aligned read
        address <= "0001";
        mem_enable <= '1';
        wait until busy = '1';
        wait until busy = '0';
        mem_enable <= '0';
        wait for busy_time; -- wait random amount of time

        assert read_data = "1111111111111111"
            report "Error on unaligned read" severity error;

        wait;
    end process testbench;

end architecture TB;
