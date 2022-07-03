-------------------------------------------------------
--! @file polilegv8.vhd
--! @brief Implementação do Polilegv8
--! @author Igor Pontes Tresolavy (tresolavy@usp.br)
--! @author Joao Pedro Cabral Miranda (miranda.jp@usp.br)
--! @author Joao Pedro Selva Bernardino (jpselva@usp.br)
--! @date 2022-06-26
-------------------------------------------------------

library ieee;
use ieee.math_real.all;
use ieee.numeric_bit.all;

entity polilegv8 is
    generic(
        word_size: natural := 64;
        data_memory_size: natural := 1024;
        instruction_memory_size: natural := 128;
        reg_reset_value: natural := 0
    );
    port(
        -- Common
        clock   : in bit;
        reset   : in bit;

        -- Memory interfaces
            -- Data memory interface
            data_mem_enable            : out bit;
            data_mem_write_en : out bit;
            data_mem_busy     : in bit;
            data_memory_address: out bit_vector(integer(ceil(log2(real(data_memory_size)))) - 1 downto 0);
            read_data: in bit_vector(word_size - 1 downto 0);
            write_data: out bit_vector(word_size - 1 downto 0);

            -- Instruction memory interface
            instruction_mem_enable     : out bit;
            instruction_mem_busy       : in bit;
            instruction_read_address: out bit_vector(integer(ceil(log2(real(instruction_memory_size)))) - 1 downto 0);
            instruction: in bit_vector(31 downto 0)

    );
end entity polilegv8;

architecture polilegv8_processor of polilegv8 is
    component control_unit
        port (clock                   : in bit;
              reset                   : in bit;
              opcode                  : in bit_vector (10 downto 0);
              zero                    : in bit;
              zero_r                  : in bit;
              carry_out_r             : in bit;
              overflow_r              : in bit;
              negative_r              : in bit;
              stxr_try_in             : in bit;
              flags_cond_sel          : in bit_vector (3 downto 0);
              mov_enable              : out bit;
              alu_control             : out bit_vector (2 downto 0);
              set_flags               : out bit;
              alu_b_src               : out bit_vector (1 downto 0);
              shift_amount_src        : out bit;
              mul_div_src             : out bit;
              mul_div_busy            : in bit;
              mul_div_enable          : out bit;
              alu_pc_b_src            : out bit;
              pc_src                  : out bit;
              pc_branch_src           : out bit;
              pc_enable               : out bit;
              monitor_enable          : out bit;
              read_register_a_src     : out bit;
              read_register_b_src     : out bit;
              write_register_src      : out bit_vector (1 downto 0);
              write_register_data_src : out bit_vector (1 downto 0);
              write_register_enable   : out bit;
              instruction_mem_enable  : out bit;
              instruction_mem_busy    : in bit;
              data_mem_enable         : out bit;
              data_mem_write_en       : out bit;
              data_mem_busy           : in bit;
              data_memory_src         : out bit_vector (1 downto 0));
    end component;

    component DataFlow
        generic(
            word_size: natural := 64;
            data_memory_size: natural := 1024;
            instruction_memory_size: natural := 128;
            reg_reset_value: natural := 0
        );
        port (
            clock                    : in bit;
            reset                    : in bit;
            instruction              : in bit_vector (31 downto 0);
            instruction_read_address : out bit_vector (integer(ceil(log2(real(instruction_memory_size)))) - 1 downto 0);
            read_data                : in bit_vector (word_size - 1 downto 0);
            write_data               : out bit_vector (word_size - 1 downto 0);
            data_memory_address      : out bit_vector (integer(ceil(log2(real(data_memory_size)))) - 1 downto 0);
            opcode                   : out bit_vector (10 downto 0);
            zero                     : out bit;
            zero_r                   : out bit;
            carry_out_r              : out bit;
            overflow_r               : out bit;
            negative_r               : out bit;
            stxr_try_out             : out bit;
            mov_enable               : in bit;
            alu_control              : in bit_vector (2 downto 0);
            set_flags                : in bit;
            shift_amount_src         : in bit;
            alu_b_src                : in bit_vector (1 downto 0);
            mul_div_src              : in bit;
            mul_div_busy             : out bit;
            mul_div_enable           : in bit;
            pc_src                   : in bit;
            pc_branch_src            : in bit;
            pc_enable                : in bit;
            monitor_enable           : in bit;
            read_register_a_src      : in bit;
            read_register_b_src      : in bit;
            write_register_src       : in bit_vector(1 downto 0);
            write_register_data_src  : in bit_vector (1 downto 0);
            write_register_enable    : in bit;
            data_memory_src          : in bit_vector (1 downto 0));

    end component;


    signal alu_b_src                    : bit_vector (1 downto 0);
    signal alu_control                  : bit_vector (2 downto 0);
    signal alu_pc_b_src                 : bit;
    signal carry_out_r                  : bit;
    signal data_memory_src              : bit_vector (1 downto 0);
    signal flags_cond_sel               : bit_vector (3 downto 0);
    signal monitor_enable               : bit;
    signal mov_enable                   : bit;
    signal mul_div_busy                 : bit;
    signal mul_div_enable               : bit;
    signal mul_div_src                  : bit;
    signal negative_r                   : bit;
    signal opcode                       : bit_vector (10 downto 0);
    signal overflow_r                   : bit;
    signal pc_branch_src                : bit;
    signal pc_enable                    : bit;
    signal pc_src                       : bit;
    signal read_register_a_src          : bit;
    signal read_register_b_src          : bit;
    signal set_flags                    : bit;
    signal shift_amount_src             : bit;
    signal stxr_try_in                  : bit;
    signal stxr_try_out                 : bit;
    signal write_register_data_src      : bit_vector (1 downto 0);
    signal write_register_enable        : bit;
    signal write_register_src           : bit_vector(1 downto 0);
    signal zero                         : bit;
    signal zero_r                       : bit;

