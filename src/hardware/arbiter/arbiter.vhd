-----------------------------------------------------------
-- Name:	gps arbiter 
-- Description:	get data from gps and store in sram, after
--		sram is full send it via rs232
--
-- Developer: Alex Nikiforov nikiforov.al [at] gmail.com
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rs232main is
    	Port (	clk : in STD_LOGIC ;
		reset : in STD_LOGIC ;
		-- rs232
		rs232_in: in std_logic ;
		rs232_out: out std_logic ;
		--sram
		address: out std_logic_vector(17 downto 0) ;
		dio_a: inout std_logic_vector(7 downto 0) ;
		s1, s2: out std_logic ;
		WE, OE: out std_logic;
	     );
end rs232main;

architecture Behavioral of rs232main is
	-- rs232
	signal	rs232_clk: std_logic ;
	signal	rx_done_tick : std_logic ;
	signal	tx_done_tick : std_logic ;
	signal	tx_start : std_logic ;
	signal	dout : std_logic_vector (7 downto 0) ; 
	signal	din : std_logic_vector (7 downto 0) ; 
	-- sram
	signal	mem: in std_logic ;
	signal	rw: in std_logic ;
	signal	addr: in std_logic_vector(17 downto 0) ;
	signal 	data_f2s: in std_logic_vector(7 downto 0) ;
	signal 	ready: out std_logic ;
	signal	data_s2f_r: data_s2f_ur: out std_logic_vector(7 downto 0)
	
begin
end Behavioral ;
