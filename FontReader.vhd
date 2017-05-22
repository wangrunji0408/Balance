library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

-- 点阵字体读取接口
-- 字符编码：Base64
entity FontReader is
	port (
		clk: in std_logic;
		id: in natural range 0 to 63;	-- 字符编码
		x, y: in natural range 0 to 15;	-- 坐标
		b: out std_logic				-- 输出字符在坐标下的bit
	);
end entity;

architecture arch of FontReader is
	component FontROM IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (5 DOWNTO 0); -- [编号6][y4][x4]
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (255 DOWNTO 0)
	);
	END component;
	signal address : STD_LOGIC_VECTOR (5 DOWNTO 0);
	signal q: STD_LOGIC_VECTOR (255 DOWNTO 0);
begin
	rom: FontROM port map (address, clk, q);
	address <= std_logic_vector(to_unsigned(id, 6));
	b <= q(y * 16 + x);
end arch ; -- arch