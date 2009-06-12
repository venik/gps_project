library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity display is
    	Port (	clk : in STD_LOGIC ;
					rst : in STD_LOGIC ; -- FIXME ucf-file
					u10 : out STD_LOGIC_VECTOR (7 downto 0) ; 
					rs232_out : out std_logic := '1' ;
					rs232_in : in std_logic
	        );
end display;

architecture Behavioral of display is

	-- rs232 section
	-- Clk = 50MHz
	-- rs232_speed = 115200 baud per sec
	Constant BaudInc: integer := 151;
	type rs232_type is(idle, start, data, stop);
	signal rs232_state: rs232_type;
	--signal rs232_state: bit_vector (2 downto 0) := "111";
	signal BaudSignal: bit_vector (0 to 16);
	signal rs232_counter: integer range 0 to 8 := 0;
	--signal rs232_value: bit_vector (7 downto 0) := "10010010";
	signal rs232_value: bit_vector (7 downto 0) := X"41"; -- A - char
	
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
			if sum > power_of_two then
				sum := sum - power_of_two;
				tmp(i) := '1';
			else
				tmp(i) := '0';
			end if;
		end loop;
		
		return tmp;
	end int2bitv;


-- Main function
begin

show_digit: process(clk, rs232_value)
begin
	--u10 <= X"b0" ;
	u10 <= to_stdlogicvector(rs232_value) ;
end process;

--change_char: process(clk, rst)
--begin

--	if rising_edge(clk) then
--		if rst = '1' then
--			-- A <-> B vice-versa
--			if rs232_value = X"41" then
--				rs232_value <= X"42" ;
--			else
--				rs232_value <= X"41" ;
--			end if;
				
--		end if;
--	end if;
--end process;

baud_generator: process(clk)
	variable tmp_int: integer range 0 to 2**16 := 0;
	--variable tmp_bit: bit_vector (0 to 16) := (others => '0'); 
begin

	if rising_edge(clk) then
			if BaudSignal(16) = '0' then
				tmp_int := bitv2int(BaudSignal);
				tmp_int := tmp_int + BaudInc;
				--tmp_bit := int2bitv(tmp_int);
				BaudSignal <= int2bitv(tmp_int);
			else
				BaudSignal <= int2bitv(0);
			end if ;
	end if ;

end process baud_generator;

rs232_tx_proc: process(clk)
begin
	if rising_edge(clk) then
		if rst = '1' then

			-- Reset
			rs232_state <= idle ;

		elsif BaudSignal(16) = '1' then 

			case rs232_state is

			when idle =>
				rs232_out <= '1';	-- idle
				rs232_state <= start;

			when start =>
				rs232_out <= '0'; 	-- start bit
				rs232_state <= data;
				rs232_counter <= 0;

			-- data bit
			when data =>
				if rs232_counter = 8 then
					rs232_state <= stop;
				else
					rs232_out <= to_stdulogic(rs232_value(rs232_counter));
					--rs232_out <= '1' ;
					rs232_counter <= rs232_counter + 1 ;
				end if;
			
			when stop =>
				rs232_out <= '1' ;	-- stop bit
				rs232_state <= idle ;
								
			end case;
		end if; -- if BaudSignal(16) = '1'

	end if; --if rising_edge(clk)
	
end process rs232_tx_proc;
	
end Behavioral;



