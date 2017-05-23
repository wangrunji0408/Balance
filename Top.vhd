library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Top is
	port (
		-- 键盘输入
		keyboard_data, keyboard_clk: in std_logic;
		-- 陀螺仪输入
		
		-- 总时钟
		clk100: in std_logic;
		-- 复位，暂停按钮
		rst, pause: in std_logic;
		-- 显示器输出
		vga_hs, vga_vs: out std_logic;
		vga_r, vga_g, vga_b : out std_logic_vector (2 downto 0);
		-- Debug
		debug_display: out DisplayNums
	);
end entity;

architecture arch of Top is
	component KeyboardToWASD is
		port (
			ps2_data, ps2_clk: in std_logic;
			clk, rst: in std_logic;
			w, a, s, d, up, left, down, right: out std_logic
		);
	end component;
	component WASDToAcc is
		port (
			w, a, s, d: in std_logic;
			ax, ay: out integer
		);
	end component;
	component vga640480 is
		port(
			reset       :         in  STD_LOGIC;
			clk100      :         in  STD_LOGIC; --100M时钟输入
			x, y		:		  out std_logic_vector(9 downto 0); --输出当前要绘制的像素位置
			color_in :    		in TColor; --输入给定像素位置的颜色
			clk25       :		  out std_logic; --输出25MHz工作时钟
			hs,vs       :         out STD_LOGIC; --行同步、场同步信号
			r,g,b       :         out STD_LOGIC_vector(2 downto 0) --输出的颜色信号
	  );
	end component;
	component Renderer is
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
	end component;

	for all: Renderer use entity work.Renderer(game);
	--for all: Renderer use entity work.Renderer(test_image_font);
	
	component Physics is
		port (
			clk60, clk100, rst, pause: in std_logic;	--游戏端时钟60Hz，复位（恢复初态），暂停（0为暂停，1为正常）
			
			-- Interfaces with SceneReader
			query_sx, query_sy: out MapXY;
			pos_type: in TPos;
			start_x, start_y: in MapXY;
			ready: in std_logic;
			
			unit_size: in natural; 	--每格的边长
			ball_radius: in natural;--球的半径
			ax, ay: in integer; 	--加速度
			
			px, py: buffer integer; 	--位置
			score: buffer integer; 	--分
			result: buffer TResult;		--结果
			
			sx, sy: buffer natural
		);
	end component;
	
	component StatusController is
	port (
		clk: in std_logic;			--娓告垙绔椂閽燂紝60Hz
		rst, pause_in: in std_logic;	--澶嶄綅锛屾殏鍋滄寜閽
		result: in TResult;			--鍥炲悎缁撴潫鐘舵€
		status: buffer TStatus;		--娓告垙鐘舵€	
		phy_rst, phy_pause: out std_logic --鎺у埗鐗╃悊寮曟搸鐨勫浣嶃€佹殏鍋滐紙褰撳墠鏄洿鎺ヤ笌鎸夐挳鍏宠仈锛屾湭鏉ュ彲鑳芥湁鍙橈級
	);
	end component;
	
	component SceneReader is
	port (
		clk100, rst: in std_logic;
		x1, y1, x2, y2: MapXY;	-- 坐标
		p1, p2: out TPos;  							-- 类型
		start_x, start_y: out MapXY;	-- 起始点
		ready: out std_logic
	);
	end component;
	
	signal ax, ay, px, py, score: integer;
	signal ax1, ay1, px1, py1, score1: integer;
	signal start_x, start_y: MapXY;
	signal w, a, s, d, w1, a1, s1, d1: std_logic;
	signal vga_vs_temp: std_logic;
	signal color: TColor;
	signal clk25, clk60: std_logic;
	signal vga_x, vga_y: std_logic_vector(9 downto 0);
	signal result, result1: TResult;
	constant unit_size: natural := 50;
	constant ball_radius: natural := 20;
	constant scale: natural := 5;
	signal status: TStatus := Init;
	signal phy_rst, phy_pause: std_logic;
	signal ready: std_logic;
	
	signal physics_sx, physics_sy: MapXY;
	signal physics_pos_type: TPos;
	signal renderer_sx, renderer_sy: MapXY;
	signal renderer_pos_type: TPos;
	
	-- for debug:
	signal result_num: std_logic_vector(3 downto 0); 
	signal px_vec, py_vec: std_logic_vector(11 downto 0);
	signal sx, sy: natural;
begin
	clk60 <= vga_vs_temp;
	vga_vs <= vga_vs_temp;
	
	ktw: KeyboardToWASD port map (keyboard_data, keyboard_clk, clk100, not rst, w, a, s, d, w1, a1, s1, d1);
	wta0: WASDToAcc port map (w, a, s, d, ax, ay);
	wta1: WASDToAcc port map (w1, a1, s1, d1, ax1, ay1);
	reader: SceneReader port map (clk100, rst, physics_sx, physics_sy, renderer_sx, renderer_sy,
					physics_pos_type, renderer_pos_type, start_x, start_y, ready);
	phy: Physics port map (clk60, clk100, phy_rst, phy_pause, 
									physics_sx, physics_sy, physics_pos_type, start_x, start_y, ready,
									unit_size, ball_radius, ax, ay, px, py, score, result, sx, sy);
	ctrl: StatusController port map (clk60, rst, pause, result, status, phy_rst, phy_pause);
	vga: vga640480 port map (rst, clk100, vga_x, vga_y, color, clk25, vga_hs, vga_vs_temp, vga_r, vga_g, vga_b);
	ren: Renderer port map (
		clk => clk60,
		sx => renderer_sx,
		sy => renderer_sy,
		pos_type => renderer_pos_type,
		unit_size => unit_size,
		ball_radius => ball_radius,
		scale => scale,
		px => px, py => py,
		px1 => px1, py1 => py1,
		score => score,
		status => Init,
		vga_clk => clk25,
		pixel_x => to_integer(unsigned(vga_x)),
		pixel_y => to_integer(unsigned(vga_y)),
		rgb => color
	);
	
	result_num <= "0000" when result = Normal else
					"0001" when result = Win else
					"0010" when result = Die else
					"1111";
	
	px_vec <= std_logic_vector( to_unsigned(px, 12) );
	py_vec <= std_logic_vector( to_unsigned(py, 12) );
	debug_display(6) <= DisplayNumber(start_x);
	debug_display(5) <= DisplayNumber(start_y);

	--debug_display(3) <= DisplayNumber( "000" & rst );
	--debug_display(2) <= DisplayNumber( "000" & pause );
	
	debug_display(0) <= DisplayNumber(ay);
	debug_display(1) <= DisplayNumber(ax);
	--debug_display(0) <= DisplayNumber(scancode(3 downto 0));
	--debug_display(1) <= DisplayNumber(scancode(7 downto 4));
end arch ; -- arch