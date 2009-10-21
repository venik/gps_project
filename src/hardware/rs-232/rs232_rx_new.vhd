-----------------------------------------------------------
-- TX rs232 module for FPGA
--
--  --------------
--  |            | <--	rs232_in - hardware port
--  |            | -->	
--  |   rs232    | -->	rx_done_tick - receive done
--  |    rx      | <--	reset - you know what is it
--  |            | <--	clk - tick-tack
--  |            | <--	
--  --------------
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rs232_rx_new is
	Port (
		clk : in STD_LOGIC ;
		u9_rx : out  STD_LOGIC_VECTOR (7 downto 0) ;
		comm: out std_logic_vector (63 downto 0) ;		
		rx_done_tick : out std_logic ;
		rs232_in: in std_logic 
	);
end rs232_rx_new;

architecture rs232_rx_new of rs232_rx_new is
	-- FSM part
	type rs232_type is(rx_idle, rx_start, rx_data, rx_stop);
	signal rs232_rx_state, rs232_rx_next_state: rs232_type;
	
	-- compare part
	signal	NewBaudSignal: integer range 0 to 435 ;
	signal	rst_NewBaudSignal: std_logic := '0' ; 
	signal	rst_start_bit: std_logic := '0' ;
	signal	rs232_rx_tick: std_logic := '0' ;
	
	-- rx part
	signal rs232_counter: integer range 0 to 8 := 0;
	signal rs232_value: std_logic_vector (7 downto 0) := ( others => '0') ;
	signal byte_counter: integer range 0 to 63;
begin

-- comapre module
process(NewBaudSignal, clk)
begin					
	
if rising_edge(clk) then

	rs232_rx_state <= rs232_rx_next_state ;
	
	if( rst_NewBaudSignal = '1' or rst_start_bit = '1' ) then
		NewBaudSignal <= 0;
		rst_NewBaudSignal <= '0' ;
	else
		NewBaudSignal <= NewBaudSignal + 1;
	
		if( NewBaudSignal >= 433 ) then
			rst_NewBaudSignal <= '1' ;
			rs232_rx_tick <= '0' ;
		elsif ( NewBaudSignal = 216 ) then
		--elsif ( NewBaudSignal = 300 ) then
			rs232_rx_tick <= '1' ;
			rst_NewBaudSignal <= '0' ;
		else 
			rs232_rx_tick <= '0' ;
			rst_NewBaudSignal <= '0' ;
		end if;
	end if;		

end if;
	
end process;

-- FSM
process(clk, rs232_in, rs232_rx_tick, rst_NewBaudSignal)
begin
if rising_edge(clk) then
	
	rx_done_tick <= '0' ;
	
	case rs232_rx_state is
	-- idle
	when rx_idle =>
	
		u9_rx <= X"40" ;				-- 0
		rst_start_bit <= '1' ;
		
		if( rs232_in = '0' ) then
    		rs232_rx_next_state <= rx_start; 
    		rs232_counter <= 0 ;
			--rst_start_bit <= '1' ;
		end if;
	
	-- skip the start bit
 	when rx_start =>
	 
	 	rst_start_bit <= '0' ;
		u9_rx <= X"79" ;				-- 1
	 
	 	if( rs232_rx_tick = '1' ) then
			rs232_rx_next_state <= rx_data ; 
		end if;
		
	-- data bits
 	when rx_data =>
	
    u9_rx <= X"24" ;				-- 2       
	 
    if( rs232_counter = 8 ) then 
		-- move to finish
    	rs232_rx_next_state <= rx_stop;
    elsif( rs232_rx_tick = '1' ) then 
    	rs232_value(rs232_counter) <= rs232_in;
    	rs232_counter <= rs232_counter + 1 ;
    end if;
	
	-- stop bit
	when rx_stop =>
	
		u9_rx <= X"30" ;				-- 3
		
		--if( rs232_in = '1' )then
			if( rs232_rx_tick = '1' ) then
							
				rs232_rx_next_state <= rx_idle ;
				comm((byte_counter + 7) downto byte_counter) <= rs232_value ;
				
				-- byte counter for 64 bits input comm
				--if( byte_counter = 56 ) then
				if( byte_counter = 0 ) then
					byte_counter <= 0 ;
					rx_done_tick <= '1' ;
				else 
					byte_counter <= byte_counter + 8;
				end if ;
				
			end if;
		--end if;
		
		
		
	end case;
	
end if;
end process;
	
end rs232_rx_new;
