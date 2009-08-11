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
			
			signal mode: std_logic_vector(1 downto 0) := ( others => '0' ) ;
			
			-- sram
			signal 	ready: std_logic := '0' ;
			signal	data_s2f_r, data_s2f_ur: std_logic_vector(7 downto 0) ;
			signal	data_f2s: std_logic_vector(7 downto 0) ;
			signal	mem: std_logic := '0';
			signal	rw: std_logic := '0';
			signal	addr: std_logic_vector(17 downto 0) := (others => '0') ;
    			
			-- arbiter
			signal	a_mem: std_logic := '0';
			signal	a_rw: std_logic ;
			signal	a_addr: std_logic_vector(17 downto 0) ;
			signal 	a_data_f2s: std_logic_vector(7 downto 0) ;
			signal	a_WE: std_logic;
			signal	a_OE: std_logic;

			-- test_mem
			signal	t_mem: std_logic := '0';
			signal	t_rw: std_logic ;
			signal	t_addr: std_logic_vector(17 downto 0) ;
			signal 	t_data_f2s: std_logic_vector(7 downto 0) ;
			signal	t_WE: std_logic;
			signal	t_OE: std_logic;

begin

arbiter: entity work.arbiter(Behavioral)
	port map(
			rs232_in => rs232_in,
			rs232_out => rs232_out,
			addr => a_addr,
			rw => a_rw,
			WE => a_WE,
			OE => a_OE,
			data_f2s => a_data_f2s,
			data_s2f_r => data_s2f_r,
			data_s2f_ur => data_s2f_ur,
			ready => ready,
			clk => clk,
			u10 => u10,
			mode => mode,
			test_done => test_done,
			test_result => test_result,
			reset => reset
			);
			
test_sram: entity work.test_sram(Behavioral)
	port map(
			addr => t_addr,
			rw => t_rw,
			WE => t_WE,
			OE => t_OE,
			data_f2s => t_data_f2s,
			data_s2f_r => data_s2f_r,
			data_s2f_ur => data_s2f_ur,
			ready => ready,
			clk => clk,
			test_done => test_done,
			test_result => test_result,
			reset => reset
			);
			
sram_controller: entity work.sram_ctrl(arch)
	port map( 
			clk => clk,
			reset => reset,
			mem => mem,
			rw => rw,
			s1 => s1,
			s2 => s2,
			address => address,
			addr => addr,
			data_f2s => data_f2s,
			ready => ready,
			data_s2f_r => data_s2f_r,
			data_s2f_ur => data_s2f_ur,
			dio_a => dio_a,
			WE => WE,
			OE => OE
			);

SRAM_MUX: process(mode)
begin

	case mode is
	when "00" => NULL ;
		-- arbiter drive SRAM bus
	when "01" => NULL ;
		-- arbiter drive SRAM bus
	when "10" => NULL ;
	when "11" => NULL ;
	when others => NULL ;
	end case;
	
end process SRAM_MUX;

end Behavioral;

