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
		query_sx, query_sy: out MapXY;
		pos_type: in TPos;
		start_x, start_y: in MapXY;
		gate2_x, gate2_y: in MapXY;
		ready: in std_logic;
		
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		ax, ay: in integer; 	--加速度
		vx, vy: buffer integer;
		px, py: buffer integer; 	--位置
		vx1, vy1: in integer;
		px1, py1: in integer; 	--位置
		score: buffer integer; 			--分
		result: buffer TResult;		--结果
		
		show_radius: buffer natural
	);
end entity;
architecture arch of Physics is
	signal temp_px, temp_py, temp_vx, temp_vy, temp_sceneX, temp_sceneY, temp_remX, temp_remY, temp_temp_vx, temp_temp_vy: integer;
	signal temp_scene: integer;
	signal sx, sy: natural;
	signal temp_wallx, temp_wally, wall, wallx, wally: boolean;
	signal temp_type: TPos;
	signal clk_num: integer := 0;
	signal clk1000: std_logic;
	signal near, last_near, collide: boolean;
	constant vmax: natural := 4096;
	
	function s2p (s: MapXY; unit_size: natural) return natural is
	begin
		return s * unit_size + unit_size / 2;
	end function;
begin
	near <= in_circle(px - px1, py - py1, ball_radius * 2);
	collide <= not last_near and near;
	
	wall <= isWall(temp_type);
	temp_wallx <= temp_sceneX /= sx and wall;
	temp_wally <= temp_sceneY /= sy and wall;
	wallx <= (not temp_wally and temp_wallx) or (temp_wally and temp_wallx and (abs(vx) < abs(vy) / 4 or not (abs(vx) / 4 >= abs(vy))));
	wally <= (not temp_wallx and temp_wally) or (temp_wallx and temp_wally and (not(abs(vx) < abs(vy) / 4) or (abs(vx) / 4 >= abs(vy))));
	temp_px <= s2p(gate2_x, unit_size) when temp_type = Gate1 else px + vx;
	temp_py <= s2p(gate2_y, unit_size) when temp_type = Gate1 else py + vy;
	temp_temp_vx <= -vx when wallx and temp_type = IronWall else
					-(vx / 2 + temp_remX) when wallx and temp_type = GlassWall else
					-(vx / 10 + 2 * temp_remX) when wallx and temp_type = WoodWall else
					vx + ax when temp_type = Ice else
					vx + ax - temp_remX when temp_type = Land else
					vx + ax - temp_remX * 2 when temp_type = Pin else
					-2 * vx when (temp_type = SpringL and temp_remX >= 0) or (temp_type = SpringR and temp_remX <= 0) else vx + ax;
	temp_temp_vy <= -vy when wally and temp_type = IronWall else
					-(vy / 2 + temp_remY) when wally and temp_type = GlassWall else
					-(vy / 10 + 2 * temp_remY)  when wally and temp_type = WoodWall else 
					vy + ay when temp_type = Ice else
					vy + ay - temp_remY when temp_type = Land else
					vy + ay - temp_remY * 2 when temp_type = Pin else
					-2 * vy when (temp_type = SpringU and temp_remY >= 0) or (temp_type = SpringD and temp_remY <= 0) else vy + ay;
	temp_sceneX <= temp_px / unit_size;
	temp_sceneY <= temp_py / unit_size;
	temp_remX <= 3 when vx > 0 else
					-3 when vx < 0 else 0;
	temp_remY <= 3 when vy > 0 else
					-3 when vy < 0 else 0;
					 
	process (temp_temp_vx, temp_temp_vy)
		variable vx, vy: integer;
		constant acc: natural := 10;
	begin
		vx := temp_temp_vx;
		vy := temp_temp_vy;
		if temp_type = AccR then
			vx := vx + acc;
		elsif temp_type = AccL then
			vx := vx - acc;
		elsif temp_type = AccD then
			vy := vy + acc;
		elsif temp_type = AccU then
			vy := vy - acc;
		end if;
		
		if collide then
			vx := vx1;
			vy := vy1;
		end if;
		
		vx := limit(vx, -vmax, vmax);
		vy := limit(vy, -vmax, vmax);
		temp_vx <= vx;
		temp_vy <= vy;
	end process;

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
			show_radius <= ball_radius;
			last_ready := '0';
		elsif falling_edge(clk60) then
			if last_ready = '0' and ready = '1' then
				px <= s2p(start_x, unit_size);
				py <= s2p(start_y, unit_size);
				show_radius <= ball_radius;
			elsif pause = '0' or result = Die or result = Win then
				
			else
				if not wall then 
					px <= temp_px;
					py <= temp_py;
				end if;
				vx <= temp_vx;
				vy <= temp_vy;
				sx <= temp_sceneX;
				sy <= temp_sceneY;
				if temp_type = Hole then
					show_radius <= show_radius - 1;
					if show_radius < ball_radius then 
						result <= Die;
					end if;
				elsif temp_type = EndPoint then
					result <= Win;
					score <= score + 1;
					show_radius <= ball_radius;
				else
					score <= score + 1;
					show_radius <= ball_radius;
				end if;
			end if;
			last_ready := ready;
			last_near <= near;
		end if;
	end process;

end architecture ; -- arch