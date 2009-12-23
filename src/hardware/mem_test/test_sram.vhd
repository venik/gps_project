-----------------------------------------------------------
-- Name:	test_sram
-- Description: sram test module
--		
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity test_sram is
    	Port (
			-- sram
			addr_t: out std_logic_vector(17 downto 0) ;
			data_f2s: out std_logic_vector(7 downto 0) ;
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
		
	type   memtester_type is(	idle,
								write_t_mem, wait_for_write,
								read_t_mem, wait_for_read) ;
	signal memtester_state: memtester_type := idle ;
	signal memtester_state_next: memtester_type := idle ;

	signal data_mem: std_logic_vector (7 downto 0) := (0 => '1', others => '0') ;
	signal result: unsigned(17 downto 0) := (others => '0') ;
		
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
		
		if memtester_state_next = idle then
			mem <= '0' ;
			test_result <= "00" ;
			addr_t(17 downto 0) <= ( others => '0' );
			data_mem(7 downto 0) <= ( 0 => '1', others => '0' ) ;
			data_f2s(7 downto 0) <= ( 0 => '1', others => '0' ) ;
			result(17 downto 0) <= (others => '0') ;
		end if;
	
		if( test_mem = '1' ) then
			memtester_state_next <= write_t_mem ;
			mem <= '1';
			rw <= '1' ;		  
		end if; 
-------------------------------------------				
		when write_t_mem =>  
		
		mem <= '1' ;
		rw <= '1' ;
		memtester_state_next <= wait_for_write ;
		
		if( result(17 downto 0) = X"3FFFF" ) then
			-- memory is full
			rw <= '0' ;
			mem <= '1' ;
			memtester_state_next <= wait_for_read ;
			
			if( memtester_state_next = wait_for_read ) then
				addr_t(17 downto 0) <= (others => '0') ;
				result(17 downto 0) <= (0 => '1', others => '0') ;
				data_mem(7 downto 0) <= ( 0 => '1', others => '0' ) ;
			end if;
			
			
		else
			addr_t(17 downto 0) <= std_logic_vector(result) ;
			data_f2s <= data_mem(7 downto 0) ;
		end if;	
-------------------------------------------
		when wait_for_write =>
		
		mem <= '0' ;
		
		if( ready = '1') then
			
			memtester_state_next <= write_t_mem ;
			
			if( memtester_state_next = write_t_mem ) then
				data_mem <= data_mem(6 downto 0) & data_mem(7) ;
				result <= result + 1 ;
			end if;
			
		end if;
-------------------------------------------				
		when read_t_mem =>
		mem <= '1' ;
		
		if( result(17 downto 0) = X"3FFFF" ) then
			-- game over
			
			test_result <= "10" ;
			rw <= '0' ;
			mem <= '0' ; 
			memtester_state_next <= idle ;
			
		elsif( data_s2f = data_mem(7 downto 0) ) then
			-- correct					  
			
			memtester_state_next <= wait_for_read ;
			
			if( memtester_state_next = wait_for_read ) then
				addr_t(17 downto 0) <= std_logic_vector(result) ;
				data_mem <= data_mem(6 downto 0) & data_mem(7) ;
				result <= result + 1 ;
			end if;
			
		else
			-- error
			rw <= '0' ;
			mem <= '0' ; 
			memtester_state_next <= idle ;
			test_result <= "11" ;
			
		end if;
-------------------------------------------			
		when wait_for_read =>
		mem <= '0' ;
		if( ready = '1') then
			memtester_state_next <= read_t_mem ;
		end if ;	
	
		end case; -- case memtester_state 
end if;		
end process;

end Behavioral;
