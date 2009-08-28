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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_sram is
    	Port (
			-- sram
			addr: out std_logic_vector(17 downto 0) ;
			data_f2s: out std_logic_vector(7 downto 0) ;
			data_s2f_r, data_s2f_ur: in std_logic_vector(7 downto 0) ;
			ready: in std_logic ;
			rw: out std_logic ;
			mem: out std_logic ;
			-- system
			clk : in std_logic ;
			reset : in std_logic ;
			-- signal
			test_mem: in std_logic ;
			test_result: inout std_logic_vector(1 downto 0)
	     );
end test_sram;

architecture Behavioral of test_sram is
		
	type 	 memtester_type is(idle, write_t_mem, read_t_mem) ;
	signal memtester_state: memtester_type := idle ;
	signal memtester_state_next: memtester_type := idle ;

	signal data_mem: std_logic_vector (8 downto 0) := "000000001" ; 
	--signal data_store: std_logic_vector (7 downto 0) := (others => '0') ; 
	
begin

process(memtester_state_next, clk)
begin								 
	
  	--if( rising_edge(clk) ) then 
		memtester_state <= memtester_state_next ;
	--end if ;
	
end process;

process(memtester_state, ready, clk, reset)
begin 
if( rising_edge(clk) ) then 
		case memtester_state is
		
		when idle =>
			test_result <= "00" ;
			if( test_mem = '1' ) then
				memtester_state_next <= write_t_mem ;
				addr(17 downto 0) <= ( others => '0' );
			end if;
			
--		if( rising_edge(clk) ) then 
--			
--				if( reset = '1' ) then
--					memtester_state_next <= idle ;
--				elsif( test_mem = '1' ) then
--					memtester_state_next <= write_t_mem ;
--				else
--					memtester_state_next <= idle ;
--				end if;		  
--				
--				--test_result <= "00" ;
--				
--			end if;
		
		when write_t_mem => 
		   	if( ready = '1') then
				if( data_mem < 256 ) then
					-- write into the memory test pattern
					addr(17 downto 0) <= b"00" & x"00" & data_mem(7 downto 0) ;
					data_f2s <= data_mem(7 downto 0) ;
					rw <= '1' ;
					mem <= '1' ;
					data_mem(8 downto 0) <= data_mem(7 downto 0) & data_mem(8) ;				
				else   
					-- switch the mode
					data_mem(8 downto 0) <= "000000001";
					memtester_state_next <= read_t_mem ;
					
					-- request for read the first byte from memory
					rw <= '1' ;
					mem <= '1' ;
					addr(17 downto 0) <= "000000000000000001" ;	
				end if; -- if( data_mem < 256 ) 		
			end if;	  -- if( ready = '1')
				
		when read_t_mem =>
		   	if( ready = '1') then
				if( data_mem < 256 ) then
					-- read from the memory test pattern
	
					--data_store <= data_s2f_r ;
					
					-- check data from memeory
					--if( data_store = data_mem(7 downto 0) ) then
					if( data_s2f_r = data_mem(7 downto 0) ) then
						-- all is oK - update values
						rw <= '0' ;
						mem <= '1' ;
						data_mem(8 downto 0) <= data_mem(7 downto 0) & data_mem(8) ;
						addr(17 downto 0) <= b"00" & x"00" & data_mem(7 downto 0) ;
					else
						-- error occur
						memtester_state_next <= idle ;
						test_result <= "11" ;
					end if ;
				else
					data_mem(8 downto 0) <= "000000001";
					memtester_state_next <= idle ;
					test_result <= "10" ;
				end if; -- if( data_mem < 256 )
			end if;	  -- if( ready = '1')
			
		end case; -- case memtester_state 

end if ;
		
end process;

end Behavioral;
