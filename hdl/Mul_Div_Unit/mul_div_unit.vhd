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

architecture struct of mul_div_unit is
    constant ZERO : bit_vector(word_s-1 downto 0) := (others => '0');
    type state_type is (IDLE, EXEC);

    component div_mul_adder is
        generic (
            word_s : natural
        );
        port (
            operand_A, operand_B : in bit_vector(word_s-1 downto 0);
            c_in   : in bit;
            c_out  : out bit;
            result : out bit_vector(word_s-1 downto 0)
        );
    end component;

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
    end component;

    component unsigned_mul_div_unit is
        generic (
            word_s : natural := 64
        );
        port (
            fixed_operand     : in bit_vector(word_s-1 downto 0); -- dividend/multiplier
            shifted_operand   : in bit_vector(word_s-1 downto 0); -- divisor/multiplicand
            start, clk, reset : in bit; 
            div               : in bit; 

            busy : out bit;
            result_high : out bit_vector(word_s-1 downto 0);
            result_low  : out bit_vector(word_s-1 downto 0)
        );
    end component;

    -- data flow signals
    signal hi_inv_A, hi_inv_result : bit_vector(word_s-1 downto 0);
    signal lo_inv_A, lo_inv_result : bit_vector(word_s-1 downto 0);
    signal lo_inv_c_out, hi_inv_c_in : bit;
    signal hi_reg_out, lo_reg_out : bit_vector(word_s-1 downto 0);
    signal hi_reg_in, lo_reg_in : bit_vector(word_s-1 downto 0);
    signal fixed_operand, shifted_operand, 
           result_high_normal, result_low_normal : bit_vector(word_s-1 downto 0);
    signal mul_div_enable, mul_div_busy : bit;

    -- control unit signals
    signal current_state, next_state : state_type;
    signal mul_div_finished : bit;
begin
    hi_inv: div_mul_adder
    generic map (word_s)
    port map (
        operand_A => hi_inv_A,
        operand_B => ZERO, 
        c_in => hi_inv_c_in,
        c_out => open,
        result => hi_inv_result
    );  

    lo_inv: div_mul_adder
    generic map (word_s)
    port map (
        operand_A => lo_inv_A,
        operand_B => ZERO, 
        c_in => '1',
        c_out => lo_inv_c_out,
        result => lo_inv_result
    );  

    hi_reg: register_d     
    generic map (word_s, 0)
    port map (
        D => hi_reg_in,
        clock => clk,
        enable => mul_div_finished,
        reset => reset,
        Q => hi_reg_out
    );

    lo_reg: register_d     
    generic map (word_s, 0)
    port map (
        D => lo_reg_in,
        clock => clk,
        enable => mul_div_finished,
        reset => reset,
        Q => lo_reg_out
    );

    mul_div: unsigned_mul_div_unit
    generic map (word_s)
    port map (
        fixed_operand => fixed_operand,
        shifted_operand => shifted_operand,
        start => enable,
        clk => clk,
        reset => reset,
        div => div,
        busy => mul_div_busy,
        result_high => result_high_normal,
        result_low => result_low_normal
    );

    -- data flow connections
    shifted_operand <= lo_inv_result when operand_A(word_s-1) = '1' and unsgn = '0'
                       else operand_A;
    fixed_operand <= hi_inv_result when operand_B(word_s-1) = '1' and unsgn = '0'
                     else operand_B;
    lo_inv_A <= not operand_A when mul_div_finished = '0' else not result_low_normal;
    hi_inv_A <= not operand_B when mul_div_finished = '0' else not result_high_normal;
    hi_inv_c_in <= lo_inv_c_out when mul_div_finished = '1' and div = '0' else '1';
    lo_reg_in <= lo_inv_result when unsgn = '0' and (operand_A(word_s-1) XOR operand_B(word_s-1)) = '1'
                 else result_low_normal;
    hi_reg_in <= hi_inv_result when unsgn = '0' and (operand_A(word_s-1) XOR operand_B(word_s-1)) = '1'
                 else result_high_normal;

    result_high <= hi_reg_out;
    result_low <= lo_reg_out;

    -- control unit 
    transition: process (clk, reset) is
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;

        if reset = '1' then
            current_state <= IDLE;
        end if;
    end process;

    fsm: process (current_state, enable, mul_div_busy) is
    begin
        case current_state is
            when IDLE =>
                mul_div_finished <= '0'; 
                busy <= '0';
                if (enable = '1') then
                    next_state <= EXEC;
                else
                    next_state <= IDLE;
                end if;

            when EXEC =>
                mul_div_finished <= not mul_div_busy; 
                busy <= '1';
                if (mul_div_busy = '0') then
                    next_state <= IDLE;
                else
                    next_state <= EXEC;
                end if;
        end case;
    end process;
end architecture;
