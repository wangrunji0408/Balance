library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Renderer is
	port (
		clk: in std_logic;		--游戏端时钟，60Hz，可能没用
		scene: in TMap;			--地图信息
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		scale: in natural;
		px, py: in integer; 		--位置
		px1, py1: in integer; 	--位置
		score: in integer; 		--分数
		status: in TStatus;		--游戏状态
		
		vga_clk: in std_logic;	--VGA端的时钟，25MHz
		pixel_x, pixel_y: in std_logic_vector(9 downto 0);	--查询像素的坐标
		rgb: out TColor										--输出像素颜色
	);
end entity;

architecture arch of Renderer is
	signal temp_x, temp_y: integer;
	signal sceneX, sceneY, distance, distance1, temp_scene: integer;

begin
	temp_x <= conv_integer(pixel_x) * scale;
	temp_y <= conv_integer(pixel_y) * scale;
	sceneX <= temp_x / unit_size;
	sceneY <= temp_y / unit_size;
	temp_scene <= sceneX * 16 + sceneY;
	distance <= (temp_x - px) * (temp_x - px) + (temp_y - py) * (temp_y - py);
	distance1 <= (temp_x - px1) * (temp_x - px1) + (temp_y - py1) * (temp_y - py1);
	process(vga_clk)
	begin
		if rising_edge(vga_clk) then
			if ball_radius * ball_radius >= distance then
				rgb <= "111111111";
			elsif ball_radius * ball_radius >= distance1 then
				rgb <= "110110110";
			else
				rgb <= ToColor( scene(temp_scene) );
			end if;
		end if;
	end process;
end architecture ; -- arch