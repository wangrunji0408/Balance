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
		score: in integer; 		--分数
		status: in TStatus;		--游戏状态
		
		vga_clk: in std_logic;	--VGA端的时钟，25MHz
		pixel_x, pixel_y: in natural;	--查询像素的坐标
		rgb: out TColor					--输出像素颜色
	);
	
	procedure RenderString (
		--Interface with FontReader
		signal id: out natural range 0 to 63;
		signal x, y: out natural range 0 to 15;
		signal b: in std_logic;
		--Input
		str: in string;
		color: in TColor;
		x0, y0: in natural;
		pixel_x, pixel_y: in natural;
		--Output
		signal rgb: out TColor
		) is
		
		variable temp_id: integer;
		constant dx: integer := pixel_x - x0;
		constant dy: integer := pixel_y - y0;
	begin
		temp_id := dx / 16;
		if temp_id >= 0 and temp_id <= str'high and dy >= 0 and dy < 16 then
			id <= temp_id;
			x <= dy;
			y <= dx - temp_id * 16;
			if b = '1' then rgb <= color; end if;
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
			id: in natural range 0 to 63;	-- 字符编码
			x, y: in natural range 0 to 15;	-- 坐标
			b: out std_logic				-- 输出字符在坐标下的bit
		);
	end component;

	signal image_id, font_id: natural;
	signal x, y: natural range 0 to 15;
	signal image_color: TColor;
	signal font_bit: std_logic;
	
	signal temp_x, temp_y: integer;
	signal sceneX, sceneY, distance, distance1, temp_scene: integer;

begin
	image: ImageReader port map (vga_clk, image_id, x, y, image_color);
	font: FontReader port map (vga_clk, font_id, x, y, font_bit);
	
	temp_x <= conv_integer(pixel_x) * scale;
	temp_y <= conv_integer(pixel_y) * scale;
	sceneX <= temp_x / unit_size;
	sceneY <= temp_y / unit_size;
	sx <= sceneX;
	sy <= sceneY;
	distance <= (temp_x - px) * (temp_x - px) + (temp_y - py) * (temp_y - py);
	distance1 <= (temp_x - px1) * (temp_x - px1) + (temp_y - py1) * (temp_y - py1);
	process(vga_clk)
		variable show: std_logic;
	begin
		if rising_edge(vga_clk) then	
			y <= pixel_x; x <= pixel_y;
			
			if ball_radius * ball_radius >= distance then
				rgb <= o"777";
			elsif ball_radius * ball_radius >= distance1 then
				rgb <= o"666";
			else
				rgb <= ToColor( pos_type );
			end if;
			
			if pixel_y < 16 and pixel_x < 16 * 16 then
				image_id <= pixel_x / 16;
				rgb <= image_color;
			elsif pixel_y >= 16 and pixel_y < 32 and pixel_x < 16 * 32 then
				font_id <= pixel_x / 16;
				if font_bit = '1' then rgb <= o"777"; end if;
			elsif pixel_y >= 32 and pixel_y < 48 and pixel_x < 16 * 32 then
				font_id <= pixel_x / 16 + 32;
				if font_bit = '1' then rgb <= o"777"; end if;
			end if;
			
			RenderString(font_id, x, y, font_bit, "test string", o"777", 0, 100, pixel_x, pixel_y, rgb);
			
		end if;
	end process;
end architecture ; -- arch


architecture test_image_font of Renderer is
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
			id: in natural range 0 to 63;	-- 字符编码
			x, y: in natural range 0 to 15;	-- 坐标
			b: out std_logic				-- 输出字符在坐标下的bit
		);
	end component;

	signal image_id, font_id: natural;
	signal x, y: natural range 0 to 15;
	signal image_color: TColor;
	signal font_bit: std_logic;
begin
	image: ImageReader port map (vga_clk, image_id, x, y, image_color);
	font: FontReader port map (vga_clk, font_id, x, y, font_bit);
	y <= pixel_x; x <= pixel_y;
	
	
	process( vga_clk )
	begin
		if rising_edge(vga_clk) then
		rgb <= o"000";
		if pixel_y < 16 and pixel_x < 16 * 16 then
			image_id <= pixel_x / 16;
			rgb <= image_color;
		elsif pixel_y >= 16 and pixel_y < 32 and pixel_x < 16 * 32 then
			font_id <= pixel_x / 16;
			if font_bit = '1' then rgb <= o"777"; end if;
		elsif pixel_y >= 32 and pixel_y < 48 and pixel_x < 16 * 32 then
			font_id <= pixel_x / 16 + 32;
			if font_bit = '1' then rgb <= o"777"; end if;
		end if;
		end if;
	end process ;
end test_image_font ; -- arch