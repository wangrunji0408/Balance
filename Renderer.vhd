library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Renderer is
	port (
		clk: in std_logic;		--游戏端时钟，60Hz，可能没用
		
		sx, sy: out MapXY;
		pos_type: in TPos;
		
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		scale: in natural;
		
		px, py: in integer; 		--位置
		px1, py1: in integer; 	--位置
		score, score1: in integer; 		--分数
		status: in TStatus;		--游戏状态
		result: in TResult;
		
		vga_clk: in std_logic;	--VGA端的时钟，25MHz
		pixel_x, pixel_y: in natural;	--查询像素的坐标
		color: out TColor;					--输出像素颜色
		
		ax, ay, ax1, ay1: in integer;
		use_keyboard: in boolean
	);
	
	procedure RenderString (
		--Interface with FontReader
		signal id: out natural range 0 to 127;
		signal x, y: out natural range 0 to 15;
		signal b: in std_logic;
		--Input
		str: in string;
		font_color, background_color: in TColor;
		background: in boolean;	-- Is not transparent? 
		size: in natural;
		x0, y0: in natural;
		pixel_x, pixel_y: in natural;
		--Output
		signal rgb: out TColor
		) is
		
		variable temp_id: integer;
		constant dx: integer := pixel_x - x0;
		constant dy: integer := pixel_y - y0;
	begin
		temp_id := dx / size;
		if dx >= 0 and temp_id >= 0 and temp_id < str'high and dy >= 0 and dy < size then
			id <= character'pos(str(temp_id+1));
			x <= dy * 16 / size;
			y <= dx * 16 / size - temp_id * 16;
			if b = '1' then
				rgb <= font_color; 
			elsif background then
				rgb <= background_color;
			end if;
		end if;
	end procedure;
	
end entity;

architecture game of Renderer is
	component ImageReader is
	port (
		clk: in std_logic;
		id: in natural range 0 to 63;	-- 图片编号
		x, y: in natural range 0 to 15;	-- 坐标
		color: out TColor				-- 颜色
	);
	end component;
	component FontReader is
		port (
			clk: in std_logic;
			id: in natural range 0 to 127;	-- 字符编码
			x, y: in natural range 0 to 15;	-- 坐标
			b: out std_logic				-- 输出字符在坐标下的bit
		);
	end component;

	signal image_id, font_id: natural;
	signal x, y: natural range 0 to 15;
	signal image_color: TColor;
	signal font_bit: std_logic;
	signal rgb: TColor;
	signal show_area: boolean;
	
	signal temp_x, temp_y: integer;
	signal sceneX, sceneY, distance, distance1, temp_scene: integer;
	signal clk_num: integer := 0;
	
	function in_circle (dx, dy: integer; r: natural) return boolean is
	begin
		return abs(dx) <= r and abs(dy) <= r and dx * dx + dy * dy <= r * r;
	end function;

begin
	image: ImageReader port map (vga_clk, image_id, x, y, image_color);
	font: FontReader port map (vga_clk, font_id, x, y, font_bit);
	
	temp_x <= pixel_x * scale;
	temp_y <= pixel_y * scale;
	sceneX <= temp_x / unit_size;
	sceneY <= temp_y / unit_size;
	sx <= sceneX;
	sy <= sceneY;
	show_area <= pixel_x < 768;
	color <= rgb;
	
	process(clk)
	begin
		if rising_edge(clk) then
			clk_num <= clk_num + 1;
			if clk_num = 60 then
				clk_num <= 0;
			end if;
		end if;
	end process;

	process(vga_clk)
		variable show: std_logic;
		variable row, col: natural;
	begin
		if rising_edge(vga_clk) then	
			y <= pixel_x; x <= pixel_y;
			
			-- Render Scene
			if show_area then
				if in_circle(temp_x - px, temp_y - py, ball_radius) then
					y <= (temp_x - px) * 8 / ball_radius + 8;
					x <= (temp_y - py) * 8 / ball_radius + 8;
					image_id <= 25;
					rgb <= image_color;
				elsif in_circle(temp_x - px1, temp_y - py1, ball_radius) then
					y <= (temp_x - px1) * 8 / ball_radius + 8;
					x <= (temp_y - py1) * 8 / ball_radius + 8;
					image_id <= 24;
					rgb <= image_color;
				else
					-- Use texture
					x <= (pixel_y * scale - sceneY * unit_size) * 16 / unit_size;
					y <= (pixel_x * scale - sceneX * unit_size) * 16 / unit_size;
					if clk_num < 30 then 
						image_id <= TPos'pos(pos_type);
					else
						image_id <= TPos'pos(pos_type) + 32;
					end if;
					rgb <= image_color;
					
					-- Use color
					--rgb <= ToColor( pos_type );
				end if;
			else
				rgb <= o"000";
			end if;
			
			-- Debug: Show All Images and Fonts
