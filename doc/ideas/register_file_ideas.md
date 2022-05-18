### Lendo dos registradores
- read_data_1 recebe reg_a_mux_out(to_integer(read_reg_a));
- read_data_2 recebe reg_b_mux_out(to_integer(read_reg_b));


### Escrevendo nos registradores
- todos os registradores têm suas entradas ligadas no register_data
- vetor de sinais reg_load de 32 bits;
    - valor do vetor será 0 quando reg_file_write for 0;
    - valor do vetor será 1 << to_integer(register_data) quando reg_file_write for 1;

### TODO
    - Reimplementar o reset dos registradores e adicioná-lo no banco de registradores
