# Para o testbench do Datapath
    - instruction e read_data serão inventados

# Fetch
# Decode
# Execute

## B (B-format)
    * alu_control <-- 011
    * alu_b_src <-- 11
    * pc_enable

instruction_read_address = SignExt( instruction[25:0] )

## STURB (D-format)
    * alu_b_src <-- 11
    * read_register_b_src
    * data_memory_src <-- 01

SignExt( Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12])) ) = SignExt( Register_File(instruction[4:0])[7:0] )

## LDURB (D-format)
    * alu_b_src <-- 11
    * write_register_enable
    * data_memory_src <-- 01

Register_File(instruction[4:0]) = SignExt( Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12]))[7:0] )

## B.cond (CB-format)
    * alu_pc_b_src
    * pc_src
    * pc_enable <-- cond ? 1 : 0

if ( Flag_Register_File(cond) ) --> pc_enable --> instruction_read_address <-- instruction_read_address + SignExt( instruction[23:5] )

## STURH (D-format)
    * alu_b_src <-- 11
    * read_register_b_src
    * data_memory_src <-- 01

Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12])) = SignExt( Register_File(instruction[4:0])[15:0] )

## LDURH (D-format)
    * alu_b_src <-- 11
    * write_register_enable
    * data_memory_src <-- 01

Register_File(instruction[4:0]) = SignExt( Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12]))[15:0] )

## AND (R-format)
    * alu_control <-- 001
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) and Register_File(instruction[20:16])

## ADD (R-format)
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) + Register_File(instruction[20:16])

## ADDI (I-format)
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) + SignExt(instruction[21:10])

## ANDI (I-format)
    * alu_control <-- 001
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) and SignExt(instruction[21:10])

## BL (B-format)
    * alu_control <-- 011
    * alu_b_src <-- 11
    * pc_enable
    * write_register_src
    * write_register_enable

Register_File(30) := LR = instruction_read_address --> instruction_read_address = SignExt( instruction[25:0] )

## SDIV (R-format)
This instruction has more than one execution state

    * initial_state:
        * mul_div_enable
        * shift_amount <-- 000010

    * -- mul_div_busy = 1 --> ongoing_sdiv:
        * mul_div_enable
        * shift_amount <-- 000010

    * -- mul_div_busy = 0 -->  div_end:
        * write_register_data_src <-- 10
        * write_register_enable

Register_File(instruction[4:0]) = (signed)(Register_File(instruction[9:5]) / Register_File(instruction[20:16]))[63:0]

## UDIV (R-format)
This instruction has more than one execution state

    * initial_state:
        * mul_div_enable
        * shift_amount <-- 000011

    * -- mul_div_busy = 1 --> ongoing_udiv:
        * mul_div_enable
        * shift_amount <-- 000011

    * -- mul_div_busy = 0 -->  div_end:
        * write_register_data_src <-- 10
        * write_register_enable

Register_File(instruction[4:0]) = (unsigned)(Register_File(instruction[9:5]) / Register_File(instruction[20:16]))[63:0]

## MUL (R-format)
This instruction has more than one execution state

    * initial_state:
        * mul_div_enable
        * shift_amount <-- 011111

    * -- mul_div_busy = 1 --> ongoing_mul:
        * mul_div_enable
        * shift_amount <-- 011111

    * -- mul_div_busy = 0 -->  mul_end:
        * write_register_data_src <-- 10
        * write_register_enable

Register_File(instruction[4:0]) = (Register_File(instruction[9:5]) * Register_File(instruction[20:16]))[63:0]

## SMULH (R-format)
This instruction has more than one execution state

    * initial_state:
        * mul_div_enable

    * -- mul_div_busy = 1 --> ongoing_mul:
        * mul_div_enable

    * -- mul_div_busy = 0 -->  mul_end:
        * mul_div_src
        * write_register_data_src <-- 10
        * write_register_enable

Register_File(instruction[4:0]) = (signed)(Register_File(instruction[9:5]) * Register_File(instruction[20:16]))[127:64]

## UMULH (R-format)
This instruction has more than one execution state

    * initial_state:
        * mul_div_enable

    * -- mul_div_busy = 1 --> ongoing_mul:
        * mul_div_enable

    * -- mul_div_busy = 0 -->  mul_end:
        * mul_div_src
        * write_register_data_src <-- 10
        * write_register_enable

Register_File(instruction[4:0]) = (unsigned)(Register_File(instruction[9:5]) * Register_File(instruction[20:16]))[127:64]

## ORR (R-format)
    * alu_control <-- 010
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) or Register_File(instruction[20:16])

