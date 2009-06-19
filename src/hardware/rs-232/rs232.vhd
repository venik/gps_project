-----------------------------------------------------------
-- TX rs232 module for FPGA
--
--  --------------
--  |            | -->	rs232_out - out in hardware port
--  |            | <--	din - input byte
--  |   FPGA     | <--	tx_start - signal to start transfer
--  |            | -->	tx_done_tick - transfer done
--  |            | <--	reset - you know what is it
--  |            | <--	clk - tick-tack
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

entity rs232_tx is
    	Port (	clk : in STD_LOGIC ;
		reset : in STD_LOGIC ; -- FIXME ucf-file
		din : in STD_LOGIC_VECTOR (7 downto 0) ; 
		rs232_out, tx_done_tick : out std_logic ;
		tx_start : in std_logic
	     );
end rs232_tx;

architecture Behavioral of rs232_tx is
	type rs232_type is(idle, start, data, stop);
	signal rs232_state, rs232_next_state: rs232_type;
	--signal rs232_state: bit_vector (2 downto 0) := "111";
	signal rs232_counter: integer range 0 to 8 := 0;
	--signal rs232_value: bit_vector (7 downto 0) := X"41"; -- A - char
	signal rs232_value: STD_LOGIC_VECTOR (7 downto 0) ;
	signal rs232_clk: std_logic;
	
begin

rs232clk_unit: entity work.rs232clk(arch)
	port map( clk => clk, rs232_clk => rs232_clk );	

process(clk, reset)
begin

	if( reset = '1') then
		rs232_state <= idle;
		--rs232_out <= '1';					
	elsif rising_edge(clk) then
		rs232_state <= rs232_next_state;
	end if;

end process;

-- next state logic 
process(rs232_clk, tx_start, rs232_state, din, rs232_value, rs232_next_state)
begin
	tx_done_tick <= '0' ;
	
	if( rs232_clk = '1') then 

		case rs232_state is
		
		-- idle
		when idle =>

			if tx_start = '1' then
				rs232_next_state <= start;
				rs232_value <= din;
			end if;

			rs232_out <= '1';					

		-- start bit
		when start =>
			rs232_out <= '0'; 	
			rs232_next_state <= data;
			rs232_counter <= 0;

		-- data bit
		when data =>
			if rs232_counter = 8 then
				rs232_next_state <= stop;
			else
				-- FIXME
				--rs232_out <= to_stdulogic(rs232_value(rs232_counter));
				--rs232_out <= '1' ;
				rs232_out <= rs232_value(rs232_counter);
				rs232_counter <= rs232_counter + 1 ;
			end if;
	
		-- stop
		when stop =>
			rs232_out <= '1' ;	-- stop bit
			rs232_next_state <= idle ;
			tx_done_tick <= '1' ;

		when others => NULL ;
							
		end case;

	end if; -- if BaudSignal(16) = '1'

end process;
	
end Behavioral;
