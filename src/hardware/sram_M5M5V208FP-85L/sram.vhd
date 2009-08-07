-----------------------------------------------------------
--- Name:	controller sram 
--- Description:	sram chip M5M5V208FP-85L
---
--  --------------
--  |            | <--	clk - clock
--  |            | <--	soft_reset - reset
--  |            | <--	mem - memory operation
--  |            | <--	rw - w = 0 / r = 1
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
---
--- Misc:	More info in "FPGA prototyping by VHDL examples"
---		Pong P. Chu, Chapter 10
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;   

entity sram_ctrl is
  port(
    clk: in std_logic;
	 soft_reset: in std_logic;
	 
    -- to/from main system
    mem: in std_logic ;
    rw: in std_logic ;
    addr: in std_logic_vector(17 downto 0) ;
    data_f2s: in std_logic_vector(7 downto 0) ;
    ready: out std_logic ;
    data_s2f_r, data_s2f_ur: out std_logic_vector(7 downto 0) ;
 
    -- to/from chip
    address: out std_logic_vector(17 downto 0) ;
 
    -- sram chip
    dio_a: inout std_logic_vector(7 downto 0) ;
    s1, s2: out std_logic ;
    WE, OE: out std_logic
  ) ;
end sram_ctrl;
 
architecture arch of sram_ctrl is
  type  state_type is (idle, rd1, rd2, rd3, rd4, rd5, wr1, wr2, wr3, wr4, wr5);
  signal   state_reg, state_next: state_type;
  signal  data_f2s_reg, data_f2s_next: std_logic_vector(7 downto 0);
  signal  data_s2f_reg, data_s2f_next: std_logic_vector(7 downto 0);
  signal  addr_reg, addr_next: std_logic_vector(17 downto 0);
  signal   we_buf, oe_buf, tri_buf: std_logic;
  signal   we_reg, oe_reg, tri_reg: std_logic;
 
begin

--  s1 <= '1' ;
--  s2 <= '1' ;
--  WE <= '1' ;
--  OE <= '1' ;
--  address <= ( others => '1' );

  -- state & data registers
  process(clk, soft_reset)
  begin
    if( soft_reset = '1') then
      state_reg <= idle;
      addr_reg <= ( others => '0' );
      data_f2s_reg <= ( others => '0' );
      data_s2f_reg <= ( others => '0' );
      tri_reg <= '1';
      we_reg <= '1';
      oe_reg <= '1';
    elsif rising_edge(clk) then   
      state_reg <= state_next;
      addr_reg <= addr_next;
      data_f2s_reg <= data_f2s_next;
      data_s2f_reg <= data_s2f_next;
      tri_reg <= tri_buf;
      we_reg <= we_buf;
      oe_reg <= oe_buf;
    end if;
  end process;
 
  -- next state logic
  process (state_reg, mem, rw, dio_a, addr, data_f2s, data_f2s_reg, data_s2f_reg, addr_reg)
  begin
    addr_next <= addr_reg;
    --data_f2s_next <= data_s2s_reg;
    data_s2f_next <= data_s2f_reg;
    ready <= '0';
 
    case state_reg is
      when idle =>
        if mem = '0' then
          state_next <= idle;
        else
          addr_next <= addr;
 
          if rw='1' then    -- write
            state_next <= wr1;
            data_f2s_next <= data_f2s;
 
          else       --read
            state_next <= rd1;
          end if;
 
        end if;
		  
		ready <= '1';
		
      -- 5 cycles - write cycle
      -- setup address and we/oe 40ns > 30 ns
      when wr1 =>
        state_next <= wr2;
      when wr2 =>
        state_next <= wr3;
      -- setup data on bus 40ns > 35 ns
      when wr3 =>
        state_next <= wr4;
      when wr4 =>
        state_next <= wr5;
      -- clear the WE signal 20ns > 5ns
      when wr5 =>
        state_next <= idle;
		  
 
      -- 5 cycles of 20ns = 100ns > 85 ns - read cycle
      when rd1 =>
        state_next <= rd2;
      when rd2 =>
        state_next <= rd3;
      when rd3 =>
        state_next <= rd4;
      when rd4 =>
        state_next <= rd5;
      when rd5 =>
        data_s2f_next <= dio_a;
        state_next <= idle;
    end case;
  end process;
 
  -- look-ahead output logic
  process(state_next)
  begin
    tri_buf <= '1';
    we_buf <= '1';
    oe_buf <= '1';
 
    case state_next is
      when idle =>
      when wr1 =>
        we_buf <= '0';
        tri_buf <= '0';
      when wr2 =>
        we_buf <= '0';
        tri_buf <= '0';
      when wr3 =>
        we_buf <= '0';
        tri_buf <= '0';
      when wr4 =>
        we_buf <= '0';
        tri_buf <= '0';
      when wr5 =>
        tri_buf <= '0';
      
      -- read cycle
      when rd1 =>
        oe_buf <= '0';
      when rd2 =>
        oe_buf <= '0';
      when rd3 =>
        oe_buf <= '0';
      when rd4 =>
        oe_buf <= '0';
      when rd5 =>
        oe_buf <= '0';
    end case;
  end process;
 
  -- to main system
  data_s2f_r <= data_s2f_reg;
  data_s2f_ur <= dio_a;
 
  -- to SRAM
  s1 <= '0' ;
  s2 <= '1' ;
  WE <= we_reg;
  OE <= oe_reg;
  address <= addr_reg;
 
  dio_a <= data_f2s_reg when tri_reg = '0' else (others => 'Z');
 
end arch;