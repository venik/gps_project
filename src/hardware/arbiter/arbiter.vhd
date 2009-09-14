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

entity arbiter is
    	Port (
			-- sram
			addr: out std_logic_vector(17 downto 0) ;
			data_f2s: out std_logic_vector(7 downto 0) ;
			data_s2f_r, data_s2f_ur: in std_logic_vector(7 downto 0) ;
			ready: in std_logic ;
			rw: out std_logic ;
			mem: out std_logic ;
			
			-- rs232
			rs232_in: in std_logic ;
			rs232_out: out std_logic ;
			
			--system
			clk : in std_logic ;
			u10 : out  std_logic_vector (7 downto 0) ;
			reset : in std_logic ;
			mode: out std_logic_vector(1 downto 0) ;			
			
			-- signal
			test_mem: out std_logic ;
			test_result: in std_logic_vector(1 downto 0)
	     );
end arbiter;

architecture Behavioral of arbiter is
	-- rs232
	signal	rx_done_tick : std_logic := '0' ;
	signal	tx_done_tick : std_logic ;
	signal	tx_start : std_logic ;
	--signal	dout : std_logic_vector (7 downto 0) ; 
	signal	din : std_logic_vector (7 downto 0) ; 

	-- local
	type arbiter_type is(idle, parse_comm, after_write, after_read, send_comm) ;
	signal arbiter_state: arbiter_type := idle ;
	signal arbiter_next_state: arbiter_type := idle ;
	
	signal soft_reset: std_logic := '0' ;
	signal comm: std_logic_vector (63 downto 0) := (others => '0') ;	
		
begin

rs232main_unit: entity work.rs232main(arch)
	port map( clk => clk,
				 --u10 => u10,
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

	if( reset = '0') then				-- push the reset-button
		soft_reset <= '1' ;				-- reset submodules
		arbiter_state <= idle ;
	elsif rising_edge(clk) then
		soft_reset <= '0' ;
		arbiter_state <= arbiter_next_state ;
	end if;
	
end process;
	
process(arbiter_state, clk, tx_done_tick, rx_done_tick, test_result)
begin
	if rising_edge(clk) then
		case  arbiter_state is

--		-- idle - waiting for incomming command
		when idle =>
			if( rx_done_tick = '1' ) then				
				arbiter_next_state <=  parse_comm ;
			else 
				u10 <= X"24" ;				-- 2		   
			end if ;
			
			-- disable rs232 tx and sram , set arbiter drive bus mode and no test mem
			tx_start <= '0';
			mem <= '0' ;
			rw <= '0' ;
			addr(17 downto 0) <=  ( others => '0' );
			mode <= "00";
			test_mem <= '0';
		
		-- parse the incomming command and do something
		when parse_comm =>
		
				case comm(7 downto 0) is
--				when "00000001" => NULL ;
					-- set register
--					arbiter_next_state <= idle ;
--					mode <= "00" ;
					
				when "00000010" =>
					-- memory test
					
					u10 <= X"40" ;				-- 0

					if( test_result = "11" ) then
						-- =) error occur
						arbiter_next_state <=  send_comm ;
						din <= not(comm(7 downto 0)) ;
						test_mem <= '0' ;
						mode <= "00" ;
						mem <= '0';
					elsif(test_result = "10") then
						-- =) memory is good
						arbiter_next_state <=  send_comm ;
						din <= comm(7 downto 0) ;
						test_mem <= '0' ;
						mode <= "00" ;
						mem <= '0';
					elsif( test_result = "01") then 
						test_mem <= '0' ;
						mode <= "01" ;
					else 
						-- need start the memeory test
						test_mem <= '1' ;
						-- test drive SRAM signals
						mode <= "01" ;
					end if;
					
				when "10101010" =>
					-- rs232 echo-test
					u10 <= X"03" ;				-- 1
					arbiter_next_state <=  send_comm ;
					din <= comm(7 downto 0) ;
					mem <= '0' ;
					mode <= "00" ;
					test_mem <= '0' ;
				
				-- work with memory
				when "00000100" =>
				if( ready = '1') then
					-- write
					mode <= "00" ;
					addr <= comm(25 downto 8) ;
					data_f2s <= comm(33 downto 26) ;
					mem <= '1' ;
					rw <= '1' ;	
					arbiter_next_state <= after_write;
				end if;
				
				when "00001000" =>
				if( ready = '1') then
					-- read
					mode <= "00" ;
					addr <= comm(25 downto 8) ;
					mem <= '1' ;
					rw <= '0' ;
					arbiter_next_state <= after_read;
				end if;
					
				when others =>
					-- unknown command
					arbiter_next_state <=  send_comm ;
					-- on unknown command - send 0xFF
					din <= ( others => '1' ) ;
					mem <= '0' ;
					mode <= "00" ;
					
				end case;

	-- wait for writing data			
	when after_write =>
	if( ready = '1') then
		arbiter_next_state <= idle;
	end if;
	
	-- wait for reading data			
	when after_read =>
	if( ready = '1') then
		din <= data_s2f_r ;
		arbiter_next_state <= send_comm;
	end if;
		
	-- send_comm			
	when send_comm =>
			-- disable memory test block
			test_mem <= '0' ;
			mem <= '0' ;
			
			-- activate the rs232 interface for transfer
			tx_start <= '1';
			
			if( tx_done_tick = '1' ) then
					arbiter_next_state <= idle ;
			end if;
			
		end case;

	end if; --  if rising_edge(clk)

end process;

end Behavioral ;
