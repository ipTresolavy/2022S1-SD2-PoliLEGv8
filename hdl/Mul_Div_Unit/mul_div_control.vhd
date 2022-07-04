-------------------------------------------------------
--! @file mul_div_dataflow.vhd
--! @brief signed/unsigned multiplication/division control unit
--! @author Joao Pedro Selva Bernardino
--! @date 2022-05-28
-------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity mul_div_control is
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
end entity;

architecture fsm of mul_div_control is
    type state_type is (IDLE, EXEC_MUL, EXEC_DIV, INV_LO, HOLD);

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

    -- counter signals
    signal cnt_reset, cnt_enable, cnt_timeout : bit;
    signal cnt_reset_internal : bit;

    -- fsm signals
    signal state, next_state : state_type;
begin
    COUNT: counter
    generic map (word_s)
    port map (
        clk     => clk,
        reset   => cnt_reset,
        enable  => cnt_enable,
        timeout => cnt_timeout 
    );

    cnt_reset <= reset OR cnt_reset_internal;

    TRANSITION: process (clk, reset) is
    begin
        if rising_edge(clk) then
            state <= next_state;
        end if;

        if reset = '1' then
            state <= IDLE;
        end if;
    end process TRANSITION;

    CONTROL: process (state, enable, cnt_timeout, div, sgn, lo_lsb, adder_carry_out, clk) is
        procedure reset_control_signals is
        begin
            adder_A_src <= '0';
            sub <= '0';
            inv_src <= '0';
            write_lo_src <= '0';
            sel_lo <= "00";
            sel_hi <= "00";
            write_hi_src <= '0';
            clr_hi <= '0';
            clr_lo <= '0';
            arit_shift_right <= '0';
            cnt_enable <= '0';
            cnt_reset_internal <= '0';
        end procedure;
    begin
        reset_control_signals;

        case state is
            when IDLE => 
                cnt_reset_internal <= cnt_timeout;                
                cnt_enable <= enable;
                sel_lo <= enable&enable;
                clr_hi <= enable;
                write_lo_src <= A_msb and sgn and div; -- A negative and signed div
                busy <= '0';

                if (enable = '1') then
                    if (div = '1') then
                        next_state <= EXEC_DIV;
                    else
                        next_state <= EXEC_MUL;
                    end if;
                else 
                    next_state <= IDLE;
                end if;

            when EXEC_MUL => 
                sel_hi <= lo_lsb & "1";
                sel_lo <= "01";
                arit_shift_right <= sgn;
                sub <= sgn and cnt_timeout; -- last bit has negative weight in 2's complement
                cnt_enable <= '1';
                busy <= '1';
                
                if (cnt_timeout = '1') then
                    next_state <= HOLD;
                else
                    next_state <= EXEC_MUL;
                end if;

            when EXEC_DIV => 
                sel_hi <= "1" & adder_carry_out;
                sel_lo <= "10";
                adder_A_src <= '1';
                write_hi_src <= '1';
                sub <= not (B_msb and sgn);
                cnt_enable <= '1';
                busy <= '1';

                if (cnt_timeout = '1') then
                    if (sgn = '1' and (A_msb xor B_msb) = '1') then
                        next_state <= INV_LO; -- invert quotient sign
                    else
                        next_state <= HOLD;
                    end if;
                else
                    next_state <= EXEC_DIV;
                end if;

            when INV_LO =>
                sel_lo <= "11";
                inv_src <= '1';
                write_lo_src <= '1';
                busy <= '1';
                next_state <= HOLD;

            when HOLD =>
                busy <= '1';
                next_state <= IDLE;

        end case;
    end process CONTROL; 
end architecture;
