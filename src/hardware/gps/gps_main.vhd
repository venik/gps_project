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
			test_spot_m: out std_logic ;
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
	type   gps_get_data_type is(idle, get_lsb, get_msb) ;
	signal gps_state, gps_next_state: gps_get_data_type := idle ;
		
	signal data_mem: std_logic_vector (7 downto 0) := (others => '0') ;
	--signal one: unsigned(17 downto 0) := (0=>'1', others => '0') ;
	signal result: unsigned(17 downto 0) := (others => '0') ;
	
	-- new signals
	signal c_in: std_logic := '0' ;
	signal c_1: std_logic := '0' ;
	signal c_2: std_logic := '0' ;
	signal gps_tick: std_logic := '0' ;
	
begin

process(clk)
begin
if rising_edge(clk) then
	c_in <= gps_clkout_m ;
	c_1 <= c_in;
	c_2 <= c_1;
	
	gps_tick <= c_2 and (not c_1) ;
	--test_spot_m <= result(0);
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
	gps_state <= gps_next_state ;
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
		gps_done_m <= '0' ;
		
		case gps_state is
		
		when idle =>
			addr_m(17 downto 0) <= (others => '0');
			data_mem(7 downto 0) <= (others => '0');
			result(17 downto 0) <= (others => '0');
			mem_m <= '0' ;
			--test_spot_m <= '0' ;
			
			if( gps_start_m = '1' ) then
				gps_next_state <= get_lsb ;
				rw_m <= '1' ;
				--mem_m <= '1' ;
			end if;
			
		when get_lsb =>
			test_spot_m <= '1' ;
			
			if( result(17 downto 0) = X"3FFFF" ) then
				-- memory is full - exit
				gps_done_m <= '1' ;
				gps_next_state <= idle ;
				mem_m <= '0' ;
					
			elsif( gps_tick = '1' ) then
					data_mem(3 downto 0) <= q_m & i_m ;
					addr_m <= std_logic_vector(result);
					--result <= result + one;
					result <= result + ( X"0000" & b"01" );
					
					gps_next_state <= get_msb ;
					
					-- try to write
					if(ready_m = '1' ) then
						mem_m <= '1' ;
						data_f2s_m <= data_mem;
					else 
						mem_m <= '0' ;
					end if;
			end if;
		
		when get_msb =>
			test_spot_m <= '0' ;
			
			if( gps_tick = '1' ) then
				data_mem(7 downto 4) <= q_m & i_m ;
				gps_next_state <= get_lsb ;
			end if;
			
		end case; -- case gps_state					
end if;
end process;

end gps_main;