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
		px, py: in integer; 	--位置
		score: in integer; 		--分数
		status: in TStatus;		--游戏状态
		
		vga_clk: in std_logic;	--VGA端的时钟，25MHz
		pixel_x, pixel_y: in std_logic_vector(9 downto 0);	--查询像素的坐标
		r, g, b: out std_logic_vector(2 downto 0)			--输出像素颜色
	);
end entity;
architecture arch of Renderer is
	signal temp_x, temp_y: integer;
	signal sceneX, sceneY, distance, temp_scene: integer;

begin
	temp_x <= conv_integer(pixel_x) * scale;
	temp_y <= conv_integer(pixel_y) * scale;
	sceneX <= temp_x / unit_size;
	sceneY <= temp_y / unit_size;
	temp_scene <= sceneX * 64 + sceneY;
	distance <= (temp_x - px) * (temp_x - px) + (temp_y - py) * (temp_y - py);
	process(vga_clk)
	begin
		if rising_edge(vga_clk) then
		if ball_radius * ball_radius >= distance then
			r <= "111";
			g <= "111";
			b <= "111";
		else
			case scene(temp_scene) is
				when None => r <= "000"; g <= "000"; b <= "000";
				when Road => r <= "010"; g <= "010"; b <= "010";
				when Terminal => r <= "111"; g <= "000"; b <= "000";
				when others => r <= "000"; g <= "111"; b <= "000";
			end case;
		end if;
		end if;
	end process;
end architecture ; -- arch