
-------------------------------------------------------
--! @file DataFlow.vhd
--! @brief Dataflow do polilegv8
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @date 2022-05-26
-------------------------------------------------------

library ieee;
use ieee.math_real.all;
use ieee.numeric_bit.all;

entity DataFlow is
    generic(
        word_size: natural := 64;
        data_memory_size: natural := 1024;
        instruction_memory_size: natural := 128;
        reg_reset_value: natural := 0
    );
    port(
        -- Common
        clock: in bit;
        reset: in bit;
        -- Instruction Memory
        instruction: in bit_vector(31 downto 0);
        instruction_read_address: out bit_vector(integer(log2(real(instruction_memory_size))) - 1 downto 0);
        -- Data Memory
        read_data: in bit_vector(word_size - 1 downto 0);
        write_data: out bit_vector(word_size - 1 downto 0);
        data_memory_address: out bit_vector(integer(log2(real(data_memory_size))) - 1 downto 0);
        -- To Control Unit
        opcode: out bit_vector(10 downto 0);
        zero: out bit;
        zero_r: out bit;
        carry_out_r: out bit;
        overflow_r: out bit;
        negative_r: out bit;
        stxr_try_out: out bit;
        -- From Control Unit 
            -- MOV's signals
        mov_enable: in bit;
            -- ALU's signals
        alu_control: in bit_vector(2 downto 0);
        set_flags: in bit;
        shift_amount: in bit_vector(integer(log2(real(word_size))) - 1 downto 0);
        alu_b_src: in bit_vector(1 downto 0);
        	-- mul_div_unit's signals
        mul_div_src: in bit;
        mul_div_busy : out bit;
        mul_div_enable: in bit;
            --ALU_pc's signals
        alu_pc_b_src: in bit;
            -- PC's signals
        pc_src: in bit;
        pc_enable: in bit;
        	-- monitor's signals
        monitor_enable: in bit;
            -- Instruction Memory's signals
        read_register_a_src: in bit;
        read_register_b_src: in bit;
        write_register_src: in bit;
        write_register_data_src: in bit_vector(1 downto 0);
        write_register_enable: in bit;
            -- Data Memory's signals
        data_memory_src: in bit_vector(1 downto 0)
    );
end entity DataFlow;

