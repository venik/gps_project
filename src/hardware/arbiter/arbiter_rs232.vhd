-----------------------------------------------------------
-- Name:	gps arbiter 
-- Description:	get data from gps and store in sram, after
--		sram is full send it via rs232
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity arbiter_rs232 is
    	Port (
			-- rs232
			rs232_in: in std_logic ;
			rs232_out: out std_logic ;
			
			--system
			clk : in std_logic ;
			u10 : out  std_logic_vector (7 downto 0) ;
			reset : in std_logic
	     );
end arbiter_rs232;

architecture Behavioral of arbiter_rs232 is
	-- rs232
	signal	rx_done_tick : std_logic := '0' ;
	signal	tx_done_tick : std_logic ;
	signal	tx_start : std_logic ;
	signal	din : std_logic_vector (7 downto 0) ; 

	-- local
	type arbiter_type is(idle, parse_comm, send_comm, wait_comm) ;
	signal arbiter_state: arbiter_type := idle ;
	signal arbiter_next_state: arbiter_type := idle ;
	
	signal soft_reset: std_logic := '0' ;
	signal comm: std_logic_vector (63 downto 0) := (others => '0') ;	
	signal byte: std_logic_vector (7 downto 0) := "00000001" ;		
begin

rs232main_unit: entity work.rs232main(arch)
	port map( clk => clk,
				 soft_reset => soft_reset,
				 comm => comm,
				 din => din,
			    rs232_in => rs232_in,
				 rs232_out => rs232_out,
		       rx_done_tick => rx_done_tick,
				 tx_done_tick => tx_done_tick, 
		       tx_start => tx_start
			);
			
process(clk, reset)
begin
	arbiter_state <= arbiter_next_state ;
end process;
	
process(arbiter_state, clk, tx_done_tick, rx_done_tick)
begin
	if rising_edge(clk) then
		case  arbiter_state is

--		-- idle - waiting for incomming command
		when idle =>
			if( rx_done_tick = '1' ) then				
				arbiter_next_state <=  parse_comm ;
			else 
				u10 <= X"40" ;				-- 0
				--arbiter_next_state <=  send_comm ;
				--din <= X"AA" ;
			end if ;
			
			-- disable rs232 tx and sram , set arbiter drive bus mode and no test mem
			tx_start <= '0';
		
		-- parse the incomming command and do something
		when parse_comm =>
				u10 <= X"79" ;				-- 1
				
				case comm(7 downto 0) is
				when "00000001" =>
					if( rx_done_tick = '0' ) then				
						--din <= comm(7 downto 0) ;
						din <= byte;
						arbiter_next_state <= send_comm;
				end if;
				
--				others
				when others =>
				
				if( rx_done_tick = '0' ) then
					-- unknown command
					u10 <= comm(7 downto 0) ;
				end if;
					
				end case;
				
-- RS232 states
	-- send_comm			
	when send_comm =>
   		-- activate the rs232 interface for transfer
			tx_start <= '1';
			
			if( tx_done_tick = '1' ) then
					arbiter_next_state <= wait_comm;
										
					byte <= byte(6 downto 0) & byte(7);
					
			end if;
			
		
		
	when wait_comm =>
		tx_start <= '0' ;
	
			if( tx_done_tick = '0' ) then
					arbiter_next_state <= send_comm;
					din <= byte;
			end if;	
			
	end case;
	
	end if; --  if rising_edge(clk)

end process;

end Behavioral ;
