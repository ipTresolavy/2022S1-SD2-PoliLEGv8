-------------------------------------------------------
--! @file register_file.vhd
--! @brief implementação do banco de registradores do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-15
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;

entity register_file is
    port(
        clock                   : in  bit;
        read_reg_a              : in  bit_vector(4 downto 0);
        read_reg_b              : in  bit_vector(4 downto 0);
        write_reg               : in  bit_vector(4 downto 0);
        write_data              : in  bit_vector(63 downto 0);
        write                   : in  bit;

        reg_a_data              : out bit_vector(63 downto 0);
        reg_b_data              : out bit_vector(63 downto 0)
    );
end entity register_file;

architecture register_file_operation of register_file is

    component d_register is
        generic(
            width: natural := 4
        );
        port(
            clock, load : in bit;
            d           : in bit_vector(width-1 downto 0);
            q           : out bit_vector(width-1 downto 0)
        );
    end component d_register;

    type reg_mux is array (30 downto 0) of bit_vector(63 downto 0);

    signal reg_mux_out : reg_mux;
    signal reg_write   : bit_vector(30 downto 0);


    begin

        regs_wiring:
        for i in 30 downto 0 generate
            reg: d_register generic map (64) port map(clock, reg_write(i), write_data, reg_mux_out(i));
        end generate regs_wiring;

        with read_reg_a select
            reg_a_data <= (others => '0') when "11111",
                          reg_mux_out(to_integer(unsigned(read_reg_a))) when others;

        with read_reg_b select
            reg_b_data <= (others => '0') when "11111",
                          reg_mux_out(to_integer(unsigned(read_reg_b))) when others;

        with write select
            reg_write <= (others => '0') when '0',
                         bit_vector(to_unsigned(1, reg_write'length)) sll to_integer(unsigned(write_reg)) when others;

end architecture register_file_operation;
