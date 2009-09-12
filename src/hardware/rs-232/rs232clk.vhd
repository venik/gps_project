-----------------------------------------------------------
-- Clock generator for rs232 interface
--
--  --------------
--  |   Baud     | -->	rs232clk - clock for rs232	
--  | generator  | <--	clk - just clock 
--  --------------
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Declaration part
entity rs232clk is
	Port (
		clk : in STD_LOGIC ;
		rs232_clk: out std_logic ;
		rs232_middle_clk: out std_logic
	);
end rs232clk;

architecture arch of rs232clk is
		signal NewBaudSignal: integer range 0 to 433 ;

begin

baud_generator: process(clk)

begin
	if rising_edge(clk) then
	
		NewBaudSignal <= NewBaudSignal + 1;
		
		if( NewBaudSignal = 433 ) then
			NewBaudSignal <= 0;
			rs232_clk <= '1';
			rs232_middle_clk <= '1' ;
			
		elsif( NewBaudSignal = 325 ) then 
			rs232_clk <= '1';
			rs232_middle_clk <= '0' ;
			
		elsif( NewBaudSignal = 216 ) then
			rs232_clk <= '0';
			rs232_middle_clk <= '1' ;
			
		elsif( NewBaudSignal = 109 ) then
			rs232_clk <= '0';
			rs232_middle_clk <= '0' ;
			
		end if ;
		
	end if ;
	
end process baud_generator;

end arch;
