library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity SceneReader is
	port (
		available: out std_logic;
		scene: out TMap
	);
end entity;

architecture arch of SceneReader is
	component digital_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
	);
	END component;

	signal address: std_logic_vector(13 downto 0);
	signal clk: std_logic;
	signal q: std_logic_vector(0 downto 0);
begin
	dr: digital_rom port map (address, clk, q);
	process
	begin
		clk <= '0';
		genclk : for i in 0 to TMap'high * 8 + 100 loop
			clk <= not clk;
			wait for 5 ns;
		end loop ; -- genclk
		wait;
	end process;

	process
		variable v: std_logic_vector(1 downto 0);
	begin
		available <= '0';
		for i in TMap'range loop
			address <= std_logic_vector(to_unsigned(i, 12)) & "0";
			wait for 20 ns; v(0) := q(0);
			address <= std_logic_vector(to_unsigned(i, 12)) & "1";
			wait for 20 ns; v(1) := q(0);
			scene(i) <= ToPosType(v);
		end loop ;
		available <= '1';
		wait;
	end process ;
end arch ; -- arch