-----------------------------------------------------------
-- TX rs232 module for FPGA
--
--  --------------
--  |            | <--	rs232_in - in in hardware port
--  |            | -->	dout - received byte 
--  |   rs232    | -->	rx_done_tick - receive done
--  |    rx      | <--	reset - you know what is it
--  |            | <--	clk - tick-tack
--  |            | <--	rs232_middle_clk - clk for receive (bods/2)
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

entity rs232rx is
    	Port (	clk : in STD_LOGIC ;
		--u10 : out  STD_LOGIC_VECTOR (7 downto 0) ;
		soft_reset : in STD_LOGIC ;
		comm: out std_logic_vector (63 downto 0) ;		
		rs232_in: in std_logic ;
		rx_done_tick : out std_logic ;
		rs232_middle_clk: in std_logic
	     );
end rs232rx;

architecture arch of rs232rx is
	type rs232_type is(idle, data, stop);
	signal rs232_state, rs232_next_state: rs232_type;
	signal rs232_counter: integer range 0 to 8 := 0;
	signal rs232_edge: std_logic_vector (1 downto 0) ;
	signal rs232_value: STD_LOGIC_VECTOR (7 downto 0) := ( others => '0') ;
	
	-- comm staff
	signal byte_counter: integer range 0 to 63;
	
begin

process(clk, soft_reset)
begin

	if( soft_reset = '1') then
		rs232_state <= idle;
	elsif rising_edge(clk) then
		rs232_state <= rs232_next_state;
	end if;

end process;

-- next state logic 
process(rs232_middle_clk, rs232_state)
begin
	
if rising_edge(rs232_middle_clk) then
 
  rx_done_tick <= '0' ;
  
  case rs232_state is
  -- idle
  when idle =>
 
   if( rs232_in = '0' ) then
    rs232_next_state <= data; 
    --rs232_value <= ( others => '0' ) ;
    rs232_counter <= 0 ;

    rs232_edge <= B"01";

   end if;
 
  -- data bit
  when data =>
           
    if( rs232_counter = 8 ) then
     rs232_next_state <= stop;
     

    elsif( rs232_edge = 2 ) then 
   --  rs232_edge <= B"001" ;

     rs232_value(rs232_counter) <= rs232_in;
     rs232_counter <= rs232_counter + 1 ;
    end if;
 

		if (rs232_edge<2) then           
			rs232_edge <= rs232_edge + 1 ;
		else
			rs232_edge<=b"01";
		end if; 
 
	-- stop
	when stop =>
		if rs232_in = '1' then
		
			rs232_next_state <= idle ;
			--dout <= rs232_value ; 
			comm((byte_counter + 7) downto byte_counter) <= rs232_value ;
							 
			if( byte_counter = 56 ) then
				byte_counter <= 0 ;
				rx_done_tick <= '1' ;
			else 
				byte_counter <= byte_counter + 8;
			end if ;
			
		end if;
	 
	when others => NULL ;
			 
	end case;
  
end if; -- if rising_edge(rs232_clk) then 

end process;

end arch;
