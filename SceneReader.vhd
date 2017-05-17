library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity SceneReader is
	port (
		clk100, rst: in std_logic;
		available: out std_logic;
		scene: out TMap;
		start_x, start_y: out natural
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
	signal q: std_logic_vector(3 downto 0);
	
begin
	rrr: rom port map (address, clk100, q);
	
	process(rst, clk100)
		variable i: TMap'range := 0;
	begin
		if rst = '0' then
			i := 0;
			available <= '0';
		elsif rising_edge(clk100) then
			address <= std_logic_vector(to_unsigned(i, 12));
			scene(i) <= ToPosType(q);
			if ToPosType(q) = Start then
				start_x <= i / 16;
				start_y <= to_integer(to_unsigned(i, 4));
			end if;
			i := i + 1;
			if i = TMap'high then available <= '1'; end if;
		end if;
	end process;
	
end arch ; -- arch