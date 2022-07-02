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
        flags_cond_sel: in bit_vector(3 downto 0);

        -- To Dataflow
            -- MOV's signals
        mov_enable: out bit;
            -- ALU's signals
        alu_control: out bit_vector(2 downto 0);
        set_flags: out bit;
        alu_b_src: out bit_vector(1 downto 0);
        shift_amount_src: out bit;
        	-- mul_div_unit's signals
        mul_div_src: out bit;
        mul_div_busy : in bit;
        mul_div_enable: out bit;
            --ALU_pc's signals
        alu_pc_b_src: out bit;
            -- PC's signals
        pc_src: out bit;
        pc_branch_src: out bit;
        pc_enable: out bit;
        	-- monitor's signals
        monitor_enable: out bit;
            -- reg file
        read_register_a_src: out bit;
        read_register_b_src: out bit;
        write_register_src: out bit_vector(1 downto 0);
        write_register_data_src: out bit_vector(1 downto 0);
        write_register_enable: out bit;
        -- Instruction memory
        instruction_mem_enable : out bit;
        instruction_mem_busy   : in bit;
        -- Data memory
        data_mem_enable : out bit;
        data_mem_write_en : out bit;
        data_mem_busy   : in bit;
        data_memory_src: out bit_vector(1 downto 0)
    );

end entity control_unit;

architecture control_unit_beh of control_unit is

    type state_type is (idle, fetch_decode, branch_and_link, stxr_execute, branch_relative, IW, D, R_and_I, BR);

    signal next_state, current_state : state_type := idle;
    signal flags_mux_out, flags_mux_final, cbz, cbnz, b_flags, uncond_branch : bit;

