library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Physics is
	port (
		clk, rst, pause: in std_logic;	--游戏端时钟60Hz，复位（恢复初态），暂停（0为暂停，1为正常）
		scene: in TMap;			--地图信息
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		ax, ay: in integer; 	--加速度
		
		px, py: buffer integer; 	--位置
		add_score: out integer; 	--加分
		result: buffer TResult		--结果
	);
end entity;
architecture arch of Physics is

	signal temp_px, temp_py, temp_vx, temp_vy, temp_sceneX, temp_sceneY: integer;
	signal temp_scene: integer;
	signal vx, vy: integer:=0;
begin
	temp_px <= px + temp_vx;
	temp_py <= py + temp_vy;
	temp_vx <= vx + ax;
	temp_vy <= vy + ay;
	temp_sceneX <= temp_px / unit_size;
	temp_sceneY <= temp_py / unit_size;
	temp_scene <= temp_sceneX * 64 + temp_sceneY;
	process(clk)
	begin
		if rst = '0' then
			px <= 200;
			py <= 200;
			vx <= 0;
			vy <= 0;
			add_score <= 0;
			result <= Normal;
		elsif rising_edge(clk) then
			if pause = '0' or result = Die or result = Win then
				add_score <= 0;
			else
				px <= temp_px;
				py <= temp_py;
				vx <= temp_vx;
				vy <= temp_vy;
				if scene(temp_scene) = None then
					result <= Die;
					add_score <= 0;
				elsif scene(temp_scene) = terminal then
					result <= Win;
					add_score <= 1;
				else
					add_score <= 1;
				end if;
			end if;
		end if;
	end process;

end architecture ; -- arch