## ADDS (R-format)
    * set_flags
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) + Register_File(instruction[20:16])
Flag_Register_File = ALU_Flags

## ADDIS (I-format)
    * set_flags
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) + SignExt(instruction[21:10])
Flag_Register_File = ALU_Flags

## ORRI (I-format)
    * alu_control <-- 010
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) or SignExt(instruction[21:10])

## CBZ (CB-format)
    * alu_control <-- 011
    * alu_pc_b_src
    * pc_src
    * pc_enable <-- ALU_flags(Z)
    * read_register_b_src

if (Register_File(instruction[4:0]) == 0) --> instruction_read_address = instruction_read_address + SignExt(instruction[23:5])

## CBNZ (CB-format)
    * alu_control <-- 011
    * alu_pc_b_src
    * pc_src
    * pc_enable <-- ALU_flags(not Z)
    * read_register_b_src

if (Register_File(instruction[4:0]) != 0) --> instruction_read_address = instruction_read_address + SignExt(instruction[23:5])

## STURW (D-format)
    * alu_b_src <-- 11
    * read_register_b_src
    * data_memory_src <-- 10

Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12])) = UnsignExt( Register_File(instruction[4:0])[31:0] )

## LDURSW (D-format)
    * alu_b_src <-- 11
    * write_register_enable
    * data_memory_src <-- 10

Register_File(instruction[4:0]) = SignExt( Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12]))[31:0] )

## STXR (D-format)
    * alu_control <-- 101
    * read_register_a_src

if (Data_memory(instruction[4:0]) == Register_File(Monitor)) --> Data_memory()

## LDXR (D-format)
    * alu_b_src <-- 11
    * monitor_enable
    * write_register_enable
    * data_memory_src <-- 11

Register_File(instruction[4:0]) = SignExt( Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12])) )
Monitor = instruction[9:5]

## EOR (R-format)
    * alu_control <-- 101
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) xor Register_File(instruction[20:16])

## SUB (R-format)
    * alu_control <-- 100
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) - Register_File(instruction[20:16])

## SUBI (I-format)
    * alu_control <-- 100
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) - SignExt(instruction[21:10])


## EORI (I-format)
    * alu_control <-- 101
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) xor SignExt(instruction[21:10])

## MOVZ (IM/IW-format)
    * mov_enable
    * alu_control <-- 011
    * shift_amount <-- instruction[22:21] << 4
    * read_register_b_src
    * write_register_enable

Register_File(instruction[4:0]) = UnsignExt( instruction[20:5] ) << (instruction[22:21] << 4)

## LSL (R-format)
    * alu_control <-- 011
    * shift_amount <-- instruction[15:10]
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) << Register_File(instruction[20:16])

## LSL (R-format)
    * alu_control <-- 111
    * shift_amount <-- instruction[15:10]
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) >> Register_File(instruction[20:16])

## BR (R-format)
    * alu_b_src <-- 10
    * pc_enable

instruction_read_address <-- Register_File(instruction[9:5])

## ANDS (R-format)
    * alu_control <-- 001
    * set_flags
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) and Register_File(instruction[20:16])
Flag_Register_File = ALU_Flags

## SUBS (R-format)
    * alu_control <-- 100
    * set_flags
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) - Register_File(instruction[20:16])
Flag_Register_File = ALU_Flags

## SUBIS (I-format)
    * alu_control <-- 100
    * set_flags
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) - SignExt(instruction[21:10])

## ANDIS (I-format)
    * alu_control <-- 001
    * set_flags
    * alu_b_src <-- 11
    * write_register_enable

Register_File(instruction[4:0]) = Register_File(instruction[9:5]) and SignExt(instruction[21:10])

## MOVK (IM/IW-format)
    * mov_enable
    * alu_control <-- 011
    * shift_amount <-- instruction[22:21] << 4
    * read_register_b_src
    * write_register_enable

Register_File(instruction[4:0]) = (UnsignExt( instruction[20:5] ) << (instruction[22:21] << 4)) or (not (UnsignExt(0xFFFF) << (instruction[22:21] << 4) and Register_File(instruction[4:0])))

## STUR (D-format)
    * alu_b_src <-- 11
    * read_register_b_src
    * data_memory_src <-- 11

Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12])) = Register_File(instruction[4:0])

## LDUR (D-format)
    * alu_b_src <-- 11
    * write_register_enable
    * data_memory_src <-- 11

Register_File(instruction[4:0]) = Data_memory(Register_file(instruction[9:5]) + SignExt(instruction[20:12]))
