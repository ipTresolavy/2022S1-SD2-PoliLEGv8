-------------------------------------------------------
--! @file counter.vhd
--! @brief clock cycle counter 
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity counter is
    generic (
        length : natural := 64
    );
    port (
        clk     : in bit;
        reset   : in bit; 
        enable  : in bit;
        timeout : out bit
    );
end entity;

architecture struct of counter is
    signal reg_inputs : bit_vector(length downto 0);

    component register_d_bin is
        port (
            D: in bit;
            clock: in bit;
            enable: in bit;
            reset: in bit;
            Q: out bit
        );
    end component; 
begin
    timeout <= reg_inputs(length); -- output of the last register
    reg_inputs(0) <= '1';          -- input of the first register

    GEN_REG: for i in length-1 downto 0 generate
        reg: register_d_bin
        port map (
            D      => reg_inputs(i),
            clock  => clk,
            enable => enable,
            reset  => reset,
            Q      => reg_inputs(i+1)
        );
    end generate GEN_REG;
end architecture;

