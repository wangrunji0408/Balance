library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Layer is
	port (
		clk: in std_logic;
		pixel_x, pixel_y: in natural;	--查询像素的坐标
		show: out std_logic;				--输出是否不透明
		rgb: out TColor					--输出像素颜色
	);
end entity;