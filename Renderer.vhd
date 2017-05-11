library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.Functions.all;

entity Renderer is
	port (
		clk: in std_logic;		--游戏端时钟，60Hz，可能没用
		scene: in TMap;			--地图信息
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		px, py: in integer; 	--位置
		score: in integer; 		--分数
		status: in TStatus;		--游戏状态
		
		vga_clk: in std_logic;	--VGA端的时钟，25MHz
		pixel_x, pixel_y: in std_logic_vector(9 downto 0);	--查询像素的坐标
		r, g, b: out std_logic_vector(2 downto 0)			--输出像素颜色
	);
end entity;