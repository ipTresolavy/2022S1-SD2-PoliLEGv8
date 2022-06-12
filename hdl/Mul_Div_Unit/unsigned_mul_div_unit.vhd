-------------------------------------------------------
--! @file unsigned_mul_div_unit.vhd
--! @brief unsigned multiplication/division circuit
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity unsigned_mul_div_unit is
    generic (
        word_s : natural := 64
    );
    port (
        fixed_operand     : in bit_vector(word_s-1 downto 0); -- divisor/multiplicand
        shifted_operand   : in bit_vector(word_s-1 downto 0); -- dividend/multiplier
        start, clk, reset : in bit; 
        div               : in bit; 

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

    -- high and low shift register signals
    signal hi_in, hi_out, lo_in, lo_out : bit_vector(word_s-1 downto 0);
    signal hi_sel, lo_sel               : bit_vector(1 downto 0);
    signal hi_serial_r, hi_serial_l     : bit;
    signal lo_serial_r, lo_serial_l     : bit;
    signal hi_clr, lo_clr : bit;

    -- internal alu signals
    signal alu_result    : bit_vector(word_s-1 downto 0);
    signal alu_operand_A : bit_vector(word_s-1 downto 0);
    signal alu_operand_B : bit_vector(word_s-1 downto 0);
    signal c_out, c_in   : bit;

    -- control unit signals
    signal counter_enable, counter_timeout, counter_reset : bit;
    signal state, next_state : state_type;
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

    --ADDER: PFA
    --generic map (word_s)
    --port map (
    --    A_vector => alu_operand_A, 
    --    B_vector => alu_operand_B,
    --    Carry_in => c_in,
    --    S_vector => alu_result,
    --    Carry_out => c_out
    --);

    ADDER: div_mul_adder
    generic map (word_s)
    port map (
        operand_A => alu_operand_A, 
        operand_B => alu_operand_B,
        c_in => c_in,
        result => alu_result,
        c_out => c_out
    );

    COUNT: counter
    generic map (word_s)
    port map (
        clk     => clk,
        reset   => counter_reset,
        enable  => counter_enable,
        timeout => counter_timeout 
    );

    -- results
    result_low <= lo_out;
    result_high <= hi_out;

    -- shift alu result left in div, right in mul 
    hi_in <= alu_result(word_s-1 downto 0) when div = '1' else 
             c_out & alu_result(word_s-1 downto 1);

    alu_operand_A <= hi_out(word_s-2 downto 0) & lo_out(word_s-1) when div = '1' else
                     hi_out(word_s-1 downto 0);

    alu_operand_B <= not fixed_operand when div = '1' else -- subtract in division (see c_in)
                     fixed_operand;
    c_in <= div;

     -- initialization only
    lo_in <= shifted_operand;

    -- multiplication (shift right)
    hi_serial_r <= '0';
    lo_serial_r <= hi_out(0) when lo_out(0) = '0' else alu_result(0);

    -- division (shift left)
    hi_serial_l <= lo_out(word_s-1);
    lo_serial_l <= c_out; -- result positive?
    
    TRANSITION: process (clk, reset) is
    begin
        if rising_edge(clk) then
            state <= next_state;
        end if;

        if reset = '1' then
            state <= IDLE;
        end if;
    end process TRANSITION;

    CONTROL: process (state, start, alu_result, lo_out, clk) is
    begin
        lo_sel <= "00"; hi_sel <= "00"; -- don't change high or low registers
        hi_clr <= '0'; lo_clr <= '0';

        case state is
            when IDLE => 
                busy <= '0';
                counter_reset <= counter_timeout; -- reset counter to 0 if necessary

                if (start = '1') then
                    counter_enable <= '1';
                    lo_sel <= "11"; -- write dividend/multiplier to low register
                    hi_clr <= '1';
                    if (div = '1') then
                        next_state <= EXEC_DIV;
                    else
                        next_state <= EXEC_MUL;
                    end if;
                else
                    counter_enable <= '0';
                    next_state <= IDLE;
                end if;

            when EXEC_DIV => 
                busy <= '1';
                hi_sel <= '1' & c_out; -- write if not negative
                lo_sel <= "10"; -- shift left always
                counter_enable <= '1';

                if (counter_timeout = '1') then
                    next_state <= IDLE;
                end if;

            when EXEC_MUL => 
                busy <= '1';
                hi_sel <= lo_out(0) & '1'; -- write if multiplier[0] is 1
                lo_sel <= "01"; -- shift right always
                counter_enable <= '1';

                if (counter_timeout = '1') then
                    next_state <= IDLE;
                end if;
        end case;
    end process CONTROL; 
end architecture;