architecture structural of DataFlow is

    component ALU is
    	generic(
		word_size: natural := 64
	    );
	    port (
            clock: in bit;
            reset: in bit;
            A: in bit_vector(word_size - 1 downto 0); -- ALU A
            B: in bit_vector(word_size - 1 downto 0); -- ALU B
            alu_control: in bit_vector(2 downto 0); -- ALU Control's signal
            set_flags: in bit;
            shift_amount: in bit_vector(integer(log2(real(word_size))) - 1 downto 0);
            Y: out bit_vector(word_size - 1 downto 0); -- ALU Result
            Zero: out bit; -- Vale 1, caso Y = 0
            -- Registradores de flags
            Zero_r: out bit;
            Overflow_r: out bit;
            Carry_out_r: out bit;
            Negative_r: out bit
	    );
    end component ALU;
    
    component mul_div_unit is
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
    end component register_d;

    component ALU_pc is
        generic(
            size: natural := 64
        );
        port(
            PC: in bit_vector(size - 1 downto 0);
            increment: in bit_vector(size - 1 downto 0);
            PC_register_in: out bit_vector(size - 1 downto 0)
        );
    end component ALU_pc;

    component MOV is
        generic(
            word_size : natural := 64
        );
        port(
            A: in bit_vector(word_size - 1 downto 0);
            B: out bit_vector(word_size - 1 downto 0);
            imediato: in bit_vector(word_size/4 - 1 downto 0);
            shift: in bit_vector(1 downto 0); -- tamanho do shift a ser realizado
            mov_enable: in bit; -- UC signal: habilita a operação MOV
            z_k: in bit -- UC signal: 0 gera um MOVZ, 1 gera um MOVK
        );
    end component MOV;

    component mux2x1 is
        generic(
            size: natural := 32
        );
        port(
            A: in bit_vector(size - 1 downto 0);
            B: in bit_vector(size - 1 downto 0);
            S: in bit;
            Y: out bit_vector(size - 1 downto 0)
        );
    end component mux2x1;

    component mux4x1 is
        generic(
            size: natural := 32
        );
        port(
            A: in bit_vector(size - 1 downto 0);
            B: in bit_vector(size - 1 downto 0);
            C: in bit_vector(size - 1 downto 0);
            D: in bit_vector(size - 1 downto 0);
            S: in bit_vector(1 downto 0);
            Y: out bit_vector(size - 1 downto 0)
        );
    end component mux4x1;

    component register_file is
        generic(
            amount_of_regs : natural := 32; -- including XZR
            register_width : natural := 64; -- amount of bits in each register
            reg_reset_value: natural := 0
        );
        port(
            clock                   : in  bit;
            reset                   : in  bit;
            read_reg_a              : in  bit_vector(integer(log2(real(amount_of_regs)))-1 downto 0);
            read_reg_b              : in  bit_vector(integer(log2(real(amount_of_regs)))-1 downto 0);
            write_reg               : in  bit_vector(integer(log2(real(amount_of_regs)))-1 downto 0);
            write_data              : in  bit_vector(register_width-1 downto 0);
            write_enable            : in  bit;
            reg_a_data              : out bit_vector(register_width-1 downto 0);
            reg_b_data              : out bit_vector(register_width-1 downto 0)
        );
    end component register_file;

    component sign_extension_unit is
        generic(
            doubleword_width : natural := 64
        );
        port(
            legv8_instruction    : in bit_vector(31 downto 0);
            signExt_imm          : out bit_vector(doubleword_width-1 downto 0)
        );
    end component sign_extension_unit;

    -- Sign_extension_unit
    signal immediate_extended: bit_vector(word_size - 1 downto 0);

    -- Muxes
    signal write_register_data_mux_out: bit_vector(word_size - 1 downto 0);
    signal read_data_mux_out: bit_vector(word_size - 1 downto 0);

    -- Alu
    signal alu_b: bit_vector(word_size - 1 downto 0);
    signal alu_out: bit_vector(word_size - 1 downto 0);
    
    -- mul_div_unit
    signal mul_div_low: bit_vector(word_size - 1 downto 0);
    signal mul_div_high: bit_vector(word_size - 1 downto 0);
    signal mul_div_out: bit_vector(word_size - 1 downto 0);
    signal mul_div_unsgn: bit;
    signal div: bit;

    -- MOV
    signal mov_immediate: bit_vector(word_size/4 - 1 downto 0);
    signal z_k: bit;

    -- Alu pc
    signal alu_pc_b: bit_vector(word_size - 1 downto 0);
    signal alu_pc_out: bit_vector(word_size - 1 downto 0);
    signal immediate_4: bit_vector(word_size - 1 downto 0);
    signal shifted_immediate: bit_vector(word_size - 1 downto 0);

    -- PC
    signal pc_in: bit_vector(word_size - 1 downto 0);
    signal pc_out: bit_vector(word_size - 1 downto 0);
    
    -- Monitor & STXR
    signal monitor_out: bit_vector(4 downto 0);
    signal stxr_try_xor: bit_vector(word_size - 1 downto 0);
    signal stxr_try_vector: bit_vector(word_size - 1 downto 0);
    signal stxr_try_intermediary: bit_vector(1 downto 0);
    signal stxr_try: bit_vector(word_size - 1 downto 0);

    -- Register File
    signal read_data_a: bit_vector(word_size - 1 downto 0);
    signal read_data_b: bit_vector(word_size - 1 downto 0);
    signal write_register_data: bit_vector(word_size - 1 downto 0);
    signal read_register_a: bit_vector(4 downto 0);
    signal read_register_b: bit_vector(4 downto 0);
    signal write_register: bit_vector(4 downto 0);

    -- Data Memory
    signal write_data_memory_b: bit_vector(word_size - 1 downto 0);
    signal write_data_memory_h: bit_vector(word_size - 1 downto 0);
    signal write_data_memory_w: bit_vector(word_size - 1 downto 0);
    signal read_data_memory_b: bit_vector(word_size - 1 downto 0);
    signal read_data_memory_h: bit_vector(word_size - 1 downto 0);
    signal read_data_memory_w: bit_vector(word_size - 1 downto 0);

