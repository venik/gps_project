library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

	-- Add your library and packages declaration here ...

entity top_level_tb is
end top_level_tb;

architecture TB_ARCHITECTURE of top_level_tb is
	-- Component declaration of the tested unit
	component top_level
	port(
		rs232_in : in STD_LOGIC;
		rs232_out : out STD_LOGIC;
		address : out STD_LOGIC_VECTOR(17 downto 0);
		dio_a : inout STD_LOGIC_VECTOR(7 downto 0);
		s1 : out STD_LOGIC;
		s2 : out STD_LOGIC;
		WE : out STD_LOGIC;
		OE : out STD_LOGIC;
		q : in STD_LOGIC_VECTOR(1 downto 0);
		i : in STD_LOGIC_VECTOR(1 downto 0);
		ld_gps : in STD_LOGIC;
		sclk : out STD_LOGIC;
		sdata : out STD_LOGIC;
		cs : out STD_LOGIC;
		gps_clkout : in STD_LOGIC;
		test_spot : out STD_LOGIC;
		clk : in STD_LOGIC;
		u10 : out STD_LOGIC_VECTOR(7 downto 0);
		u9 : out STD_LOGIC_VECTOR(7 downto 0);
		u8 : out STD_LOGIC_VECTOR(7 downto 0) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal rs232_in : STD_LOGIC;
	signal q : STD_LOGIC_VECTOR(1 downto 0);
	signal i : STD_LOGIC_VECTOR(1 downto 0);
	signal ld_gps : STD_LOGIC;
	signal gps_clkout : STD_LOGIC;
	signal clk : STD_LOGIC;
	signal dio_a : STD_LOGIC_VECTOR(7 downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	signal rs232_out : STD_LOGIC;
	signal address : STD_LOGIC_VECTOR(17 downto 0);
	signal s1 : STD_LOGIC;
	signal s2 : STD_LOGIC;
	signal WE : STD_LOGIC;
	signal OE : STD_LOGIC;
	signal sclk : STD_LOGIC;
	signal sdata : STD_LOGIC;
	signal cs : STD_LOGIC;
	signal test_spot : STD_LOGIC;
	signal u10 : STD_LOGIC_VECTOR(7 downto 0);
	signal u9 : STD_LOGIC_VECTOR(7 downto 0);
	signal u8 : STD_LOGIC_VECTOR(7 downto 0);

	-- Add your code here ...

begin

	-- Unit Under Test port map
	UUT : top_level
		port map (
			rs232_in => rs232_in,
			rs232_out => rs232_out,
			address => address,
			dio_a => dio_a,
			s1 => s1,
			s2 => s2,
			WE => WE,
			OE => OE,
			q => q,
			i => i,
			ld_gps => ld_gps,
			sclk => sclk,
			sdata => sdata,
			cs => cs,
			gps_clkout => gps_clkout,
			test_spot => test_spot,
			clk => clk,
			u10 => u10,
			u9 => u9,
			u8 => u8
		);

	-- Add your stimulus here ...
process begin
clk <= '1'; wait for 10 ns; -- clk high for T1 ns
clk <= '0'; wait for 10 ns; -- clk low for T2 ns
end process;

--CLOCK_CLK : process
--begin
--	if END_SIM = FALSE then
--		clk <= '0';
--		wait for 10 ns; --0 fs
--	else
--		wait;
--	end if;
--	if END_SIM = FALSE then
--		clk <= '1';
--		wait for 10 ns; --5 ns
--	else
--		wait;
--	end if;
-- end process;   

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_top_level of top_level_tb is
	for TB_ARCHITECTURE
		for UUT : top_level
			use entity work.top_level(behavioral);
		end for;
	end for;
end TESTBENCH_FOR_top_level;

