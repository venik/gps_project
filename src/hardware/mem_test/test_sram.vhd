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
			WE, OE: out std_logic ;
			data_f2s: out std_logic_vector(7 downto 0) ;
			data_s2f_r, data_s2f_ur: in std_logic_vector(7 downto 0) ;
			ready: in std_logic ;
			rw: out std_logic ;
			-- system
			clk : in std_logic ;
			reset : in std_logic ;
			-- signal
			test_done: out std_logic ;
			test_result: out std_logic
	     );
end test_sram;

architecture Behavioral of test_sram is
	-- sram
		
	-- local
	type arbiter_type is(idle, write_sram, read_sram, send_comm) ;
	signal arbiter_state: arbiter_type := idle ;
	signal arbiter_next_state: arbiter_type := idle ;
	
	signal soft_reset: std_logic := '0' ;
	
	-- comm staff
	signal byte_counter: integer range 0 to 63;
	signal comm: std_logic_vector (63 downto 0) := ( others => '0') ;
	
	-- mem test staff
	type test_mem_type is(idle_t_mem, read_t_mem, write_t_mem) ;
	signal test_mem: test_mem_type := idle_t_mem;
	signal data_mem: std_logic_vector (7 downto 0) := ( others => '0') ; 
	signal test_mem_result: std_logic_vector (1 downto 0) := ( others => '0' );
	
begin

process(test_mem, ready)
begin
	case test_mem is
	when write_t_mem =>	 
	
		if( data_mem < 255 ) then
			-- write into the memory test pattern
			if ready = '1' then
				addr(7 downto 0) <= data_mem ;
				data_f2s <= data_mem ;
				rw <= '1' ;
				data_mem <= data_mem + 1 ;				
			end if; -- if ready = '1' then
		else
			data_mem <= ( others => '0' );
			test_mem_result <= "01";
		end if; -- if( data_mem < 255 ) then   
			
	when read_t_mem =>
		if( data_mem < 255 ) then
			-- read into the memory test pattern
			addr(7 downto 0) <= data_mem ;						
			rw <= '0' ;
			
			if ready = '1' then
				if (data_s2f_ur /= data_mem) then 
					test_mem_result <= "11"	;
				else
					data_mem <= data_mem + 1 ;	
				end if;
			end if; -- if ready = '1' then
		else
			test_mem_result <= "10" ;
		end if;
	
	when idle_t_mem => NULL ;
	
	end case;
	
end process;

end Behavioral;