begin

    -- Sign_extension_unit
    sign_extender: component sign_extension_unit generic map(word_size) port map(instruction, immediate_extended);

    -- ALU
    ULA: component ALU generic map(word_size) port map(clock, reset, read_data_a, alu_b, alu_control, set_flags, shift_amount, alu_out, zero, zero_r, overflow_r, carry_out_r, negative_r);
    alu_b_mux: component mux4x1 generic map(word_size) port map(read_data_b, alu_pc_out, pc_out, immediate_extended, alu_b_src, alu_b);

	--mul_div_unit
	mul_div: component mul_div_unit generic map(word_size) port map(read_data_a, read_data_b, mul_div_enable, reset, clock, div, mul_div_unsgn, mul_div_busy, mul_div_high, mul_div_low);
	mul_div_mux: component mux2x1 generic map(word_size) port map(mul_div_low, mul_div_high, mul_div_src, mul_div_out);
    div <= not instruction(24);
    mul_div_unsgn <= instruction(10) when div = '1' else instruction(23);

    -- ALU_pc
    ULA_pc: component ALU_pc generic map(word_size) port map(pc_out, alu_pc_b, alu_pc_out);
    alu_pc_b_mux: component mux2x1 generic map(word_size) port map(immediate_4, shifted_immediate, alu_pc_b_src, alu_pc_b);
    immediate_4 <= bit_vector(to_unsigned(4, word_size));
    shifted_immediate <= immediate_extended(word_size - 3 downto 0) & "00";

    -- PC
    PC: component register_d generic map(word_size, 0) port map(pc_in, clock, pc_enable, reset, pc_out);
    pc_mux: component mux2x1 generic map(word_size) port map(alu_out, alu_pc_out, pc_src, pc_in);
    
    -- Monitor
    Monitor: component register_d generic map(5) port map(instruction(9 downto 5), clock, monitor_enable, reset, monitor_out);

    -- Instruction Memory
    instruction_read_address <= bit_vector(resize(unsigned(pc_out), integer(log2(real(instruction_memory_size)))));

    -- MOV
    MOVZ_K: component MOV generic map(word_size) port map(write_register_data_mux_out, write_register_data, mov_immediate, instruction(22 downto 21), mov_enable, z_k);
    z_k <= instruction(29);
    mov_immediate <= bit_vector(resize(signed(instruction(20 downto 5)),word_size/4));

    -- Register File
    Banco_de_registradores: component register_file generic map(32, word_size, 0) port map(clock, reset, read_register_a, read_register_b, write_register, write_register_data, write_register_enable, read_data_a, read_data_b);
    read_register_a_mux: component mux2x1 generic map(5) port map(instruction(9 downto 5), monitor_out, read_register_a_src, read_register_a);
    read_register_b_mux: component mux2x1 generic map(5) port map(instruction(20 downto 16), instruction(4 downto 0),  read_register_b_src, read_register_b);
    write_register_mux: component mux2x1 generic map(5) port map(instruction(4 downto 0), "11110", write_register_src, write_register);
    write_register_data_mux: component mux4x1 generic map(word_size) port map(alu_out, read_data_mux_out, mul_div_out, stxr_try, write_register_data_src, write_register_data_mux_out);
    stxr_try_xor <= read_data_mux_out xor alu_out;
    stxr_try_vector(0) <= stxr_try_xor(0);
    stxr_try_generate: for i in word_size - 1 downto 1 generate
        stxr_try_vector(i) <= (stxr_try_vector(i - 1) or stxr_try_xor(i));
    end generate stxr_try_generate;
    stxr_try_intermediary <= '0' & stxr_try_vector(word_size - 1);
    stxr_try <= bit_vector(resize(unsigned(stxr_try_intermediary), word_size));
    stxr_try_out <= stxr_try_intermediary(0);

    -- Data Memory
    data_memory_address <= alu_out(integer(log2(real(data_memory_size))) - 1 downto 0);
    write_data_memory_mux: component mux4x1 generic map(word_size) port map(write_data_memory_b, write_data_memory_h, write_data_memory_w, read_data_b, data_memory_src, write_data);
    write_data_memory_b <= bit_vector(resize(unsigned(read_data_b(word_size/8 - 1 downto 0)), word_size));
    write_data_memory_h <= bit_vector(resize(unsigned(read_data_b(word_size/4 - 1 downto 0)), word_size));
    write_data_memory_w <= bit_vector(resize(signed(read_data_b(word_size/2 - 1 downto 0)), word_size));
    read_data_memory_mux: component mux4x1 generic map(word_size) port map(read_data_memory_b, read_data_memory_h, read_data_memory_w, read_data, data_memory_src, read_data_mux_out);
    read_data_memory_b <= bit_vector(resize(unsigned(read_data(word_size/8 - 1 downto 0)), word_size));
    read_data_memory_h <= bit_vector(resize(unsigned(read_data(word_size/4 - 1 downto 0)), word_size));
    read_data_memory_w <= bit_vector(resize(unsigned(read_data(word_size/2 - 1 downto 0)), word_size));

end architecture structural;
