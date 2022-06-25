## Sinais da STXR

* initial_state:
    * reg_a_src <-- 0
    * alu_b_src <-- 11
    * alu_control <-- 000
    * data_memory_enable
    * next_state <-- middle_state after memory done
* middle_state:
    * reg_a_src <-- 1
    * write_register_src <-- 11
    * write_register_data_src <-- 11
    * write_register_enable
    * if (stxr_try == 1):
        next_state <-- fetch 
      else 
        next_state <-- final_state
* final_state:
    * reg_a_src <-- 0
    * reg_b_src <-- 1 
    * alu_control <-- 000
    * data_memory_enable
    * data_memory_src_write_en
    * next_state <-- fetch after memory done

if (Data_memory(Register_File(instruction[9:5])) == Register_File(Monitor)):
    Data_memory(Register_File(instruction[9:5])) <-- Register_File(instruction[4:0])
    Register_File(instruction[20:16]) <-- 1
else
    Register_File(instruction[20:16]) <-- 0
