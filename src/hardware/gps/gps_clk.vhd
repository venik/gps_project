library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity gps_clk is
		Port (
			-- system
			clk : in std_logic ;
			reset : in std_logic ;
			-- gps
			gps_clk: out std_logic
		);
end gps_clk;

architecture gps_clk of gps_clk is
	signal NewGPSSignal: integer range 0 to 4 := 0 ;
begin 
	
gps_clk_generator: process(clk)
begin
	if rising_edge(clk) then
	
		NewGPSSignal <= NewGPSSignal + 1;
		
		if( NewGPSSignal = 3 ) then
			NewGPSSignal <= 0;
			gps_clk <= '1';
			
		elsif( NewGPSSignal = 1 ) then
			gps_clk <= '0';
			
		end if ;
		
	end if ;
end process;

end gps_clk;
