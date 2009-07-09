--	arbiter_next_state <= send_comm ;--	arbiter_next_state <= send_comm ;-----------------------------------------------------------
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
	--		address: out std_logic_vector(17 downto 0) ;
	--		dio_a: inout std_logic_vector(7 downto 0) ;
	--		s1, s2: out std_logic ;
	--		WE, OE: out std_logic
			--system
			clk : in STD_LOGIC ;
			u10 : out  STD_LOGIC_VECTOR (7 downto 0) ;
			reset : in STD_LOGIC
	     );
end arbiter;

architecture Behavioral of arbiter is
	-- rs232
	signal	rx_done_tick : std_logic ;
	signal	tx_done_tick : std_logic ;
	signal	tx_start : std_logic ;
	signal	dout : std_logic_vector (7 downto 0) ; 
	signal	din : std_logic_vector (7 downto 0) ; 
	-- sram
--	signal	mem: std_logic ;
--	signal	rw: std_logic ;
--	signal	addr: std_logic_vector(17 downto 0) ;
--	signal 	data_f2s: std_logic_vector(7 downto 0) ;
--	signal 	ready: std_logic ;
--	signal	data_s2f_r, data_s2f_ur: std_logic_vector(7 downto 0) ;
	-- local
	type arbiter_type is(idle, send_comm) ;
	signal arbiter_state: arbiter_type := idle ;
	signal arbiter_next_state: arbiter_type := idle ;
	
	signal soft_reset: std_logic := '0';
	
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
	
	tx_start <= '1' ;
	din <= X"41" ;
	
process(clk, reset)
begin

	if( reset = '0') then				-- push the reset-button
		soft_reset <= '1' ;
	else
		soft_reset <= '0' ;
	end if;
	
end process;

--end process;
--process(clk, reset)
--begin
--	if( reset = '1') then
--		arbiter_state <= idle;
--	elsif rising_edge(clk) then
--		arbiter_state <= arbiter_next_state;
--	end if;
--end process;
		
--process(arbiter_state, clk, tx_done_tick)
--begin
--	if rising_edge(clk) then
--		case  arbiter_state is
--
----		-- idle	
--		when idle =>
----			if( rx_done_tick = '1' ) then
----				 simple test
----				din <= dout ;
----				arbiter_next_state <= send_comm ;
----			end if;
--			arbiter_next_state <= send_comm ;
--			din <= X"55";
--		when send_comm =>
--			tx_start <= '1';
--			
--			if( tx_done_tick = '1' ) then
--				arbiter_next_state <= idle ;
--			end if;
--						
--		end case;
--
--	end if; --  if rising_edge(clk)
--
--end process;

end Behavioral ;