begin
        pc_src <= (b_flags and flags_mux_out) or
                  (zero and cbz) or
                  ((not zero) and cbnz);

        with flags_cond_sel(3 downto 1) select flags_mux_out <=
            zero_r when "000",
            carry_out_r when "001",
            negative_r when "010",
            overflow_r when "011",
            not zero_r and carry_out_r when "100",
            negative_r xor overflow_r when "101",
            not zero_r and not (negative_r xor overflow_r) when "110",
            '1' when others;

        flags_mux_final <= (flags_mux_out xor (flags_cond_sel(0) and not (flags_cond_sel(3) and flags_cond_sel(2) and flags_cond_sel(1))));

        data_memory_src <= opcode(10 downto 9);

        mul_div_src <= opcode(3) and opcode(1);

        change_of_state: process(clock, reset) is
            begin
                if reset = '1' then
                    current_state <= idle;
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
                shift_amount_src <= '0';
                mul_div_enable <= '0';
                alu_pc_b_src <= '0';
                pc_branch_src <= '0';
                pc_enable <= '0';
                monitor_enable <= '0';
                instruction_mem_enable <= '0';
                data_mem_enable <= '0';
                uncond_branch <= '0';
                b_flags <= '0';
                cbz <= '0';
                cbnz <= '0';
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
                    when idle =>
                        next_state <= fetch_decode;

                    when fetch_decode =>
                        instruction_mem_enable <= '1';
                        wait until instruction_mem_busy = '1';
                        wait until instruction_mem_busy = '0';
                        instruction_mem_enable <= '0';

                        if (opcode(10 downto 5) = "100101") then
                            next_state <= branch_and_link;
                        elsif (opcode(10 downto 5) = "000101" or opcode(7 downto 4) = "1010") then
                            next_state <= branch_relative;
                        elsif (opcode(10 downto 9) & opcode(7 downto 2) = "11100101") then
                            next_state <= IW;
                        elsif (opcode(6 downto 3) & opcode(0) = "10000") then
                            next_state <= D;
                        elsif ('0' & opcode = x"6B0") then -- BR
                            next_state <= BR;
                        else
                            next_state <= R_and_I;
                        end if;

                    -- BL
                    when branch_and_link =>
                        alu_control <= "011";
                        alu_b_src <= "01";
                        write_register_enable <= '1';
                        write_register_src <= "01";
                        wait until rising_edge(clock); -- link
                        reset_control_signals;

                        uncond_branch <= '1';
                        pc_enable <= '1';
                        next_state <= fetch_decode;


                    -- CBZ, CBNZ, B.cond and B
                    when branch_relative =>
                        read_register_b_src <= '1';
                        alu_control <= "011";
                        pc_enable <= '1';
                        pc_branch_src <= '0';

                        if opcode(10 downto 9) = "00" then
                            uncond_branch <= '1';
                        elsif opcode(10 downto 9) = "01" then
                            b_flags <= '1';
                        elsif opcode(10 downto 9) = "10" then
                            if opcode(4) = '0' then
                                cbz <= '1';
                            else
                                cbnz <= '1';
                            end if;
                        end if;
                        next_state <= fetch_decode;

                    when IW =>
                        mov_enable <= '1';
                        alu_control <= "011";
                        read_register_b_src <= '1';
                        write_register_enable <= '1';
                        pc_enable <= '1';
                        next_state <= fetch_decode;

                    when D =>
                        alu_b_src <= "11";
                        read_register_b_src <= '1';
                        write_register_data_src <= "01";

                        -- monitor is enabled on LDXR
                        monitor_enable <= (not opcode(8)) and opcode(1);


                        -- Differing between Loads and Stores
                        if(opcode(8 downto 7) & opcode(2 downto 1) = "1100") then -- Loads
                            wait_for_data_mem(true);
                        else -- Stores

                            wait_for_data_mem(false);
                            if (opcode(8) & opcode(1) = "00") then -- STXR
                                read_register_a_src <= '1';
                                write_register_src <= "11";
                                write_register_data_src <= "11";
                            end if;
                            write_register_enable <= '1';
                        end if;

                        -- Deciding next state
                        if(opcode(8) & opcode(1) & stxr_try_in = "000") then
                            next_state <= stxr_execute;
                        else
                            pc_enable <= '1';
                            next_state <= fetch_decode;
                        end if;

                    when stxr_execute =>
                        alu_b_src <= "11";
                        read_register_b_src <= '1';

                        pc_enable <= '1';
                        next_state <= fetch_decode;

                    when BR =>
                        alu_control <= "010";
                        pc_enable <= '1';
                        pc_branch_src <= '1';
                        uncond_branch <= '1';
                        next_state <= fetch_decode;

                    when R_and_I =>
                        alu_b_src <= '1' & (opcode(7) and (not opcode(6)) and (not opcode(5)) and (not opcode(2)) and (not opcode(1))); -- opcode 10 is not needed (?)
                        shift_amount_src <= not (opcode(7) and (not opcode(6)) and (not opcode(5)) and (not opcode(2)) and (not opcode(1)));
                        write_register_data_src <= ((not opcode(9)) and (not opcode(8)) and opcode(7)) & '0';
                        set_flags <= opcode(8) and (opcode(9) or opcode(3));
                        -- alu_control
                            -- LSL(LSR)
                        if(opcode(9 downto 1) = "101001101") then
                            alu_control <= (not opcode(0)) & "11";
                            -- ADD(SUB)
                        elsif(opcode(5) & opcode(3 downto 1) = "0100") then
                            alu_control <= opcode(9) & "00";
                            -- OR
                        elsif(opcode(9 downto 8) = "01") then
                            alu_control <= "010";
                            -- EOR(XOR)
                        elsif(opcode(9 downto 8) = "10") then
                            alu_control <= "101";
                            -- AND
                        else
                            alu_control <= "001";
                        end if;
                        if(((not opcode(9)) and (not opcode(8)) and opcode(7)) = '1') then
                            mul_div_enable <= '1';
                            wait_for_mul_div;
                        end if;
                        pc_enable <= '1';
                        next_state <= fetch_decode;
                end case;

                wait on current_state;
                wait on clock;

        end process control;
end architecture control_unit_beh;

