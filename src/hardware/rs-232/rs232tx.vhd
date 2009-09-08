-----------------------------------------------------------
-- TX rs232 module for FPGA
--
--  --------------
--  |            | -->	rs232_out - out in hardware port
--  |            | <--	din - input byte
--  |   rs232    | <--	tx_start - signal to start transfer
--  |    tx      | -->	tx_done_tick - transfer done
--  |            | <--	reset - you know what is it
--  |            | <--	clk - tick-tack
--  |            | <--	rs232_clk - clk at 115200 bits/sec speed 
--  --------------
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

entity rs232tx is
    	Port (	clk : in STD_LOGIC ;
		--u10 : out  STD_LOGIC_VECTOR (7 downto 0) ;
		soft_reset : in STD_LOGIC ;
		din : in STD_LOGIC_VECTOR (7 downto 0) ; 
		rs232_out : out std_logic ;
		tx_done_tick : out std_logic ;
		rs232_clk: in std_logic ;
		tx_start : in std_logic
	     );
end rs232tx;

architecture arch of rs232tx is
	type rs232_type is(idle, start, data, stop);
	signal rs232_state: rs232_type;
	signal rs232_next_state: rs232_type;
	--signal rs232_state: bit_vector (2 downto 0) := "111";
	signal rs232_counter: integer range 0 to 7 := 0;
	--signal rs232_value: bit_vector (7 downto 0) := X"41"; -- A - char
	signal rs232_value: STD_LOGIC_VECTOR (7 downto 0) := ( others => '0');
	
begin

process(clk, soft_reset)
begin

	if( soft_reset = '1') then
		rs232_state <= idle;
		--rs232_out <= '1';					
	elsif rising_edge(clk) then
		rs232_state <= rs232_next_state;
	end if;

end process;

--rs232_out <= rs232_clk;

-- -- next state logic 
process(rs232_clk, tx_start, rs232_state)
begin
  if rising_edge(rs232_clk) then
	
  	tx_done_tick <= '0' ;
		
		case rs232_state is
			
			-- idle
			when idle =>

				if tx_start = '1' then
					rs232_next_state <= start;
					rs232_value <= din;
				end if;

				rs232_out <= '1';
				--u10 <= X"40" ;				-- 0

			-- start bit
			when start =>
			
				rs232_out <= '0';
				
				rs232_next_state <= data;
				rs232_counter <= 0;
				
				--u10 <= X"03" ;				-- 1

			-- data bit
			when data =>
			
					rs232_out <= rs232_value(rs232_counter);	
				
					if rs232_counter = 7 then
						rs232_next_state <= stop;
					end if;
					
					-- FIXME
					--rs232_out <= to_stdulogic(rs232_value(rs232_counter));
					--rs232_out <= '0' ;
															
					rs232_counter <= rs232_counter + 1 ;
					--u10 <= X"24" ;				-- 2
				
			-- stop
			when stop =>
					rs232_out <= '1' ;	-- stop bit
					rs232_next_state <= idle ;
					tx_done_tick <= '1' ;

					--u10 <= X"30";				-- 3
					
			when others =>
					--u10 <= X"19" ;				-- 4 
					
			end case;
			
		end if;
		
end process;
	
end arch;
