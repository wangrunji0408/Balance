library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity SceneReader is
	port (
		clk100, rst: in std_logic;
		x1, y1, x2, y2: in MapXY;		-- 坐标
		p1, p2: out TPos;  				-- 类型
		start_x, start_y: out MapXY;	-- 起始点
		gate2_x, gate2_y: out MapXY;
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
			q_a		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
			q_b		: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
		);
	END component;

	signal address0, address1, address2: std_logic_vector(11 downto 0);
	signal q1, q2: std_logic_vector(5 downto 0);
	signal p0: TPos;
	signal temp_ready: std_logic := '0';
	signal clk10: std_logic := '0';
begin
	rom: SceneROM port map (address1, address2, clk100, q1, q2);
	address1 <= std_logic_vector(to_unsigned(y1, 6) & to_unsigned(x1, 6));
	address2 <= std_logic_vector(to_unsigned(y2, 6) & to_unsigned(x2, 6)) when temp_ready = '1' else address0;
	p1 <= ToPosType(q1);
	p0 <= ToPosType(q2);
	p2 <= p0;
	ready <= temp_ready;

	process(clk100)
		variable i: natural range 0 to 4 := 0;
	begin
		if rising_edge(clk100) then
			if i = 4 then
				clk10 <= not clk10;
				i := 0;
			else
				i := i + 1;
			end if;
		end if;
	end process;
	
	-- 临时占用端口2进行初始化
	process(rst, clk100)
		variable i: natural range 0 to 64*64 := 0;
	begin
		if rst = '0' then
			i := 0;
			temp_ready <= '0';
		elsif rising_edge(clk10) and temp_ready = '0' then
			address0 <= std_logic_vector(to_unsigned(i+1, 12));
			if p0 = StartPoint then
				start_y <= i / 64;
				start_x <= i mod 64;
			elsif p0 = Gate2 then
				gate2_y <= i / 64;
				gate2_x <= i mod 64;
			end if;
			i := i + 1;
			if i = 64*64 then temp_ready <= '1'; end if;
		end if;
	end process;
	
end arch ; -- arch