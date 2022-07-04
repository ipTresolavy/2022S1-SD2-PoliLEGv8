-------------------------------------------------------
--! @file mul_div_dataflow.vhd
--! @brief signed/unsigned multiplication/division dataflow
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity mul_div_dataflow is
    generic (
        word_s : natural := 64
    );
    port (
        -- A = dividend/multiplier, B = divisor/multiplicand
        A, B : in bit_vector(word_s-1 downto 0);
        clk  : in bit;

        -- main adder control
        adder_A_src : in bit;
        sub         : in bit;

        -- sign inverter control
        inv_src : in bit;

        -- low shift register control
        write_lo_src : in bit;
        sel_lo       : in bit_vector(1 downto 0);
        clr_lo       : in bit;

        -- high shift register control
        write_hi_src     : in bit;
        sel_hi           : in bit_vector(1 downto 0);
        clr_hi           : in bit;
        arit_shift_right : in bit;

        -- outputs
        adder_carry_out : out bit;
        result_high, result_low : out bit_vector(word_s-1 downto 0)
    );
end entity;

architecture struct of mul_div_dataflow is
    constant ZERO : bit_vector(word_s-1 downto 0) := (others => '0');

    component shift_register is
        generic (
            word_s : natural
        );
        port (
            write_word    : in bit_vector(word_s-1 downto 0);
            right_serial  : in bit;  
            left_serial   : in bit;  
            clear         : in bit; 
            clk           : in bit;
            selector      : in bit_vector(1 downto 0); 
            read_word     : out bit_vector(word_s-1 downto 0)
        );
    end component;

    component counter is
        generic (
            length : natural
        );
        port (
            clk     : in bit;
            reset   : in bit; 
            enable  : in bit;
            timeout : out bit
        );
    end component;

    component PFA is
        generic(
            size: natural := 4
        );
        port(
            A_vector: in bit_vector(size - 1 downto 0);
            B_vector: in bit_vector(size - 1 downto 0);
            Carry_in: in bit;
            S_vector: out bit_vector(size - 1 downto 0);
            Carry_out: out bit
        );
    end component; 

    -- high register signals
    signal write_hi_msb : bit;
    signal write_hi, read_hi : bit_vector(word_s-1 downto 0);
    signal hi_serial_r, hi_serial_l : bit;

    -- lo register signals
    signal write_lo, read_lo : bit_vector(word_s-1 downto 0);
    signal lo_serial_r, lo_serial_l  : bit;

    -- main adder signals
    signal adder_A, adder_B, adder_S : bit_vector(word_s-1 downto 0);
    signal carry_out, carry_in : bit;

    -- inverter signals
    signal inv_A, inv_S : bit_vector(word_s-1 downto 0);
begin
    HI_REG: shift_register
    generic map (word_s)
    port map (
        write_word   => write_hi, 
        right_serial => hi_serial_r,
        left_serial  => hi_serial_l,
        clear        => clr_hi,
        clk          => clk,
        selector     => sel_hi,
        read_word    => read_hi
    );

    LO_REG: shift_register
    generic map (word_s)
    port map (
        write_word   => write_lo, 
        right_serial => lo_serial_r,
        left_serial  => lo_serial_l,
        clear        => clr_lo,
        clk          => clk,
        selector     => sel_lo,
        read_word    => read_lo
    );

    ADDER: PFA
    generic map (word_s)
    port map (
        A_vector  => adder_A, 
        B_vector  => adder_B,
        Carry_in  => carry_in,
        S_vector  => adder_S,
        Carry_out => carry_out
    );

    INV: PFA
    generic map (word_s)
    port map (
        A_vector  => inv_A, 
        B_vector  => ZERO,
        Carry_in  => '1',
        S_vector  => inv_S,
        Carry_out => open
    );

    -- hi reg connections
    write_hi_msb <= carry_out when arit_shift_right = '0' else
                    (adder_A(word_s-1) xor adder_B(word_s-1)) xor carry_out; -- sign extended sum
    write_hi <= write_hi_msb & adder_S(word_s-1 downto 1) when write_hi_src = '0' else
                adder_S;
    hi_serial_r <= read_hi(word_s-1) when arit_shift_right = '1' else '0';
    hi_serial_l <= read_lo(word_s-1);
    result_high <= read_hi;

    -- lo reg connections
    write_lo <= A when write_lo_src = '0' else inv_S;
    lo_serial_r <= adder_S(0) when read_lo(0) = '1' else read_hi(0);
    lo_serial_l <= carry_out;
    result_low <= read_lo;
    
    -- main adder connections
    adder_A <= read_hi when adder_A_src = '0' else
               read_hi(word_s-2 downto 0) & read_lo(word_s-1);
    adder_B <= B when sub ='0' else not B;
    carry_in <= sub;
    adder_carry_out <= carry_out;

    -- sign inverter connections
    inv_A <= not A when inv_src = '0' else not read_lo;
end architecture;
