-------------------------------------------------------
--! @file register_file_tb.vhd
--! @brief Testbench do banco de registradores do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-06-25
-------------------------------------------------------
library ieee;
use ieee.math_real.all;
use ieee.numeric_bit.all;

entity register_file_tb is
end entity register_file_tb;

architecture TB of register_file_tb is

    component register_file is
        generic(
            amount_of_regs : natural := 10; -- including XZR
            register_width : natural := 64; -- amount of bits in each register
            reg_reset_value: natural := 0
        );
        port(
            clock                   : in  bit;
            reset                   : in  bit;
            read_reg_a              : in  bit_vector(natural(ceil(log2(real(amount_of_regs)))) -1 downto 0);
            read_reg_b              : in  bit_vector(natural(ceil(log2(real(amount_of_regs)))) -1 downto 0);
            write_reg               : in  bit_vector(natural(ceil(log2(real(amount_of_regs)))) -1 downto 0);
            write_data              : in  bit_vector(register_width-1 downto 0);
            write_enable            : in  bit;

            reg_a_data              : out bit_vector(register_width-1 downto 0);
            reg_b_data              : out bit_vector(register_width-1 downto 0)
        );
    end component register_file;

    constant amount_of_regs : natural := 32;
    constant register_width : natural := 64;
    constant reg_reset_value: natural := 0;

    signal clock                   : bit;
    signal reset                   : bit;
    signal read_reg_a              : bit_vector(natural(ceil(log2(real(amount_of_regs)))) -1 downto 0);
    signal read_reg_b              : bit_vector(natural(ceil(log2(real(amount_of_regs)))) -1 downto 0);
    signal write_reg               : bit_vector(natural(ceil(log2(real(amount_of_regs)))) -1 downto 0);
    signal write_data              : bit_vector(register_width-1 downto 0);
    signal write_enable            : bit;
    signal reg_a_data              : bit_vector(register_width-1 downto 0);
    signal reg_b_data              : bit_vector(register_width-1 downto 0);

    -- tb signals
    constant clk_period : time := 50 ps;
    signal clk : bit := '1';
    signal clk_enable : bit := '0';

begin

    DUT: register_file
    generic map (amount_of_regs, register_width, reg_reset_value)
    port map (clock, reset, read_reg_a, read_reg_b, write_reg, write_data, write_enable, reg_a_data, reg_b_data);

    -- Clock generation
    clk <= not clk after clk_period/2 when clk_enable = '1';

    stimuli: process is
        procedure reset_test_signals is
            read_reg_a <= (others => '0');
            read_reg_b <= (others => '0');
            write_reg <= (others => '0');
            write_data <= (others => '0');
            write_enable <= '0';
            reg_a_data <= (others => '0');
            reg_b_data <= (others => '0');
        end procedure;

    begin
        clk_enable <= '1';

        read_reg_a <= "11111";
        wait until rising_edge(clk);
        assert reg_a_data = x"0000000000000000" report "XZR is not zero!"
            severity error;

        reset_test_signals;

        write_reg <= "11111";
        write_data <= x"0000000000000001";
        write_register_enable <= '1';
        wait until rising_edge(clk);

        -- TODO: Read XZR

        assert reg_b_data = x"0000000000000001" report "XZR was written!"
            severity error;

        reset_test_signals;
        wait;
    end process;

end architecture TB;
