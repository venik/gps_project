-----------------------------------------------------------
-- Name:	top level
-- Description: connect all modules into the system
--		
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top_level is
    	Port (
			-- rs232
			rs232_in: in std_logic ;
			rs232_out: out std_logic ;
			-- sram
			address: out std_logic_vector(17 downto 0) ;
			dio_a: inout std_logic_vector(7 downto 0) ;
			s1, s2: out std_logic ;
			WE, OE: out std_logic ;
			-- system
			clk : in std_logic ;
			u10 : out  std_logic_vector (7 downto 0) ;
			reset : in std_logic
	     );
end top_level;

architecture Behavioral of top_level is
			signal test_done: std_logic := '0' ;
			signal test_result: std_logic := '0' ;
			
			signal s_u10 : std_logic_vector (7 downto 0) ;
			
			-- sram
			signal	mem: std_logic := '0';
			signal	rw: std_logic ;
			signal	addr: std_logic_vector(17 downto 0) ;
			signal 	data_f2s: std_logic_vector(7 downto 0) ;
			signal 	ready: std_logic := '0' ;
			signal	data_s2f_r, data_s2f_ur: std_logic_vector(7 downto 0) ;
begin

arbiter: entity work.arbiter(Behavioral)
	port map(
			rs232_in => rs232_in,
			rs232_out => rs232_out,
			address => address,
			dio_a => dio_a,
			WE => WE,
			OE => OE,
			clk => clk,
			u10 => s_u10,
			test_done => test_done,
			test_result => test_result,
			reset => reset
			);
			
test_sram: entity work.test_sram(Behavioral)
	port map(
			address => address,
			dio_a => dio_a,
			WE => WE,
			OE => OE,
			clk => clk,
			test_done => test_done,
			test_result => test_result,
			u10 => s_u10,
			reset => reset
			);
			
sram_controller: entity work.sram_ctrl(arch)
	port map( clk => clk,
				reset => reset,
				mem => mem,
				rw => rw,
				s1 => s1,
				s2 => s2,
				addr => addr,
				data_f2s => data_f2s,
				ready => ready,
				data_s2f_r => data_s2f_r,
				data_s2f_ur => data_s2f_ur,
				address => address,
				dio_a => dio_a,
				WE => WE,
				OE => OE
			);
			
			u10 <= s_u10 ;
end Behavioral;

