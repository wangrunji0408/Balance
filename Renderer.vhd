library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Renderer is
	port (
		clk: in std_logic;		--游戏端时钟，60Hz，可能没用
		
		sx, sy: out natural range 0 to 15;
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
end entity;

architecture arch of Renderer is
	component ImageReader is
	port (
		clk: in std_logic;
		id: in natural range 0 to 15;	-- 图片编号
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

	signal temp_x, temp_y: integer;
	signal sceneX, sceneY, distance, distance1, temp_scene: integer;

begin
	temp_x <= conv_integer(pixel_x) * scale;
	temp_y <= conv_integer(pixel_y) * scale;
	sceneX <= temp_x / unit_size;
	sceneY <= temp_y / unit_size;
	sx <= sceneX;
	sy <= sceneY;
	distance <= (temp_x - px) * (temp_x - px) + (temp_y - py) * (temp_y - py);
	distance1 <= (temp_x - px1) * (temp_x - px1) + (temp_y - py1) * (temp_y - py1);
	process(vga_clk)
	begin
		if rising_edge(vga_clk) then
			if ball_radius * ball_radius >= distance then
				rgb <= o"777";
			elsif ball_radius * ball_radius >= distance1 then
				rgb <= o"666";
			else
				rgb <= ToColor( pos_type );
			end if;
		end if;
	end process;
end architecture ; -- arch


architecture test_image_font of Renderer is
	component ImageReader is
	port (
		clk: in std_logic;
		id: in natural range 0 to 15;	-- 图片编号
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
	process( pixel_x, pixel_y )
	begin
		if pixel_y < 16 and pixel_x < 16 * 16 then
			image_id <= pixel_x / 16;
			rgb <= image_color;
		elsif pixel_y >= 16 and pixel_y < 32 and pixel_x < 16 * 32 then
			font_id <= pixel_x / 16;
			if font_bit = '1' then rgb <= o"777"; else rgb <= o"000"; end if;
		elsif pixel_y >= 32 and pixel_y < 48 and pixel_x < 16 * 32 then
			font_id <= pixel_x / 16 + 16;
			if font_bit = '1' then rgb <= o"777"; else rgb <= o"000"; end if;
		else
			rgb <= o"000";
		end if;
	end process ;
end test_image_font ; -- arch