-------------------------------------------------------
--! @file mul_div_unit.vhd
--! @brief multiplication/division circuit
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity div_mul_adder is
    generic (
        word_s : natural := 64
    );
    port (
        operand_A, operand_B : in bit_vector(word_s-1 downto 0);
        c_out  : out bit;
        c_in   : in bit;
        result : out bit_vector(word_s-1 downto 0)
    );
end entity;

architecture behav of div_mul_adder is
    signal temp : bit_vector(word_s downto 0);
begin
    temp <= bit_vector(unsigned("0"&operand_A) + unsigned("0"&operand_B)) when c_in = '0' else
            bit_vector(unsigned("0"&operand_A) + unsigned("0"&operand_B) + to_unsigned(1, word_s));

    result <= temp(word_s-1 downto 0);
    c_out <= temp(word_s);
end architecture;

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
    type reg_inputs_type is array (length-1 downto 0) of bit_vector(0 downto 0);
    signal reg_inputs : reg_inputs_type;

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
begin
    timeout <= reg_inputs(0)(0); -- output of the last register

    GEN_REG: for i in length-1 downto 0 generate
        GEN_FIRST: if i = 0 generate
            reg: register_d
            generic map (1, 1) -- resets to 1
            port map (
               D => reg_inputs(i),
               clock => clk, 
               enable => enable,
               reset => reset,
               Q => reg_inputs((i + 1) mod length)
           );
        end generate GEN_FIRST;

        GEN_OTHERS: if i /= 0 generate
            reg: register_d
            generic map (1, 0)
            port map (
               D => reg_inputs(i),
               clock => clk, 
               enable => enable,
               reset => reset,
               Q => reg_inputs((i + 1) mod length)
           );
        end generate GEN_OTHERS;
    end generate GEN_REG;
end architecture;

entity unsigned_mul_div_unit is
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
    signal hi_sr, lo_sr, hi_sl, low_sl  : bit;
    signal hi_serial_r, hi_serial_l     : bit;
    signal lo_serial_r, lo_serial_l     : bit;
    signal hi_clr, lo_clr : bit;

    -- internal alu signals
    signal alu_result    : bit_vector(word_s-1 downto 0);
    signal alu_operand_A : bit_vector(word_s-1 downto 0);
    signal alu_operand_B : bit_vector(word_s-1 downto 0);
    signal c_out, c_in   : bit;

    -- control unit signals
    signal counter_enable, counter_timeout : bit;
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
        reset   => reset,
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
                counter_enable <= '0';
                if (start = '1') then
                    lo_sel <= "11"; -- write dividend/multiplier to low register
                    hi_clr <= '1';
                    if (div = '1') then
                        next_state <= EXEC_DIV;
                    else
                        next_state <= EXEC_MUL;
                    end if;
                else
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
    signal hi_reg_enable, lo_reg_enable : bit;
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
