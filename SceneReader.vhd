library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity SceneReader is
	port (
		clk100: in std_logic;
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
	--dr: digital_rom port map (address, clk100, q);

	--process
	--	variable v: std_logic_vector(1 downto 0);
	--begin
	--	available <= '0';
	--	for i in TMap'range loop
	--		address <= std_logic_vector(to_unsigned(i, 13)) & "0";
	--		wait until clk100 = '0'; v(0) := q(0);
	--		address <= std_logic_vector(to_unsigned(i, 13)) & "1";
	--		wait until clk100 = '1'; v(1) := q(0);
	--		
	--		v := std_logic_vector(to_unsigned(i, 2));
	--		
	--		scene(i) <= ToPosType(v);
	--	end loop ;
	--	available <= '1';
	--	wait;
	--end process ;
	process(clk)
	begin
	for i in TMap'range loop
		scene(i) <= Road;--ToPosType( std_logic_vector(to_unsigned(i, 2)) );
	end loop;
	end process;
	
end arch ; -- arch