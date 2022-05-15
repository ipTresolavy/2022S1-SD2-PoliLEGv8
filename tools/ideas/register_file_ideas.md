### Lendo dos registradores
- read_data_1 recebe reg_a_mux_out(to_integer(read_reg_a));
- read_data_2 recebe reg_b_mux_out(to_integer(read_reg_b));


### Escrevendo nos registradores
- todos os registradores têm suas entradas ligadas no register_data
- vetor de sinais reg_load de 32 bits;
    - valor do vetor será 0 quando reg_file_write for 0;
    - valor do vetor será 1 << to_integer(register_data) quando reg_file_write for 1;

### Entidade

entity register_file is
    port(
        read_reg_a              : in bit_vector(4 downto 0);
        read_reg_b              : in bit_vector(4 downto 0);
        write_reg               : in bit_vector(4 downto 0);
        write_data              : in bit_vector(63 downto 0);
        write                   : in bit;

        reg_a_data              : out bit_vector(63 downto 0);
        reg_b_data              : out bit_vector(63 downto 0);
    );
end entity register_file;


