-----------------------------------------------------------
-- Name:	rs232 main module 
-- Description: just rs232	
--
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rs232main is
    	Port (	clk : in STD_LOGIC ;
					u9 : out  STD_LOGIC_VECTOR (7 downto 0) ;
					u8 : out  STD_LOGIC_VECTOR (7 downto 0) ;
					soft_reset : in STD_LOGIC ; -- FIXME ucf-file
					--dout : out std_logic_vector (7 downto 0) ; 
					comm: out std_logic_vector (63 downto 0) ;
					din : in std_logic_vector (7 downto 0) ; 
					rs232_in: in std_logic ;
					rs232_out: out std_logic ;
					rx_done_tick : out std_logic ;
					tx_done_tick : out std_logic ;
					tx_start : in std_logic
	     );
end rs232main;

rs232rx_unit: entity work.rs232_rx_new(rs232_rx_new)
	port map(
		clk => clk,
		u9_rx => u9,
		comm => comm,
		rx_done_tick => rx_done_tick,
		rs232_in => rs232_in
	);

rs232tx_unit: entity work.rs232_tx_new(rs232_tx_new)
	port map(
		clk => clk,
		din => din,
		u8_tx => u8,
		rs232_out => rs232_out,
		tx_start => tx_start,
		tx_done_tick => tx_done_tick
	);
	
end arch;
