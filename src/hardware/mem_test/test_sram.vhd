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
			--clk : in std_logic ;
			--reset : in std_logic ;
			-- signal
			test_mem: in std_logic ;
			test_result: out std_logic_vector(1 downto 0)
	     );
end test_sram;

architecture Behavioral of test_sram is
		
	type 	 memtester_type is(idle, write_t_mem, read_t_mem) ;
	signal memtester_state: memtester_type ;
	signal memtester_state_next: memtester_type := write_t_mem ;

	signal data_mem: std_logic_vector (7 downto 0) := "00000001" ; 
	signal data_store: std_logic_vector (7 downto 0) := (others => '0') ; 
	
begin

process(test_mem, memtester_state_next)
begin

	if( test_mem = '1' ) then				
		memtester_state <= memtester_state_next ;
	else 
		memtester_state <= idle ;
	end if;
	
end process;

process(memtester_state, ready)
begin
	if( ready = '1') then
	
		case memtester_state is
		
		when idle => 	NULL;
		
		when write_t_mem => 	
			if( data_mem < 128 ) then
				-- write into the memory test pattern
				if ready = '1' then
					addr(7 downto 0) <= data_mem ;
					data_f2s <= data_mem ;
					rw <= '1' ;
					mem <= '1' ;
					data_mem(7 downto 0) <= data_mem(6 downto 0) & data_mem(7) ;				
				end if; -- if ready = '1' then
			else
				data_mem(7 downto 0) <= "00000001";
				memtester_state_next <= write_t_mem ;
			end if; -- if( data_mem < 128 ) 
				
		when read_t_mem => NULL ;
			if( data_mem < 128 ) then
				-- write into the memory test pattern
				addr(7 downto 0) <= data_mem ;
				data_store <= data_s2f_r ;
				
				-- check data from memeory
				if( data_store = data_mem ) then
					-- all is oK - update values
					rw <= '1' ;
					mem <= '1' ;
					data_mem(7 downto 0) <= data_mem(6 downto 0) & data_mem(7) ;	
				else
					-- error occur
					memtester_state_next <= read_t_mem ;
					test_result <= "11" ;
				end if ;
			else
				data_mem(7 downto 0) <= "00000001";
				memtester_state_next <= idle ;
				test_result <= "01" ;
			end if; -- if( data_mem < 128 ) 
			
		end case; -- case memtester_state
		
	end if; -- if( ready = '1')

end process;

end Behavioral;

