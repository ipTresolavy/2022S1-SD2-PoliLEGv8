ALU_files := $(wildcard ../hdl/ALU/**)
Memory_files := $(wildcard ../hdl/Memory/**)
Register_File_files := $(wildcard ../hdl/Register_File/**)
Sign_Extension_Unit_files := $(wildcard ../hdl/Sign_Extension_Unit/**)

all: ALU Memory Register_File Sign_Extension_Unit

ALU: $(ALU_files)
	vcom ../hdl/ALU/full_adder.vhd -work ../build/ALU/work/ > make_log
	vcom ../hdl/ALU/alu.vhd -work ../build/ALU/work/ >> make_log
	echo '\n\n' >> make_log


Memory: $(Memory_files)
	vcom ../hdl/Memory/data_memory.vhd -work ../build/Memory/work/ >> make_log
	vcom ../hdl/Memory/data_memory_tb.vhd -work ../build/Memory/work/ >> make_log
	vcom ../hdl/Memory/instruction_memory.vhd -work ../build/Memory/work >> make_log
	vcom ../hdl/Memory/instruction_memory_tb.vhd -work ../build/Memory/work >> make_log
	echo '\n\n' >> make_log

Register_File: $(Register_File_files)
	vcom ../hdl/Register_File/register_d.vhd -work ../build/Register_File/work >> make_log
	vcom ../hdl/Register_File/register_file.vhd -work ../build/Register_File/work >> make_log
	echo '\n\n' >> make_log

Sign_Extension_Unit: $(Sign_Extension_Unit_files)
	vcom ../hdl/Sign_Extension_Unit/sign_extension_unit.vhd -work ../build/Sign_Extension_Unit/work >> make_log
	echo '\n\n' >> make_log

clean:
	rm ../build/**/work/**
