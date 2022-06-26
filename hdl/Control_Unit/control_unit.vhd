-------------------------------------------------------
--! @file control_unit.vhd
--! @brief Unidade de controle do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @author Joao Pedro Selva Bernardino (jpselva@usp.br)
--! @date 2022-06-25
-------------------------------------------------------

library ieee;
use ieee.math_real.all;
use ieee.numeric_bit.all;

entity control_unit is
    generic(
        word_size: natural := 64
    );
    port(
        -- Common
        clock: in bit;
        reset: in bit;

        -- From Dataflow
        opcode: in bit_vector(10 downto 0);
        zero: in bit;
        zero_r: in bit;
        carry_out_r: in bit;
        overflow_r: in bit;
        negative_r: in bit;
        stxr_try_in: in bit;

        -- To Dataflow
            -- MOV's signals
        mov_enable: out bit;
            -- ALU's signals
        alu_control: out bit_vector(2 downto 0);
        set_flags: out bit;
        alu_b_src: out bit_vector(1 downto 0);
        	-- mul_div_unit's signals
        mul_div_src: out bit;
        mul_div_busy : in bit;
        mul_div_enable: out bit;
            --ALU_pc's signals
        alu_pc_b_src: out bit;
            -- PC's signals
        pc_src: out bit;
        pc_enable: out bit;
        	-- monitor's signals
        monitor_enable: out bit;

        -- Instruction memory
        instruction_mem_enable : out bit;
        instruction_mem_busy   : in bit;
        -- Data memory
        data_mem_enable : out bit;
        data_mem_write_en : out bit;
        data_mem_busy   : in bit
    );

end entity control_unit;

architecture control_unit_beh of control_unit is

    type state_type is (fetch_decode, stxr_execute, branch_relative);

    signal next_state, current_state : state_type := fetch;
    signal flags_mux_out, cbz, cbnz, uncond_branch : bit;
    signal flags_mux_sel : bit_vector(3 downto 0);
begin
        pc_src <= (b_cond and flags_mux_out) or 
                  (zero and cbz) or 
                  ((not zero) and cbnz) or
                  uncond_branch;

        with flags_mux_sel select flags_mux_out <=
            negative_r when "0000", 
            not negative_r when "0001", 
            overflow_r when "0010", 
            not overflow_r when "0011", 
            zero_r when "0100", 
            not zero_r when "0101", 
            negative_r xor overflow_r when "0110", 
            zero_r or (negative_r xor overflow_r) when "0111", 
            not zero_r and not (negative_r xor overflow_r) when "1000", 
            not (negative_r xor overflow_r) when "1001", 
            zero_r when "1010", 
            not zero_r when "1011", 
            not carry_out_r when "1100", 
            not (not zero_r and carry_out_r) when "1101", 
            not zero_r and carry_out_r when "1110", 
            carry_out_r when "1111";

        change_of_state: process(clock, reset) is
            begin
                if reset = '1' then
                    current_state <= fetch;
                elsif rising_edge(clock) then
                    current_state <= next_state;
                end if;
        end process change_of_state;

        control: process is
            procedure reset_control_signals is
                begin
                mov_enable <= '0';
                alu_control <= "000";
                set_flags <= '0';
                alu_b_src <= "00";
                mul_div_src <= '0';
                mul_div_enable <= '0';
                alu_pc_b_src <= '0';
                pc_src <= '0';
                pc_enable <= '0';
                monitor_enable <= '0';
                instruction_mem_enable <= '0';
                data_mem_enable <= '0';
            end procedure;

            procedure wait_for_data_mem(we:boolean) is
                begin
                data_mem_enable <= '1';

                if we = true then
                    data_mem_write_en <= '1';
                end if;

                wait until data_mem_busy = '1';
                wait until data_mem_busy = '0';
                data_mem_write_en <= '0';
                data_mem_enable <= '0';
            end procedure;

            procedure wait_for_mul_div is
                begin
                mul_div_enable <= '1';
                wait until mul_div_busy = '1';
                mul_div_enable <= '0';
                wait until mul_div_busy = '0';
            end procedure;

            begin
                reset_control_signals;

                case current_state is
                    when fetch =>
                        instruction_mem_enable <= '1';
                        wait until instruction_mem_busy = '1';
                        wait until instruction_mem_busy = '0';
                        instruction_mem_enable <= '0';
                        next_state <= decode_execute;

                        -- colocar BL antes desse
                        if (opcode(10 downto 5) = "000101" or opcode(7 downto 4) = "1010")
                            next_state <= branch_relative;
                        end if;

                    when branch_relative =>
                        read_register_b_src <= '1';
                        alu_control <= "011";
                        pc_enable <= '1';

                        if 
                        
                    when stxr_execute =>

                end case;

                wait on current_state;
                wait on clock;

        end process control;
end architecture control_unit_beh;
