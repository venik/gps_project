-----------------------------------------------------------
-- Name:	gps arbiter 
-- Description:	get data from gps and store in sram, after
--		sram is full send it via rs232
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity arbiter is
    	Port (
			-- sram
			addr_a: out std_logic_vector(17 downto 0) ;
			data_f2s: out std_logic_vector(7 downto 0) ;
			--data_s2f_r, data_s2f_ur: in std_logic_vector(7 downto 0) ;\
			data_s2f: in std_logic_vector(7 downto 0) ;
			ready: in std_logic ;
			rw: out std_logic ;
			mem: out std_logic ;
			
			-- rs232
			rs232_in: in std_logic ;
			rs232_out: out std_logic ;
			
			--system
			clk : in std_logic ;
			u10 : out  std_logic_vector (7 downto 0) ;
			u9 : out  std_logic_vector (7 downto 0) ;
			u8 : out  std_logic_vector (7 downto 0) ;
			reset : in std_logic ;
			mode: out std_logic_vector(1 downto 0) ;

			-- GPS
			cs_a : out std_logic ;
			sclk_a : out std_logic ;
			sdata_a : out std_logic ;
			gps_start_a : out std_logic ;
			gps_done_a : in std_logic ;
			
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
	signal	din : std_logic_vector (7 downto 0) ; 
	signal comm: std_logic_vector (63 downto 0) := (others => '0') ;	
	
	-- local
	type arbiter_type is(idle, parse_comm, after_write, after_read, send_comm, waite_for_gps, waite_for_gps_data, wait_for_mem_test) ;
	signal arbiter_state: arbiter_type := idle ;
	signal arbiter_next_state: arbiter_type := idle ;
		
	-- GPS
	signal gps_word_a: std_logic_vector (31 downto 0) := (others => '0') ;	
	signal program_gps_a: std_logic := '0' ;
	signal gps_programmed_a: std_logic := '0' ;
	
	signal soft_reset: std_logic := '0' ;
	--signal addr_a_int: std_logic_vector(17 downto 0) := ( others => '0' ) ;	
	-- SRAM
	signal result: unsigned (17 downto 0) := (others => '0') ;
		
begin

rs232rx_unit: entity work.rs232_rx_new(rs232_rx_new)
	port map(
		clk => clk,
		u9_rx => u9,
		comm => comm,
		rx_done_tick => rx_done_tick,
		rs232_in => rs232_in
	);

rs232tx_unit: entity work.rs232_tx_new(rs232_tx_new)
	port map(
		clk => clk,
		din => din,
		u8_tx => u8,
		rs232_out => rs232_out,
		tx_start => tx_start,
		tx_done_tick => tx_done_tick
	);
			
gps_serial_unit: entity work.gps_serial(gps_serial)
	port map(
			cs_s => cs_a,
			sclk_s => sclk_a,
			sdata_s => sdata_a,
			gps_word_s => gps_word_a,
			program_gps_s => program_gps_a,
			gps_programmed_s => gps_programmed_a,
			clk => clk
		) ;


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
	
process(arbiter_state, clk, tx_done_tick, rx_done_tick, test_result, ready)
begin
	if rising_edge(clk) then
		case  arbiter_state is

--		-- idle - waiting for incomming command
		when idle =>
			if( rx_done_tick = '1' ) then				
				arbiter_next_state <=  parse_comm ;
				--arbiter_next_state <=  send_comm ;
				--din <= comm(7 downto 0) ;
				--tx_start <= '1';
			else 
				u10 <= X"40" ;				-- 0
				tx_start <= '0';
			end if ;
			
			-- disable rs232 tx and sram , set arbiter drive bus mode and no test mem
			mode <= "00";
			tx_start <= '0';
			mem <= '0' ;
			rw <= '0' ;
			addr_a(17 downto 0) <=  ( others => '0' );
			result(17 downto 0) <= (others => '0');
			test_mem <= '0';
			program_gps_a <= '0' ;
			gps_start_a <= '0' ;
		
		-- parse the incomming command and do something
		when parse_comm =>
				u10 <= X"79" ;				-- 1
				
				case comm(7 downto 0) is
				when "00000001" => 
					-- send to the GPS serial
					mode <= "00" ;
					gps_word_a <= comm(39 downto 8) ;
					mem <= '0' ;
					program_gps_a <= '1' ; 	
					arbiter_next_state <= waite_for_gps;
				
				when "00000011" => 
					-- get gps data
					mode <= "10" ;
					arbiter_next_state <= waite_for_gps_data;
					gps_start_a <= '1' ;
				
				when "00000010" =>
					-- test sram
					test_mem <= '1' ;
					mode <= "01" ;
					arbiter_next_state <= wait_for_mem_test;
					
				when "10101010" =>
					-- rs232 echo-test
					arbiter_next_state <=  send_comm ;
					tx_start <= '1' ;
					din <= comm(7 downto 0) ;
					mem <= '0' ;
					mode <= "00" ;
									
				-- work with memory
				when "00000100" =>
				if( ready = '1') then
					-- write
					mode <= "00" ;
					addr_a <= comm(25 downto 8) ;
					data_f2s <= comm(33 downto 26) ;
					mem <= '1' ;
					rw <= '1' ;	
					arbiter_next_state <= after_write;
				end if;	 
				
				when "00000101" =>
				-- ZEROOOOO mem	 FIXME
				mode <= "00" ;
				--data_f2s <= ( others => '0' );
				--data_f2s <= ( others => '1' );
				data_f2s <= std_logic_vector(result( 7 downto 0 ));
				rw <= '1' ;
													
				if( result(17 downto 0) = X"3FFFF" ) then	
				--if( addr_a_int(17 downto 0) = X"3FFFF" ) then
					-- already ZEROOOOed
					arbiter_next_state <= send_comm;
					din <= comm(7 downto 0) ;
					--result <= ( 0=>'1', others => '0' );
					result <= X"0000" & b"01" ;
					addr_a <= ( others => '0' );
					
					tx_start <= '1';
				else 
					if( ready = '1') then
						mem <= '1' ;	
						addr_a <= std_logic_vector(result);
						--addr_a <= addr_ant + '1';
						--result <= result + one;
						--result <= result + ( X"0000" & b"01" );
						result <= result + 1;
						--result <= one;
					  else 
						mem <= '0' ;
					end if;
				end if;
			
				when "00001000" =>
				if( ready = '1') then
					-- read
					mode <= "00" ;
					addr_a <= comm(25 downto 8) ;
					mem <= '1' ;
					rw <= '0' ;
					arbiter_next_state <= after_read;
				end if;
					
				when others =>
					-- unknown command
					arbiter_next_state <=  send_comm ;
					tx_start <= '1' ;
					u10 <= comm(7 downto 0) ;
					-- on unknown command - send 0xFF
					din <= ( others => '1' ) ;
					mem <= '0' ;
					mode <= "00" ;
									
				end case;
				
	when wait_for_mem_test =>
		-- wait for end of the memory test
		test_mem <= '0' ;
		if( test_result = "11" ) then
			-- =) error occur
			arbiter_next_state <=  send_comm ;
			tx_start <= '1' ;
			din <= not(comm(7 downto 0)) ;
			mode <= "00" ;
			mem <= '0';
		elsif(test_result = "10") then
			-- =) memory is good
			arbiter_next_state <=  send_comm ;
			tx_start <= '1' ;
			din <= comm(7 downto 0) ;
			
			mode <= "00" ;
			mem <= '0';
		end if;
	
	-- wait for writing data			
	when after_write =>
		u10 <= X"24" ;				-- 2
		
		if( ready = '1') then
			din <= comm(7 downto 0);
			tx_start <= '1' ;		
			arbiter_next_state <= send_comm;
		end if;
	
	
	-- wait for reading data			
	when after_read =>
		u10 <= X"30" ;				-- 3
		mem <= '0' ;
		
		if( ready = '1') then
			din <= data_s2f ;
			tx_start <= '1' ;
			arbiter_next_state <= send_comm;
		end if;
		
-- GPS states
	when waite_for_gps =>
		-- wait for the GPS data
		
		program_gps_a <= '0' ;

		if( gps_programmed_a = '1') then
			din <= comm(7 downto 0) ;
			arbiter_next_state <= send_comm;
			tx_start <= '1' ;
		end if;
		
		
	when waite_for_gps_data =>
		u10 <= X"99" ;				-- 3
		gps_start_a <= '0' ;
		
		if( gps_done_a = '1') then
			din <= comm(7 downto 0) ;
			arbiter_next_state <= send_comm;
			tx_start <= '1' ;
			
			mode <= "00" ;
			mem <= '0' ;
		end if;

-- RS232 states
	-- send_comm			
	when send_comm =>
			-- disable memory test block
			mem <= '0' ;
			
			-- activate the rs232 interface for transfer
			--tx_start <= '1';
			tx_start <= '0';
			
			if( tx_done_tick = '1' ) then
				arbiter_next_state <= idle ;
			end if;
			
		end case;

	end if; --  if rising_edge(clk)

end process;

end Behavioral ;
