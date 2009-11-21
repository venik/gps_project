-----------------------------------------------------------
--- Name:	controller sram 
--- Description:	sram chip M5M5V208FP-85L
---
--  --------------
--  |            | <--	clk - clock
--  |            | <--	soft_reset - reset
--  |            | <--	mem - memory operation
--  |            | <--	rw - w = 1 / r = 0
--  |   SRAM     | <--	addr - address
--  | controller | <--	data_f2s - fpga to sram data
--  |            | -->	ready - sram controller is ready (1 is ready)
--  |            |
--  |            | --> s1, s2 - chip enable
--  |            | --> WE, OE - write enable / output enable
--  |            | --> address - address bus
--  |            |<--> dio_a - data bus
--  --------------
--
--- Developer:	Alex Nikiforov nikiforov.al [at] gmail.com
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;   

entity sram_ctrl is
  port(
    clk: in std_logic;				
	reset: in std_logic;
	u9_sram: out std_logic_vector(7 downto 0) ;
	 
    -- to/from main system
    mem_s: in std_logic ;
    rw: in std_logic ;
    addr: in std_logic_vector(17 downto 0) ;
	ready: out std_logic ;
    data_f2s: in std_logic_vector(7 downto 0) ;
    --data_s2f_r, data_s2f_ur: out std_logic_vector(7 downto 0) ;
	data_s2f: out std_logic_vector(7 downto 0) ;
 
    -- sram chip
	address: out std_logic_vector(17 downto 0) ;
    dio_a: inout std_logic_vector(7 downto 0) ;
    s1, s2: out std_logic ;
    WE, OE: out std_logic
  ) ;
end sram_ctrl;

architecture arch of sram_ctrl is
	type 	sram_ctrl_type is (idle, wr, rd);	
	signal	sram_ctrl_state, sram_ctrl_next_state: sram_ctrl_type := idle;
	signal	tri_reg: std_logic;	
	signal	cycle_counter_s: integer range 0 to 6;
begin

process(clk)	
begin
	if rising_edge(clk) then
		sram_ctrl_state <= sram_ctrl_next_state;
	end if;
end process;

dio_a <= data_f2s when tri_reg = '0' else (others => 'Z') ;
s2 <= '1' ;
address <= addr;
	
-- FSM
process(clk)
begin
if rising_edge(clk) then	
	
	case(sram_ctrl_state) is
		
	when idle =>
	
	if sram_ctrl_next_state = idle then
		sram_ctrl_next_state <= idle ;
		WE <= '1' ;
		OE <= '1' ;
		s1 <= '1' ;
		tri_reg <= '1' ;
		cycle_counter_s <= 0 ;
		ready <= '1' ;
	end if;
	
	if mem_s = '1' then
				
		ready <= '0' ;
		
		if rw = '1' then
			-- write
			sram_ctrl_next_state <= wr ;
			WE <= '0' ;
			tri_reg <= '0' ;
			s1 <= '0' ;
		else 
			-- read
			sram_ctrl_next_state <= rd ;
			OE <= '0' ;
			s1 <= '0' ;
		end if;
		
	end if;
		
	when wr => 
	
	cycle_counter_s <= cycle_counter_s + 1 ;
	
	if cycle_counter_s >= 2 then 
		if sram_ctrl_next_state = idle then
			ready <= '1' ;
			WE <= '1' ;
			OE <= '1' ;
			s1 <= '1' ;
			tri_reg <= '1' ;
			cycle_counter_s <= 0 ;
		end if ;
		
		sram_ctrl_next_state <= idle ;
	end if;
	
	when rd =>
	
	cycle_counter_s <= cycle_counter_s + 1 ;
	if cycle_counter_s >= 2 then 
		if sram_ctrl_next_state = idle then
			ready <= '1' ;
			WE <= '1' ;
			OE <= '1' ;
			s1 <= '1' ;
			tri_reg <= '1' ;
			cycle_counter_s <= 0 ;
			data_s2f <= dio_a ;
		end if ;
		
		sram_ctrl_next_state <= idle ;
	end if;
	
	end case;
	
end if; -- 	if rising_edge(clk)
end process;

end arch;