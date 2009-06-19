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
		signal rs232_clk: out std_logic
		-- rs232_speed = 115200 baud per sec
		--signal rs232_clk: out std_logic;
	);
end rs232clk;

architecture arch of rs232clk is
		constant BaudInc: integer := 151;
		signal BaudSignal: bit_vector (0 to 16);

-- bit_vector to integer
function bitv2int( X: bit_vector ( 0 to 16 ) )
	return integer is variable tmp: integer range 0 to 2**16 := 0;	
begin
	for i in 0 to X'length - 1 loop
		if X(i) = '1' then
			tmp := tmp + 2**i;
		end if;
	end loop;

	return tmp;
end bitv2int;

-- integer to bit_vector
function int2bitv( X: integer range 0 to 2**16)
	return bit_vector is 
		variable tmp: bit_vector ( 0 to 16 );
		variable power_of_two: integer range 0 to 2**16 ;
		variable sum: integer range 0 to 2**16 := 0 ;
begin
	sum := X;
	for i in tmp'length - 1 downto 0 loop
		power_of_two := 2**i;
		if( sum > power_of_two) then
			sum := sum - power_of_two;
			tmp(i) := '1';
		else
			tmp(i) := '0';
		end if;
	end loop;
	
	return tmp;
end int2bitv;

begin

baud_generator: process(clk)
	variable tmp_int: integer range 0 to 2**16 := 0;
	--variable tmp_bit: bit_vector (0 to 16) := (others => '0'); 
begin

	if rising_edge(clk) then
		if(BaudSignal(16) = '0') then
			tmp_int := bitv2int(BaudSignal);
			tmp_int := tmp_int + BaudInc;
			--tmp_bit := int2bitv(tmp_int);
			BaudSignal <= int2bitv(tmp_int);
			rs232_clk <= '0' ;
		else
			BaudSignal <= int2bitv(0);
			rs232_clk <= '1';
		end if ;
	end if ;

end process baud_generator;

end arch;
