-----------------------------------------------------------
-- Name:	gps main
-- Description: get the data from GPS and store it in the SRAM
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity gps_main is
	Port (
			-- gps
			q_m: in std_logic_vector(1 downto 0) ;
			i_m: in std_logic_vector(1 downto 0) ;
			gps_clkout_m: in std_logic ;
			-- control
			gps_start_m : in std_logic ;
			gps_done_m : out std_logic ;
			-- sram
			addr_m: out std_logic_vector(17 downto 0) ;
			data_f2s_m: out std_logic_vector(7 downto 0) ;
			--data_s2f_r_m, data_s2f_ur_m: in std_logic_vector(7 downto 0) ;
			ready_m: in std_logic ;
			rw_m: out std_logic ;
			mem_m: out std_logic ;
			-- system
			clk : in std_logic
	);
end gps_main;

architecture gps_main of gps_main is
	type   gps_get_data_type is(idle, get_lsb, get_msb, write) ;
	signal gps_state, gps_next_state: gps_get_data_type := idle ;
	
	signal data_mem: std_logic_vector (7 downto 0) := (others => '0') ;
	signal one: unsigned(17 downto 0) := (0=>'1', others => '0') ;
	signal result: unsigned(17 downto 0) := (others => '0') ;
begin
	
process(clk)
begin								 
	
  	if( rising_edge(clk) ) then 
		gps_state <= gps_next_state ;
	end if ;
		
end process;

process(gps_state, clk)
begin
if rising_edge(clk) then		
	
		case gps_state is
		
		when idle =>
			if( gps_start_m = '1' ) then
				gps_next_state <= get_lsb ;
				data_f2s_m <= data_mem(7 downto 0) ;
				mem_m <= '1';
				rw_m <= '1' ;
				addr_m(17 downto 0) <= (others => '0');
			else 
				mem_m <= '0' ;
				data_mem(7 downto 0) <= (others => '0');
				gps_done_m <= '0' ;
			end if;
			
		when get_lsb => 
			if( gps_clkout_m = '1' ) then
				data_mem(3 downto 0) <= q_m & i_m ;
					
				if( result(17 downto 0) = x"1111" & b"1" ) then
					-- bytes are full - exit
					gps_next_state <= idle ;
					mem_m <= '0' ;
					gps_done_m <= '1' ;
				else
					-- increment address
					mem_m <= '1' ;
					addr_m <= std_logic_vector(result);
					result <= result + one;
					gps_next_state <= get_msb ;
				end if;

			end if;
		
		when get_msb => 
			if( gps_clkout_m = '1' ) then
				data_mem(7 downto 4) <= q_m & i_m ;
				gps_next_state <= get_lsb ;
			end if;
			
		when others => NULL;
			
		end case; -- case gps_state					   
			
-- ----------------------------------------------------			

		if( gps_state = get_lsb ) then
			-- need write data
			data_f2s_m <= data_mem;
			
			if(ready_m = '1' ) then
				mem_m <= '1' ;
			else 
				mem_m <= '0' ;
			end if;
			
		end if;
	
end if;		
end process;

end gps_main;
