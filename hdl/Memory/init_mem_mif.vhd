package init_mem_mif is
	impure function init_mem(file_name : in string) return mem_type;
end package init_mem_mif;

package body init_mem_mif is
	impure function init_mem(file_name : in string) return mem_type is
	    file     f       : text open read_mode is file_name;
	    variable l       : line;
	    variable tmp_str : string(1 to 59); -- maximum line width is 59
	    variable index   : integer := 1;
	    variable read_ok : boolean := true;
	    variable addr_ok : boolean := false;
	    variable tmp_c   : character;
	    variable t_int   : integer;
	    variable t_bv    : bit_vector(31 downto 0);
	  begin
	      while not endfile(f) loop
		index := 1; addr_ok := false;
		readline(f, l);
		read(l, tmp_c, read_ok);
		while read_ok loop
		    if tmp_c = ':' then
		        t_int := integer'value(tmp_str(1 to index-1));
		        index := 1; addr_ok := true;
		    elsif tmp_c = ';' then
		        if addr_ok then
		          t_bv := hex2bit_vector(tmp_str(1 to index-1));
		          index := 1;
		          mem(t_int) := t_bv( 3 downto  0) & t_bv( 7 downto  4) &
		                        t_bv(11 downto  8) & t_bv(15 downto 12) &
		                        t_bv(19 downto 16) & t_bv(23 downto 20) &
		                        t_bv(27 downto 24) & t_bv(31 downto 28);
		          addr_ok := false;
		        end if;
		    else
		        if tmp_c /= ' ' then
		          tmp_str(index) := tmp_c;
		          index := index + 1;
		        end if;
		    end if;
		    read(l, tmp_c, read_ok);
		end loop;
	    end loop;
	    return mem;
	  end;
end package body init_mem_mif;
