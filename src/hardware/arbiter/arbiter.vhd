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
			-- rs232
			rs232_in: in std_logic ;
			rs232_out: out std_logic ;
			--sram
			address: out std_logic_vector(17 downto 0) ;
			dio_a: inout std_logic_vector(7 downto 0) ;
			s1, s2: out std_logic ;
			WE, OE: out std_logic ;
			--system
			clk : in std_logic ;
			u10 : out  std_logic_vector (7 downto 0) ;
			reset : in std_logic
	     );
end arbiter;

architecture Behavioral of arbiter is
	-- rs232
	signal	rx_done_tick : std_logic := '0' ;
	signal	tx_done_tick : std_logic ;
	signal	tx_start : std_logic ;
	signal	dout : std_logic_vector (7 downto 0) ; 
	signal	din : std_logic_vector (7 downto 0) ; 
	-- sram
	signal	mem: std_logic := '0';
	signal	rw: std_logic ;
	signal	addr: std_logic_vector(17 downto 0) ;
	signal 	data_f2s: std_logic_vector(7 downto 0) ;
	signal 	ready: std_logic := '0' ;
	signal	data_s2f_r, data_s2f_ur: std_logic_vector(7 downto 0) ;
	-- local
	type arbiter_type is(idle, write_sram, read_sram, send_comm) ;
	signal arbiter_state: arbiter_type := idle ;
	signal arbiter_next_state: arbiter_type := idle ;
	
	signal soft_reset: std_logic := '0' ;
	
	-- comm staff
	signal byte_counter: integer range 0 to 63;
	signal comm: std_logic_vector (63 downto 0) := ( others => '0') ;
	signal test_mem: std_logic_vector (7 downto 0) := ( others => '0') ;
	
begin

rs232main_unit: entity work.rs232main(arch)
	port map( clk => clk,
				 u10 => u10,
				 soft_reset => soft_reset,
				 dout => dout,
				 din => din,
			    rs232_in => rs232_in,
				 rs232_out => rs232_out,
		       rx_done_tick => rx_done_tick,
				 tx_done_tick => tx_done_tick, 
		       tx_start => tx_start
			);

sram_controller: entity work.sram_ctrl(arch)
  port map( clk => clk,
				soft_reset => soft_reset,
				mem => mem,
				rw => rw,
				addr => addr,
				data_f2s => data_f2s,
				ready => ready,
				data_s2f_r => data_s2f_r,
				data_s2f_ur => data_s2f_ur,
				address => address,
				dio_a => dio_a,
				s1 => s1,
				s2 => s2,
				WE => WE,
				OE => OE
			);
	
process(clk, reset)
begin

	if( reset = '0') then				-- push the reset-button
		soft_reset <= '1' ;
	elsif rising_edge(clk) then
		soft_reset <= '0' ;
		arbiter_state <= arbiter_next_state;
	end if;
	
end process;

process(arbiter_state, clk, tx_done_tick)
begin
	if rising_edge(clk) then
		case  arbiter_state is

--		-- idle	
		when idle =>
			if( rx_done_tick = '1' ) then
				--data_f2s <= dout ;
				comm((byte_counter + 7) downto byte_counter) <= dout ;
				
				if( byte_counter = 63 ) then
					-- check the command
					case comm(7 downto 0) is
						when "00000001" => NULL ;
							-- set register
							
						when "00000010" =>
							-- memory test
								if( test_mem < 7 ) then
									-- write into the memory test pattern
																
									if ready = '1' then
										addr(7 downto 0) <= test_mem ;
										data_f2s <= test_mem ;
										mem <= '1' ;	
										rw <= '1' ;
										test_mem <= test_mem + 1 ;
										
									end if; -- if ready = '1' then
								
								else 
									-- read from the memory test pattern
									
								end if; -- if( test_mem < 7 ) then
								
						when "00000100" => NULL ;
							-- start gps	
						
						when others => NULL ;
       			end case;
				else 
					byte_counter <= byte_counter + 7;
					
					-- the old code
					arbiter_next_state <=  write_sram;
				end if ;
				
			end if ;
			
			-- disable rs232 tx and sram
			mem <= '0' ; 
			tx_start <= '0';

--		-- write_sram
		when write_sram =>
			addr <= ( others => '0' ) ;
			mem <= '1' ;	
			rw <= '1' ;
			
			if ready = '1' then
				arbiter_next_state <=  read_sram;
			end if;

--		-- write_sram
		when read_sram =>
			addr <= ( others => '0' ) ;
			mem <= '1' ;	
			rw <= '0' ;
			
			if ready = '1' then
				arbiter_next_state <=  send_comm ;
				din <= data_s2f_ur ;
			end if;
			
--		-- send_comm			
		when send_comm =>
			tx_start <= '1';
			
			if( tx_done_tick = '1' ) then
					arbiter_next_state <= idle ;
			end if;
			mem <= '0' ; 			
			
		end case;

	end if; --  if rising_edge(clk)

end process;

end Behavioral ;
