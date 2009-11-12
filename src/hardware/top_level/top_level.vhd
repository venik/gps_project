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
			-- gps
			q: in std_logic_vector(1 downto 0) ;
			i: in std_logic_vector(1 downto 0) ;
--			ld_gps: in std_logic ;
			sclk: out std_logic ;
			sdata: out std_logic ;
			cs: out std_logic ;
			gps_clkout: in std_logic ;
			test_spot: out std_logic ;
			-- system
			clk : in std_logic ;
			u10 : out  std_logic_vector (7 downto 0) ;
			u9 : out  std_logic_vector (7 downto 0) ;
			u8 : out  std_logic_vector (7 downto 0) ;
			reset : in std_logic
	     );
end top_level;

architecture Behavioral of top_level is

			-- sram
			signal 	ready: std_logic := '0' ;
			--signal	data_s2f_r, data_s2f_ur: std_logic_vector(7 downto 0) ;	
			signal	data_s2f: std_logic_vector(7 downto 0) ;
			signal	data_f2s: std_logic_vector(7 downto 0) ;
			signal	mem: std_logic := '0';
			signal	rw: std_logic := '0';
			signal	addr: std_logic_vector(17 downto 0) := (others => '0') ;
			signal	u9_tops: std_logic_vector(7 downto 0) ;
    			
			-- arbiter
			signal	a_mem: std_logic := '0';
			signal	a_rw: std_logic := '0';
			signal	a_addr: std_logic_vector(17 downto 0) := (others => '0') ;
			signal 	a_data_f2s: std_logic_vector(7 downto 0) := (others => '0') ;

			-- test_mem
			signal	t_mem: std_logic := '0';
			signal	t_rw: std_logic := '0';
			signal	t_addr: std_logic_vector(17 downto 0) := (others => '0');
			signal 	t_data_f2s: std_logic_vector(7 downto 0) := (others => '0');
			signal	u9_topt: std_logic_vector(7 downto 0) ;
			signal	u8_topt: std_logic_vector(7 downto 0) ;
			
			-- interprocess communication
			signal   mode: std_logic_vector(1 downto 0) := ( others => '0' ) ;
			signal   test_mem: std_logic := '0' ;
			signal   test_result: std_logic_vector(1 downto 0) := ( others => '0' ) ;
			
			-- gps
			signal	m_mem: std_logic := '0';
			signal	m_rw: std_logic := '0';
			signal	m_addr: std_logic_vector(17 downto 0) := (others => '0') ;
			signal 	m_data_f2s: std_logic_vector(7 downto 0) := (others => '0');
			signal   gps_start: std_logic := '0' ;
			signal   gps_done: std_logic := '0' ;
					
begin

--process(clk)
--begin
--if(rising_edge(clk)) then
--	test_spot <= gps_clkout ;
--end if;
--end process;

arbiter: entity work.arbiter(Behavioral)
	port map(
			cs_a => cs,
			sclk_a => sclk,
			sdata_a => sdata,
			gps_start_a => gps_start,
			gps_done_a => gps_done,
			rs232_in => rs232_in,
			rs232_out => rs232_out,
			addr_a => a_addr,
			rw => a_rw,
			data_f2s => a_data_f2s,
			mem => a_mem,
			data_s2f => data_s2f,
			ready => ready,
			clk => clk,
			u10 => u10,
			u9 => u9,
			u8 => u8,
			mode => mode,
			test_result => test_result,
			test_mem => test_mem,
			reset => reset
			);
			
test_sram: entity work.test_sram(Behavioral)
	port map(
			addr_t => t_addr,
			rw => t_rw,
			mem => t_mem,
			data_f2s => t_data_f2s,
			data_s2f => data_s2f,
			ready => ready,
			clk => clk,
			reset => reset,
			u9_test => u9_topt,
			u8_test => u8_topt,
			test_result => test_result,
			test_mem => test_mem
			);
			
sram_controller: entity work.sram_ctrl(arch)
	port map( 
			clk => clk,
			reset => reset,
			u9_sram => u9_tops,
			mem_s => mem,
			rw => rw,
			s1 => s1,
			s2 => s2,
			address => address,
			addr => addr,
			data_f2s => data_f2s,
			ready => ready,
			data_s2f => data_s2f,
			dio_a => dio_a,
			WE => WE,
			OE => OE
			);
			
gps: entity work.gps_main(gps_main)
	port map (
			q_m => q,
			i_m => i,
			gps_clkout_m => gps_clkout,
			gps_start_m => gps_start,
			gps_done_m => gps_done,
			addr_m => m_addr,
			data_f2s_m => m_data_f2s,
			ready_m => ready,
			rw_m => m_rw,
			mem_m => m_mem,
			test_spot_m =>test_spot,
			clk => clk
		);
			
SRAM_MUX: process(mode, t_addr, t_rw, t_data_f2s, t_mem,
						a_addr, a_rw, a_data_f2s, a_mem,
						m_addr, m_rw, m_mem
					)
begin
	
	case mode is
	when "00" => 
		-- arbiter drive SRAM bus
		addr 		<= a_addr ;
		rw 			<= a_rw ;
		data_f2s 	<= a_data_f2s ;
		mem 		<= a_mem ;
		--u9 	<= u9_tops ;
		
	when "01" => 
		-- test_mem drive SRAM bus
		addr 		<= t_addr ;
		rw 			<= t_rw ;
		data_f2s 	<= t_data_f2s ;
		mem 		<= t_mem ;
		--u9 	<= u9_topt;
		
	when "10" =>
 		-- gps drive SRAM bus
		addr 		<= m_addr ;
		rw 			<= m_rw ;
		data_f2s 	<= m_data_f2s ;
		mem 		<= m_mem ;
		
	when others => NULL ;
	
	end case;
	
end process SRAM_MUX;

end Behavioral;

