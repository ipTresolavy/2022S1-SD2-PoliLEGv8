-------------------------------------------------------
--! @file shift_register_tb.vhd
--! @brief testbench for the universal shift register
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;

entity shift_register_tb is
end shift_register_tb;

architecture tb of shift_register_tb is
    constant word_s : natural := 8;

    component shift_register
        generic (
            word_s : natural
        ); 
        port (
            write_word   : in bit_vector (word_s-1 downto 0);
            right_serial : in bit;
            left_serial  : in bit;
            clear        : in bit;
            clk          : in bit;
            selector     : in bit_vector (1 downto 0);
            read_word    : out bit_vector (word_s-1 downto 0)
        );
    end component;

    signal write_word   : bit_vector (word_s-1 downto 0);
    signal right_serial : bit;
    signal left_serial  : bit;
    signal clear        : bit;
    signal clk          : bit;
    signal selector     : bit_vector (1 downto 0);
    signal read_word    : bit_vector (word_s-1 downto 0);

    constant clk_period : time := 1000 ns; -- EDIT Put right period here
    signal tb_clk       : bit := '0';
    signal tb_ended     : bit := '0';

begin

    dut : shift_register
    generic map (
        word_s => word_s
    ) 
    port map (
        write_word   => write_word,
        right_serial => right_serial,
        left_serial  => left_serial,
        clear        => clear,
        clk          => clk,
        selector     => selector,
        read_word    => read_word
    );

    -- Clock generation
    tb_clk <= not tb_clk after clk_period/2 when tb_ended /= '1';
    clk <= tb_clk;

    testbench: process
    begin
        clear <= '0';

        -- parallel write attempt
        write_word <= "00010011";
        selector   <= "11";
        wait for clk_period;

        assert (read_word = "00010011")
            report "write failed" severity error;

        -- shift left attempt
        left_serial <= '0';
        selector <= "10";
        wait for clk_period;
        
        assert (read_word = "00100110")
            report "shift left failed" severity error;

        -- shift right attempt
        right_serial <= '1';
        selector <= "01";
        wait for clk_period;

        assert (read_word = "10010011")
            report "shift right failed" severity error;

        -- do nothing attempt
        selector <= "00";
        wait for clk_period;

        assert (read_word = "10010011")
            report "shift left failed" severity error;

        -- clear attempt
        clear <= '1';
        wait for clk_period/100; -- async reset should be instantaneous
        clear <= '0';
        wait for clk_period/100;

        assert (read_word = "00000000")
            report "clear failed" severity error;

        -- Stop the clock and hence terminate the simulation
        tb_ended <= '1';
        wait;
    end process testbench;

end tb;
