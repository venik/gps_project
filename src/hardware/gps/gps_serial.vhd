library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity gps_serial is
			Port (
			-- gps
			cs_s : out std_logic ;
			sclk_s : out std_logic ;
			sdata_s : out std_logic ;
			-- data
			gps_word_s : in std_logic_vector (31 downto 0) ;
			program_gps_s : in std_logic ;
			gps_programmed_s : out std_logic ;
			-- system
			clk : in std_logic ;
			soft_reset : in std_logic
		) ;
end gps_serial;

architecture gps_serial of gps_serial is
	type   gps_serial_type is(idle, data, data_lsb, addr_msb, addr_lsb, data_done) ;
	signal gps_serial_state: gps_serial_type := idle ;
	signal gps_serial_state_next: gps_serial_type := idle ;
	
	signal gps_clk_serial: std_logic ;
	signal gps_clk_serial_middle: std_logic ;
	signal gps_counter: integer range 0 to 32 := 32 ;
	signal gps_cycle: integer range 0 to 2 := 0 ;
begin

gps_clk_uplevel: entity work.gps_clk(gps_clk)
port map( 
			clk => clk,
			gps_clk => sclk_s,
			gps_clk_local_middle => gps_clk_serial_middle,
			gps_clk_local => gps_clk_serial
		);	

process(clk)
begin								 
	
  	if( rising_edge(clk) ) then 
		gps_serial_state <= gps_serial_state_next ;
	end if ;
	
end process;		

process(gps_serial_state, gps_clk_serial_middle, program_gps_s)
begin
if rising_edge(gps_clk_serial_middle) then
	
	case  gps_serial_state is
	when idle =>
		if program_gps_s = '1' then
			gps_serial_state_next <= data;
			gps_counter <= 32 ;
			cs_s <= '0' ;
			gps_cycle <= 0;
		else 
			cs_s <= '1' ;
		end if;
		
		gps_programmed_s <= '0' ;
		
	when data =>
		if(gps_counter = 0) then
			gps_serial_state_next <= data_done ; 
			cs_s <= '1' ;
		else
			if(gps_cycle = 1) then
				gps_counter <= gps_counter - 1 ;
				gps_cycle <= 0;
			else
				gps_cycle <= gps_cycle + 1;
			end if;
			
			sdata_s <= gps_word_s(gps_counter - 1) ;
			--sdata <= '1';
		end if;
		
	when data_done =>
		gps_serial_state_next <= idle ;
		gps_programmed_s <= '1';
	
	when others => NULL ;
	end case ;
	
end if;
end process;

end gps_serial;
