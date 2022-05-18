-------------------------------------------------------
--! @file data_memory.vhd
--! @brief implementação da RAM de dados do LEGv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @date 2022-05-14
-------------------------------------------------------

library IEEE;
use IEEE.numeric_bit.all;

entity datapath is
    generic(
        instruction_mem_addressable_range   : natural := 8;
        program             : string  := "program.dat"

        data_mem_addressable_range   : natural := 16
    );
    port(
        clock               : in bit;
        uncond_branch       : in bit;
        reg_b_src           : in bit;
        branch              : in bit;
        mem_read            : in bit;
        reg_write_data_src  : in bit;
        alu_op              : in bit_vector(3 downto 0);
        mem_write           : in bit;
        alu_src             : in bit;
        reg_write           : in bit;

        instruction         : out bit_vector(31 downto 0)
    );
end entity datapath;

architecture datapath_operation of datapath is

    -- PC register's signals
    component d_register is
        generic(
            width: natural := 4
        );
        port(
            clock, load : in bit;
            d           : in bit_vector(width-1 downto 0);
            q           : out bit_vector(width-1 downto 0)
        );
    end component d_register;

    signal pc_mux_out : bit_vector(63 downto 0);
    signal pc_out : bit_vector(63 downto 0);
    -- End PC register's signals

    -- Instruction memory's signals
    component instruction_memory is
        generic(
            addressable_range   : natural := 8;
            program             : string  := "program.dat"
        );
        port(
            instruction_address : in  bit_vector(63 downto 0);
            instruction         : out bit_vector(31 downto 0)
        );
    end component instruction_memory;

    signal instruction_mem_out : bit_vector(31 downto 0);
    -- End instruction memory's signals

    -- ALU's signals
    component full_adder is
        port (
            a           : in bit;
            b           : in bit;
            alu_op      : in bit_vector(3 downto 0);
            carry_in    : in bit;
            less        : in bit;

            carry_out   : out bit;
            result      : out bit;
            set         : out bit
        );
    end component full_adder;
    component alu is
        port (
            a           : in bit_vector(63 downto 0);
            b           : in bit_vector(63 downto 0);
            alu_op      : in bit_vector(3 downto 0);

            zero        : out bit;
            result      : out bit_vector(63 downto 0);
            overflow    : out bit;
            carry_out   : out bit
        );
    end component alu;

    signal zero_flag_ground : bit_vector(1 downto 0);
    signal overflow_flag_ground : bit_vector(2 downto 0);
    signal carry_out_flag_ground : bit_vector(2 downto 0);
    signal next_instruction_address : bit_vector(63 downto 0);

    signal branch_address : bit_vector(63 downto 0);
    signal zero_flag : bit;
    signal alu_b_data_mux_out : bit_vector(63 downto 0);
    signal main_alu_out : bit_vector(63 downto 0);
    -- End ALU's signals

    -- Register File's signals
    component register_file is
        port(
            clock                   : in  bit;
            read_reg_a              : in  bit_vector(4 downto 0);
            read_reg_b              : in  bit_vector(4 downto 0);
            write_reg               : in  bit_vector(4 downto 0);
            write_data              : in  bit_vector(63 downto 0);
            write                   : in  bit;

            reg_a_data              : out bit_vector(63 downto 0);
            reg_b_data              : out bit_vector(63 downto 0)
        );
    end component register_file;

    signal reg_b_mux_out : bit_vector(4 downto 0);
    signal reg_write_data_mux_out : bit_vector(63 downto 0);
    signal reg_a_data : bit_vector(63 downto 0);
    signal reg_b_data : bit_vector(63 downto 0);
    -- End Register File's signals

    -- Data memory's signals
    component data_memory is
        generic(
            addressable_range   : natural := 16
        );
        port(
            clock               : in  bit;
            address, write_data : in  bit_vector(63 downto 0);
            mem_read, mem_write : in  bit;

            read_data           : out bit_vector(63 downto 0)
        );
    end component data_memory;

    signal read_dynamic_data : bit_vector(63 downto 0);
    -- End data memory's signals

    signal sign_extension_out : bit_vector(63 downto 0);
    signal pc_src : bit;

    begin

        PC:
        d_register generic map (64) port map (clock, '1', pc_mux_out, pc_out);

        Instruction_mem:
        instruction_memory generic map (instruction_mem_addressable_range, "program.dat")
                           port map (pc_out, instruction_mem_out);

        next_instruction_alu:
        alu port map (pc_out, bit_vector(to_unsigned(4, pc_out'length)), "0010", zero_flag_ground(0), next_instruction_address, overflow_flag_ground(0), carry_out_flag_ground(0));

        register_file_declaration:
        register_file port map (clock, instruction_mem_out(9 downto 5), reg_b_mux_out, instruction_mem_out(4 downto 0), reg_write_data_mux_out, reg_write, reg_a_data, reg_b_data);

        branch_alu:
        alu port map ((sign_extension_out sll 2), pc_out, "0010", zero_flag_ground(1), branch_address, overflow_flag_ground(1), carry_out_flag_ground(1));

        main_alu:
        alu port map (reg_a_data, alu_b_data_mux_out, alu_op, zero_flag, main_alu_out, overflow_flag_ground(2), carry_out_flag_ground(2));

        dynamic_data_mem:
        data_memory generic map (data_mem_addressable_range)
                    port map (clock, main_alu_out, reg_b_data, mem_read, mem_write, read_dynamic_data);

        with reg_b_src select
            reg_b_mux_out <= instruction_mem_out(20 downto 16) when '0',
                             instruction_mem_out(4 downto 0) when others;

        with reg_write_data_src select
            reg_write_data_mux_out <= read_dynamic_data when '1',
                                      main_alu_out when others;

        with alu_src select
            alu_b_data_mux_out <= reg_b_data when '0',
                                  sign_extension_out when others;

        pc_src <= (branch and zero_flag) or uncond_branch;
        with pc_src select
            pc_mux_out <= next_instruction_address when '0',
                          branch_address when others;

        -- TODO: Implement signal extension
        -- with instruction_mem_out(31) & instruction_mem_out(26) select
            -- sign_extension_out <= resize(signed(instruction_mem_out(25 downto 0)), sign_extension_out'length) when "01", -- Unconditional Branch
                                  -- resize(signed(instruction_mem_out(20 downto 12)), sign_extension_out'length) when "10", -- Data transfer
                                  -- resize(signed(instruction_mem_out(23 downto 5)), sign_extension_out'length) when "11", -- Conditional Branch
                                  -- resize(signed(instruction_mem_out(21 downto 10)), sign_extension_out'length) when others, -- Conditional Branch

        instruction <= instruction_mem_out;

end architecture datapath_operation;
