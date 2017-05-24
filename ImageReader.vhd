library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

-- 图片读取接口
-- 格式：分辨率16*16，每个像素3*3bit
entity ImageReader is
	port (
		clk: in std_logic;
		id: in natural range 0 to 63;	-- 图片编号
		x, y: in natural range 0 to 15;	-- 坐标
		color: out TColor				-- 颜色
	);
end entity;

architecture arch of ImageReader is
	component ImageROM IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0); -- [编号6][x4][y4]
		clock		: IN STD_LOGIC;
		q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
	);
	END component;
	signal address: STD_LOGIC_VECTOR(13 downto 0);
begin
	rom: ImageROM port map (address, clk, color);
	address <= std_logic_vector(to_unsigned(id, 6)) & 
					std_logic_vector(to_unsigned(x, 4)) & 
					std_logic_vector(to_unsigned(y, 4));
end arch ; -- arch