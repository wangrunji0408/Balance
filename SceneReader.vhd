library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity SceneReader is
	port (
		clk100, rst: in std_logic;
		available: out std_logic;
		scene: out TMap
	);
end entity;

architecture arch of SceneReader is
	component rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
	);
	END component;

	signal address: std_logic_vector(11 downto 0);
	signal clk: std_logic;
	signal q: std_logic_vector(3 downto 0);
begin
	rrr: rom port map (address, clk100, q);

	process(rst)
	begin
		available <= '0';
		if rst = '0' then
			for i in TMap'range loop
				address <= std_logic_vector(to_unsigned(i, 12));
				scene(i) <= ToPosType( q );
			end loop;
		end if;
		available <= '1';
	end process;
	
end arch ; -- arch