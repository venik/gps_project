-----------------------------------------------------------
-- Name:	test_sram
-- Description: sram test module
--		
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity test_sram is
    	Port (
			-- sram
			addr_t: out std_logic_vector(17 downto 0) ;
			data_f2s: out std_logic_vector(7 downto 0) ;
			--data_s2f_r, data_s2f_ur: in std_logic_vector(7 downto 0) ;
			data_s2f: in std_logic_vector(7 downto 0) ;
			ready: in std_logic ;
			rw: out std_logic ;
			mem: out std_logic ;
			-- system
			clk : in std_logic ;
			u9_test: out std_logic_vector(7 downto 0) ;
			u8_test: out std_logic_vector(7 downto 0) ;
			-- signal
			test_mem: in std_logic ;
			test_result: inout std_logic_vector(1 downto 0)
	     );
end test_sram;

architecture Behavioral of test_sram is
		
	type 	 memtester_type is(idle, write_t_mem, middle_t_mem, read_t_mem) ;
	signal memtester_state: memtester_type := idle ;
	signal memtester_state_next: memtester_type := idle ;

	signal data_mem: std_logic_vector (8 downto 0) := "000000001" ; 
	signal data_mem_prev: std_logic_vector (8 downto 0) := "000000001" ; 
	
begin

process(clk)
begin								 
	
  	if( rising_edge(clk) ) then 
		memtester_state <= memtester_state_next ;
	end if ;
	
end process;

process(memtester_state, ready, test_mem, clk)
begin
if rising_edge(clk) then		
	
		case memtester_state is
		
		when idle =>
			if( test_mem = '1' ) then
				memtester_state_next <= write_t_mem ;
				addr_t(17 downto 0) <= ( 0 => '1', others => '0' );
				data_mem(7 downto 0) <= ( 0 => '0', 1 => '1', others => '0' ) ;
				data_f2s(7 downto 0) <= ( 0 => '1', others => '0' ) ;
				mem <= '1';
				rw <= '1' ;		  
			else 
				mem <= '0' ;
				test_result <= "00" ;
			end if;
						
		when write_t_mem =>  
		
			mem <= not data_mem(8) ;	 	
			
			if( ready = '1') then 	
			   if( data_mem(8) = '1' ) then	
				   	-- next state
					addr_t(17 downto 0) <= (0 => '1', others => '0') ;
					memtester_state_next <= middle_t_mem ;
								
				else
					-- write into the memory test pattern
					addr_t(17 downto 0) <= b"00" & x"00" & data_mem(7 downto 0) ;
					data_f2s <= data_mem(7 downto 0) ;
					rw <= '1' ;
					mem <= '1' ;
					data_mem(8 downto 0) <= data_mem(7 downto 0) & data_mem(8) ;				
				end if; -- if( data_mem < 256 ) 
				
			end if;
			
			if( memtester_state_next = middle_t_mem ) then
				rw <= '0' ;
				mem <= '0' ;
			end if;
		
		when middle_t_mem =>
			mem <= '1' ;
			addr_t(17 downto 0) <= ( 0 => '1', others => '0' ) ;
			memtester_state_next <= read_t_mem ;
			data_mem(8 downto 0) <= "000000001" ;
									
		when read_t_mem =>
			if( ready = '1') then
			
				if( data_mem(8) = '1' ) then
					-- exit
					memtester_state_next <= idle ;
					test_result <= "10" ;
					mem <= '0' ;
					addr_t(17 downto 0) <=  ( others => '0' ) ;
										
				else
					-- read from the memory test pattern
					-- check data from memeory
					if( data_s2f = data_mem(7 downto 0) ) then
						-- all is oK - update values 
						data_mem(8 downto 0) <= data_mem(7 downto 0) & data_mem(8) ;
						rw <= '0' ;
						mem <= '1' ;
						addr_t(17 downto 0) <= b"0" & x"00" & data_mem(7 downto 0) & data_mem(8) ;
					else
						-- error occur
						memtester_state_next <= idle ;
						test_result <= "11" ;
						mem <= '0' ;
						u9_test <= data_s2f ;
						u8_test <= data_mem(7 downto 0) ;
						addr_t(17 downto 0) <= ( others => '0' );
						--u9_test <= data_mem(7 downto 0);
					end if ;
					
				end if; -- if( data_mem < 256 )
			end if;	  -- if( ready = '1')
			
		end case; -- case memtester_state 
end if;		
end process;

end Behavioral;
