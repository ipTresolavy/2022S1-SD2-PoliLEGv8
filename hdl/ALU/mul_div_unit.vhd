-------------------------------------------------------
--! @file mul_div_unit.vhd
--! @brief multiplication/division circuit
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity div_mul_alu is
    generic (
        word_s : natural := 64
    );
    port (
        operand_A, operand_B : in bit_vector(word_s-1 downto 0);
        op     : in bit;    -- add or sub
        c_out  : out bit;
        result : out bit_vector(word_s-1 downto 0)
    );
end entity;

architecture behav of div_mul_alu is
    signal temp : bit_vector(word_s downto 0);
begin
    temp <= bit_vector(unsigned("0"&operand_A) + unsigned("0"&operand_B)) when op = '0' else
            bit_vector(unsigned("0"&operand_A) - unsigned("0"&operand_B));

    result <= temp(word_s-1 downto 0);
    c_out <= temp(word_s);
end architecture;

entity unsigned_mul_div_unit is
    generic (
        word_s : natural := 64
    );
    port (
        fixed_operand   : in bit_vector(word_s-1 downto 0); -- dividend/multiplier
        shifted_operand : in bit_vector(word_s-1 downto 0); -- divisor/multiplicand
        start, clk      : in bit; 
        div             : in bit; 

        busy : out bit;
        result_high : out bit_vector(word_s-1 downto 0);
        result_low  : out bit_vector(word_s-1 downto 0)
    );
end entity unsigned_mul_div_unit;

architecture struct of unsigned_mul_div_unit is
    type state_type is (IDLE, EXEC_DIV, EXEC_MUL);

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

    component div_mul_alu is
        generic (
            word_s : natural
        );
        port (
            operand_A, operand_B : in bit_vector(word_s-1 downto 0);
            op     : in bit;
            c_out  : out bit;
            result : out bit_vector(word_s-1 downto 0)
        );
    end component;

    -- high and low shift register signals
    signal hi_in, hi_out, lo_in, lo_out : bit_vector(word_s-1 downto 0);
    signal hi_sel, lo_sel               : bit_vector(1 downto 0);
    signal hi_sr, lo_sr, hi_sl, low_sl  : bit;
    signal hi_serial_r, hi_serial_l     : bit;
    signal lo_serial_r, lo_serial_l     : bit;
    signal hi_clr, lo_clr : bit;

    -- internal alu signals
    signal alu_result    : bit_vector(word_s-1 downto 0);
    signal alu_operand_A : bit_vector(word_s-1 downto 0);
    signal c_out, alu_op : bit;

    -- control unit signals
    signal state, next_state : state_type;
    signal counter : natural := 0;
    signal reset_counter : bit;
begin
    HI_REG: shift_register
    generic map (word_s)
    port map (
        write_word   => hi_in, 
        right_serial => hi_serial_r,
        left_serial  => hi_serial_l,
        clear        => hi_clr,
        clk          => clk,
        selector     => hi_sel,
        read_word    => hi_out
    );

    LO_REG: shift_register
    generic map (word_s)
    port map (
        write_word   => lo_in, 
        right_serial => lo_serial_r,
        left_serial  => lo_serial_l,
        clear        => lo_clr,
        clk          => clk,
        selector     => lo_sel,
        read_word    => lo_out
    );

    ALU: div_mul_alu
    generic map (word_s)
    port map (
        operand_A => alu_operand_A,
        operand_B => fixed_operand,
        op => alu_op,
        c_out => c_out,
        result => alu_result
    );

    -- results
    result_low <= lo_out;
    result_high <= hi_out;

    -- shift alu result left in div, right in mul 
    hi_in <= alu_result(word_s-1 downto 0) when div = '1' else 
             c_out & alu_result(word_s-1 downto 1);

    alu_operand_A <= hi_out(word_s-2 downto 0) & lo_out(word_s-1) when div = '1' else
                     hi_out(word_s-1 downto 0);

     -- initialization only
    lo_in <= shifted_operand;

    -- multiplication (shift right)
    hi_serial_r <= '0';
    lo_serial_r <= hi_out(0) when lo_out(0) = '0' else alu_result(0);

    -- division (shift left)
    hi_serial_l <= lo_out(word_s-1);
    lo_serial_l <= not alu_result(word_s-1); -- result positive?
    
    TRANSITION: process (clk, reset_counter) is
    begin
        if rising_edge(clk) then
            state <= next_state;
            counter <= counter + 1;
        end if;

        if reset_counter = '1' then
            counter <= 0;
        end if;
    end process TRANSITION;

    CONTROL: process (state, start, alu_result, lo_out, counter) is
    begin
        lo_sel <= "00"; hi_sel <= "00"; -- don't change high or low registers
        hi_clr <= '0'; lo_clr <= '0';

        case state is
            when IDLE => 
                busy <= '0';
                if (start = '1') then
                    reset_counter <= '0';
                    lo_sel <= "11"; -- write dividend/multiplier to low register
                    hi_clr <= '1';
                    if (div = '1') then
                        next_state <= EXEC_DIV;
                    else
                        next_state <= EXEC_MUL;
                    end if;
                else
                    reset_counter <= '1';
                    next_state <= IDLE;
                end if;

            when EXEC_DIV => 
                busy <= '1';
                hi_sel <= '1' & not alu_result(word_s-1); -- write if not negative
                lo_sel <= "10"; -- shift left always
                alu_op <= '1'; -- sub

                if (counter = word_s) then
                    next_state <= IDLE;
                end if;

            when EXEC_MUL => 
                busy <= '1';
                hi_sel <= lo_out(0) & '1'; -- write if multiplier[0] is 1
                lo_sel <= "01"; -- shift right always
                alu_op <= '0'; -- add

                if (counter = word_s) then
                    next_state <= IDLE;
                end if;
        end case;
    end process CONTROL; 
end architecture;
