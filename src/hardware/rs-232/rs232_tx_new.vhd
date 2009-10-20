-----------------------------------------------------------
-- TX rs232 module for FPGA
--
--  --------------
--  |            | -->	rs232_out - out in hardware port
--  |            | <--	din - input byte
--  |   rs232    | <--	tx_start - signal to start transfer
--  |    tx      | -->	tx_done_tick - transfer done
--  |            | <--	reset - you know what is it
--  |            | <--	clk - tick-tack
--  |            | <--	rs232_clk - clk at 115200 bits/sec speed 
--  --------------
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rs232_tx_new is
	Port (
		clk : in STD_LOGIC ;
		--u10 : out  STD_LOGIC_VECTOR (7 downto 0) ;
		din : in STD_LOGIC_VECTOR (7 downto 0) ; 
		rs232_out : out std_logic ;
		tx_done_tick : out std_logic ;
		tx_start : in std_logic
	);
end rs232_tx_new;

architecture rs232_tx_new of rs232_tx_new is
	-- FSM part
	type rs232_tx_type is(tx_idle, tx_startbit, tx_databits, tx_stopbit);
	signal rs232_tx_state, rs232_tx_next_state: rs232_tx_type;
	
	-- compare part
	signal	NewBaudSignal: integer range 0 to 433 ;
	signal	rst_NewBaudSignal: std_logic := '0' ; 
	signal	rs232_tx_tick: std_logic := '0' ;
	
	-- tx part
	signal rs232_tx_counter: integer range 0 to 8 := 0;
	signal rs232_tx_value: std_logic_vector (7 downto 0) := ( others => '0') ;
		
begin
	
-- next state logic
process(clk)
begin
	
if rising_edge(clk) then
	rs232_tx_state <= rs232_tx_next_state ;
	rs232_tx_tick <= '0' ;
	
	if( rst_NewBaudSignal = '1' ) then
		NewBaudSignal <= 0;
	elsif( NewBaudSignal = 433 ) then
		NewBaudSignal <= 0;
		rs232_tx_tick <= '1';
	else 
		NewBaudSignal <= NewBaudSignal + 1;
	end if;
end if;

end process;

-- -- next state logic 
process(clk, tx_start, rs232_tx_state)
begin
if rising_edge(clk) then
	tx_done_tick <= '0' ;
	rst_NewBaudSignal <= '0' ;
	
	case rs232_tx_state is
		-- -- idle
		when tx_idle =>
			rs232_out <= '1';
			
			if tx_start = '1' then
				rs232_tx_next_state <= tx_startbit;
				rs232_tx_value <= din;
				rst_NewBaudSignal <= '1' ;
				rs232_tx_counter <= 0;
			end if;
		
		-- -- start bit
		when tx_startbit =>
			rs232_out <= '0' ;				
		
			if rs232_tx_tick = '1' then
				rs232_tx_next_state <= tx_databits;
			end if;	   
			
		-- -- data bits
		when tx_databits =>
			rs232_out <= rs232_tx_value(rs232_tx_counter);
			
			if rs232_tx_tick = '1' then
			
				if (rs232_tx_counter + 1) = 8 then
					rs232_tx_next_state <= tx_stopbit;
					rs232_out <= '1' ;
				else
					rs232_tx_counter <= rs232_tx_counter + 1;
					rs232_out <= rs232_tx_value(rs232_tx_counter + 1);
				end if;
			
			end if;
			
		-- -- start bit
		when tx_stopbit => 
			rs232_out <= '1' ;
		
			if rs232_tx_tick = '1' then
				rs232_tx_next_state <= tx_idle;
				rs232_out <= '0' ;
				tx_done_tick <= '1' ;
			end if;	   	
		
	end case;
end if;	  
end process;

end rs232_tx_new;