begin

    UC: control_unit
    port map (clock                   => clock,
              reset                   => reset,
              opcode                  => opcode,
              zero                    => zero,
              zero_r                  => zero_r,
              carry_out_r             => carry_out_r,
              overflow_r              => overflow_r,
              negative_r              => negative_r,
              stxr_try_in             => stxr_try_in,
              flags_cond_sel          => flags_cond_sel,
              mov_enable              => mov_enable,
              alu_control             => alu_control,
              set_flags               => set_flags,
              alu_b_src               => alu_b_src,
              shift_amount_src        => shift_amount_src,
              mul_div_src             => mul_div_src,
              mul_div_busy            => mul_div_busy,
              mul_div_enable          => mul_div_enable,
              alu_pc_b_src            => alu_pc_b_src,
              pc_src                  => pc_src,
              pc_branch_src           => pc_branch_src,
              pc_enable               => pc_enable,
              monitor_enable          => monitor_enable,
              read_register_a_src     => read_register_a_src,
              read_register_b_src     => read_register_b_src,
              write_register_src      => write_register_src,
              write_register_data_src => write_register_data_src,
              write_register_enable   => write_register_enable,
              instruction_mem_enable  => instruction_mem_enable,
              instruction_mem_busy    => instruction_mem_busy,
              data_mem_enable         => data_mem_enable,
              data_mem_write_en       => data_mem_write_en,
              data_mem_busy           => data_mem_busy,
              data_memory_src         => data_memory_src);

    DF: DataFlow
    generic map (
        word_size => word_size,
        data_memory_size => data_memory_size,
        instruction_memory_size => instruction_memory_size,
        reg_reset_value => reg_reset_value
    )
    port map (
        clock                    => clock,
        reset                    => reset,
        instruction              => instruction,
        instruction_read_address => instruction_read_address,
        read_data                => read_data,
        write_data               => write_data,
        data_memory_address      => data_memory_address,
        opcode                   => opcode,
        zero                     => zero,
        zero_r                   => zero_r,
        carry_out_r              => carry_out_r,
        overflow_r               => overflow_r,
        negative_r               => negative_r,
        stxr_try_out             => stxr_try_out,
        mov_enable               => mov_enable,
        alu_control              => alu_control,
        set_flags                => set_flags,
        alu_b_src                => alu_b_src,
        mul_div_src              => mul_div_src,
        mul_div_busy             => mul_div_busy,
        mul_div_enable           => mul_div_enable,
        pc_src                   => pc_src,
        pc_enable                => pc_enable,
        monitor_enable           => monitor_enable,
        read_register_a_src      => read_register_a_src,
        read_register_b_src      => read_register_b_src,
        write_register_src       => write_register_src,
        write_register_data_src  => write_register_data_src,
        write_register_enable    => write_register_enable,
        data_memory_src          => data_memory_src,
        shift_amount_src         => shift_amount_src,
        pc_branch_src            => pc_branch_src
    );

end architecture polilegv8_processor;
