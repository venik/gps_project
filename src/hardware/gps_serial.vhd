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
			clk : in std_logic
		) ;
end gps_serial;

architecture gps_serial of gps_serial is
	type   gps_serial_type is(idle, data, data_done) ;
	signal gps_serial_state: gps_serial_type := idle ;
	signal gps_serial_state_next: gps_serial_type := idle ;
	
	signal gps_counter: integer range 0 to 32 := 32 ;
	signal rst_idle: std_logic := '1' ;
	
	signal NewGPSSignal: integer range 0 to 4 := 0 ;
	
begin

process(clk)
begin								 
if( rising_edge(clk) ) then 
	-- fsm
	gps_serial_state <= gps_serial_state_next ;
	
	if( rst_idle = '0' ) then 
		
		NewGPSSignal <= NewGPSSignal + 1;
		
		-- clock generator
		if( NewGPSSignal = 0 ) then
			sclk_s <= '0';
		elsif( NewGPSSignal = 1 ) then 
			sclk_s <= '0';
		elsif( NewGPSSignal = 2 ) then
			sclk_s <= '1';
		else 
			sclk_s <= '1';
			NewGPSSignal <= 0 ;
		end if;	
	else 
		-- in the idle state
		sclk_s <= '0' ;
		NewGPSSignal <= 1 ;
	end if;
		
end if ;
end process;		

-- FSM
process(gps_serial_state, clk, program_gps_s)
begin
if rising_edge(clk) then
	
	case  gps_serial_state is
	when idle =>
		if program_gps_s = '1' then
			gps_serial_state_next <= data;
			gps_counter <= 32 ;
			cs_s <= '0' ;
			rst_idle <= '0';
			sdata_s <= gps_word_s(gps_counter - 1) ;
		else 
			cs_s <= '1' ;
			rst_idle <= '1' ;
			--sdata_s <= '0' ;
		end if;
		
		gps_programmed_s <= '0' ;
		
	when data =>
	
		if(gps_counter = 0) then
			-- all done
			gps_serial_state_next <= data_done ; 
			cs_s <= '1' ;
			rst_idle <= '1' ;
		else
			cs_s <= '0' ;
			if(NewGPSSignal = 0) then
				gps_counter <= gps_counter - 1 ;
			end if;
			
			sdata_s <= gps_word_s(gps_counter - 1) ;
			
		end if;
		
	when data_done =>
		gps_serial_state_next <= idle ;
		gps_programmed_s <= '1';
	
	when others => NULL ;
	end case ;
	
end if;
end process;

end gps_serial;
