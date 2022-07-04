-------------------------------------------------------
--! @file mul_div_unit.vhd
--! @brief signed/unsigned multiplication/division circuit
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity mul_div_unit is
    generic (
        word_s : natural
    );
    port (
        operand_A, operand_B : in bit_vector(word_s-1 downto 0);
        enable, reset, clk : bit;
        div : in bit;   -- div = 1 if division
        unsgn : in bit; -- unsgn = 1 if unsigned operation
        busy : out bit;
        result_high, result_low : out bit_vector(word_s-1 downto 0)
    );
end entity;

architecture full of mul_div_unit is
   component mul_div_control is
        generic (
            word_s : natural
        );
        port (
            enable, reset, clk : in bit;
            div   : in bit;   -- div = 1 if division
            sgn   : in bit;   -- sgn = 1 if unsigned operation
            busy  : out bit;
            A_msb : in bit;
            B_msb : in bit; 
            lo_lsb : in bit;          -- lsb of the low register (for mul)
            adder_carry_out : in bit; -- carry out of the main adder (for div)
            adder_A_src      : out bit;
            sub              : out bit;
            inv_src          : out bit;
            write_lo_src     : out bit;
            sel_lo, sel_hi   : out bit_vector(1 downto 0);
            write_hi_src     : out bit;
            clr_hi, clr_lo   : out bit; 
            arit_shift_right : out bit
        ); 
    end component;

    component mul_div_dataflow is
        generic (
            word_s : natural := 64
        );
        port (
            A, B : in bit_vector(word_s-1 downto 0);
            clk  : in bit;
            adder_A_src : in bit;
            sub         : in bit;
            inv_src : in bit;
            write_lo_src : in bit;
            sel_lo       : in bit_vector(1 downto 0);
            clr_lo       : in bit;
            write_hi_src     : in bit;
            sel_hi           : in bit_vector(1 downto 0);
            clr_hi           : in bit;
            arit_shift_right : in bit;
            adder_carry_out : out bit;
            result_high, result_low : out bit_vector(word_s-1 downto 0)
        );
    end component;

    signal adder_A_src : bit;
    signal sub         : bit;
    signal inv_src : bit;
    signal write_lo_src : bit;
    signal sel_lo       : bit_vector(1 downto 0);
    signal clr_lo       : bit;
    signal write_hi_src     : bit;
    signal sel_hi           : bit_vector(1 downto 0);
    signal clr_hi           : bit;
    signal arit_shift_right : bit;
    signal adder_carry_out : bit;
    signal result_high_i, result_low_i : bit_vector(word_s-1 downto 0);
    signal sgn : bit;
    signal A_msb, B_msb, lo_lsb : bit;
begin
    CONTROL_UNIT: mul_div_control
    generic map (word_s)
    port map (
        enable => enable, 
        reset => reset, 
        clk => clk,
        div => div,
        sgn => sgn,
        busy => busy,
        A_msb => A_msb,
        B_msb => B_msb,
        lo_lsb => lo_lsb,
        adder_carry_out => adder_carry_out,
        adder_A_src => adder_A_src,
        sub => sub,
        inv_src => inv_src,
        write_lo_src => write_lo_src,
        sel_lo => sel_lo, 
        sel_hi => sel_hi,
        write_hi_src => write_hi_src,
        clr_hi => clr_hi, 
        clr_lo => clr_lo,
        arit_shift_right => arit_shift_right
    );

    DATAFLOW: mul_div_dataflow
    generic map (word_s)
    port map (
        A => operand_A, 
        B => operand_B, 
        clk => clk,
        adder_A_src => adder_A_src,
        sub => sub,
        inv_src => inv_src,
        write_lo_src => write_lo_src,
        sel_lo => sel_lo,
        clr_lo => clr_lo,
        write_hi_src => write_hi_src,
        sel_hi => sel_hi,
        clr_hi => clr_hi,
        arit_shift_right => arit_shift_right,
        adder_carry_out => adder_carry_out,
        result_high => result_high_i,
        result_low => result_low_i
    );

    sgn <= not unsgn;
    A_msb <= operand_A(word_s-1);
    B_msb <= operand_B(word_s-1);
    lo_lsb <= result_low_i(0);
    result_high <= result_high_i;
    result_low <= result_low_i;
end architecture;
