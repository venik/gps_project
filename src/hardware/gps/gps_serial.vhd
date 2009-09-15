library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity gps_serial is
			Port (
			-- system
			clk : in std_logic ;
			reset : in std_logic
		) ;
end gps_serial;

architecture gps_serial of gps_serial is
	signal gps_clk_serial: std_logic ;
begin

gps_clk_uplevel: entity work.gps_clk(gps_clk)
port map( 
			clk => clk,
			gps_clk => gps_clk_serial
		);	

end gps_serial;
