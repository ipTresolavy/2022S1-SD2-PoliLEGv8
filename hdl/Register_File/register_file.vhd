-------------------------------------------------------
--! @file register_file.vhd
--! @brief implementação do banco de registradores do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-15
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;
use IEEE.math_real.all;

entity register_file is
    generic(
        amount_of_regs : natural := 32; -- including XZR
        register_width : natural := 64; -- amount of bits in each register
        reg_reset_value: natural := 0
    );
    port(
        clock                   : in  bit;
        reset                   : in  bit;
        read_reg_a              : in  bit_vector(integer(log2(real(amount_of_regs))))-1 downto 0);
        read_reg_b              : in  bit_vector(integer(log2(real(amount_of_regs))))-1 downto 0);
        write_reg               : in  bit_vector(integer(log2(real(amount_of_regs))))-1 downto 0);
        write_data              : in  bit_vector(register_width-1 downto 0);
        write_enable            : in  bit;

        reg_a_data              : out bit_vector(register_width-1 downto 0);
        reg_b_data              : out bit_vector(register_width-1 downto 0)
    );
end entity register_file;

architecture register_file_operation of register_file is

    component register_d is
        generic (
            size: natural := 8;
            reset_value: natural := 0
        );
        port (
            D: in bit_vector(size - 1 downto 0);
            clock: in bit;
            enable: in bit;
            reset: in bit;
            Q: out bit_vector(size - 1 downto 0)
        );
    end component register_d;

    type reg_mux is array (amount_of_regs - 2 downto 0) of bit_vector(register_width-1 downto 0); -- excluding XZR

    signal reg_mux_out : reg_mux;
    signal reg_write_enable   : bit_vector(amount_of_regs - 2 downto 0); -- decoder of enables


    begin

        regs_wiring:
        for i in amount_of_regs-2 downto 0 generate
            reg: register_d generic map (register_width, reg_reset_value) port map(write_data, clock, reg_write_enable(i), reset, reg_mux_out(i));
        end generate regs_wiring;

        reg_a_data <= (others => '0') when (signed(read_reg_a) = to_signed(-1, read_reg_a'length)) else -- XZR
                      reg_mux_out(to_integer(unsigned(read_reg_a)));

        reg_b_data <= (others => '0') when (signed(read_reg_b) = to_signed(-1, read_reg_b'length)) else -- XZR
                      reg_mux_out(to_integer(unsigned(read_reg_b)));

        with write_enable select
            reg_write_enable <= (others => '0') when '0', -- doesn't enable any register
                                bit_vector(to_unsigned(1, reg_write_enable'length)) sll to_integer(unsigned(write_reg)) when others; -- maps address to correspondent register enable

end architecture register_file_operation;
