library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Physics is
	port (
		clk60, clk100, rst, pause: in std_logic;	--游戏端时钟60Hz，复位（恢复初态），暂停（0为暂停，1为正常）
		
		-- Interfaces with SceneReader
		query_sx, query_sy: out natural range 0 to 15;
		pos_type: in TPos;
		start_x, start_y: in natural range 0 to 15;
		ready: in std_logic;
		
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		ax, ay: in integer; 	--加速度
		
		px, py: buffer integer; 	--位置
		score: buffer integer; 			--分
		result: buffer TResult;		--结果
		
		sx, sy: buffer natural
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
	-- query pos type
	query_sx <= temp_sceneX;
	query_sy <= temp_sceneY;
	temp_type <= pos_type;
	
	process(clk60)
		variable last_ready: std_logic := '0';
	begin
		if rst = '0' then
			px <= 0;
			py <= 0;
			vx <= 0;
			vy <= 0;
			score <= 0;
			result <= Normal;
		elsif rising_edge(clk60) then
			if last_ready = '0' and ready = '1' then
				px <= start_x * unit_size + unit_size / 2;
				py <= start_y * unit_size + unit_size / 2;
			elsif pause = '0' or result = Die or result = Win then
				
			else
				px <= temp_px;
				py <= temp_py;
				vx <= temp_vx;
				vy <= temp_vy;
				sx <= temp_sceneX;
				sy <= temp_sceneY;
				if temp_type = None then
					result <= Die;
				elsif temp_type = terminal then
					result <= Win;
					score <= score + 1;
				else
					score <= score + 1;
				end if;
			end if;
			last_ready := ready;
		end if;
	end process;

end architecture ; -- arch