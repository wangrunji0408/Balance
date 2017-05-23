library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity SceneReader is
	port (
		clk100, rst: in std_logic;
		x1, y1, x2, y2: in natural range 0 to 15;	-- 坐标
		p1, p2: out TPos;  							-- 类型
		start_x, start_y: out natural range 0 to 15;	-- 起始点
		ready: out std_logic
	);
end entity;

architecture arch of SceneReader is
	component SceneROM IS
		PORT
		(
			address_a		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			address_b		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			clock		: IN STD_LOGIC;
			q_a		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
			q_b		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
		);
	END component;

	signal address0, address1, address2: std_logic_vector(11 downto 0);
	signal q1, q2: std_logic_vector(3 downto 0);
	signal p0: TPos;
	signal temp_ready: std_logic := '0';
begin
	rom: SceneROM port map (address1, address2, clk100, q1, q2);
	address1 <= std_logic_vector(to_unsigned(y1 * 16 + x1, 12));
	address2 <= std_logic_vector(to_unsigned(y2 * 16 + x2, 12)) when temp_ready = '1' else address0;
	p1 <= ToPosType(q1);
	p0 <= ToPosType(q2);
	p2 <= p0;
	ready <= temp_ready;

	-- 临时占用端口2进行初始化
	process(rst, clk100)
		variable i: natural range 0 to 16*16-1 := 0;
	begin
		if rst = '0' then
			i := 0;
			temp_ready <= '0';
		elsif rising_edge(clk100) and temp_ready = '0' then
			address0 <= std_logic_vector(to_unsigned(i, 12));
			if p0 = Start then
				start_y <= i / 16;
				start_x <= to_integer(to_unsigned(i, 4));
			end if;
			i := i + 1;
			if i = 16*16-1 then temp_ready <= '1'; end if;
		end if;
	end process;
	
end arch ; -- arch