--			row := pixel_y / 16;
--			col := pixel_x / 16;
--			if row = 20 and col < 32 then
--				image_id <= col;
--				rgb <= image_color;
--			elsif row = 21 and col < 32 then
--				image_id <= col + 32;
--				rgb <= image_color;
--			elsif row = 22 and col < 32 then
--				font_id <= col;
--				if font_bit = '1' then rgb <= o"777"; end if;
--			elsif row = 23 and col < 32 then
--				font_id <= col + 32;
--				if font_bit = '1' then rgb <= o"777"; end if;
--			elsif row = 24 and col < 32 then
--				font_id <= col + 64;
--				if font_bit = '1' then rgb <= o"777"; end if;
--			elsif row = 25 and col < 32 then
--				font_id <= col + 96;
--				if font_bit = '1' then rgb <= o"777"; end if;
--			end if;
			
--			RenderString(font_id, x, y, font_bit, "abc bdf", o"777", o"000", false, 50, 0, 270, pixel_x, pixel_y, rgb);
			
			case status is 
				when Init =>
					RenderString(font_id, x, y, font_bit, "Ready", o"777", o"000", true, 32, 200,200, pixel_x, pixel_y, rgb);
				when Pause =>
					RenderString(font_id, x, y, font_bit, "Pause", o"777", o"000", true, 32, 200,200, pixel_x, pixel_y, rgb);
				when Gameover => 
					if result = Win then
						RenderString(font_id, x, y, font_bit, "Win", o"700", o"000", true, 32, 200,200, pixel_x, pixel_y, rgb);
					elsif result = Die then
						RenderString(font_id, x, y, font_bit, "Die", o"777", o"000", true, 32, 200,200, pixel_x, pixel_y, rgb);
					end if;
				when others => null;
			end case;
			
			--RenderString(font_id, x, y, font_bit, "ax0: " & toString(ax), o"777", o"000", true, 16, 0, 480-16*9, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "ay0: " & toString(ay), o"777", o"000", true, 16, 0, 480-16*8, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "ax1: " & toString(ax1), o"777", o"000", true, 16, 0, 480-16*7, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "ay1: " & toString(ay1), o"777", o"000", true, 16, 0, 480-16*6, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "ax: " & toString(ax1), o"777", o"000", true, 16, 0, 480-16*7, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "ay: " & toString(ay1), o"777", o"000", true, 16, 0, 480-16*6, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "az: " & toString(az1), o"777", o"000", true, 16, 0, 480-16*5, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "gx: " & toString(gx1), o"777", o"000", true, 16, 0, 480-16*4, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "gy: " & toString(gy1), o"777", o"000", true, 16, 0, 480-16*3, pixel_x, pixel_y, rgb);
			--RenderString(font_id, x, y, font_bit, "gz: " & toString(gz1), o"777", o"000", true, 16, 0, 480-16*2, pixel_x, pixel_y, rgb);
			if use_keyboard then
				RenderString(font_id, x, y, font_bit, "Input: Keyboard", o"777", o"000", true, 16, 768, 768-16*3, pixel_x, pixel_y, rgb);
			else
				RenderString(font_id, x, y, font_bit, "Input: Gyro", o"777", o"000", true, 16, 768, 768-16*3, pixel_x, pixel_y, rgb);
			end if;
			RenderString(font_id, x, y, font_bit, "Player0: " & toString(conv_integer(score)), o"700", o"000", true, 16, 768, 768-16*2, pixel_x, pixel_y, rgb);
			RenderString(font_id, x, y, font_bit, "Player1: " & toString(conv_integer(score1)), o"700", o"000", true, 16, 768, 768-16, pixel_x, pixel_y, rgb);

			
		end if;
	end process;
end architecture ; -- arch