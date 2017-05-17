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
		start_x, start_y: in natural;
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		ax, ay: in integer; 	--加速度
		
		px, py: buffer integer; 	--位置
		add_score: out integer; 	--加分
		result: buffer TResult;		--结果
		
		sx, sy: buffer natural;
		nowt: out TPos 
	);
end entity;
architecture arch of Physics is

	signal temp_px, temp_py, temp_vx, temp_vy, temp_sceneX, temp_sceneY: integer;
	signal temp_scene: integer;
	signal vx, vy: integer := 0;
	signal wallx, wally: boolean;
	signal temp_type: TPos;
begin
	wallx <= temp_sceneX /= sx and temp_type = Wall;
	wally <= temp_sceneY /= sy and temp_type = Wall;
	temp_px <= px + vx;
	temp_py <= py + vy;
	temp_vx <= -vx when wallx else vx + ax;
	temp_vy <= -vy when wally else vy + ay;
	temp_sceneX <= temp_px / unit_size;
	temp_sceneY <= temp_py / unit_size;
	temp_scene <= temp_sceneX * 16 + temp_sceneY;
	temp_type <= scene(temp_scene);
	
	nowt <= temp_type;
	
	process(clk)
	begin
		if rst = '0' then
			px <= start_x * unit_size + unit_size / 2;
			py <= start_y * unit_size + unit_size / 2;
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
				sx <= temp_sceneX;
				sy <= temp_sceneY;
				if temp_type = None then
					result <= Die;
					add_score <= 0;
				elsif temp_type = terminal then
					result <= Win;
					add_score <= 1;
				else
					add_score <= 1;
				end if;
			end if;
		end if;
	end process;

end architecture ; -- arch