library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Top is
	port (
		-- 键盘输入
		keyboard_data, keyboard_clk: in std_logic;
		-- 陀螺仪输入
		i2c_data, i2c_clk: inout std_logic;
		i2c_data1, i2c_clk1: inout std_logic;
		gyro1_vcc: out std_logic;
		gyro_rst: in std_logic;
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

	component Gyro is
		port (
			clk100, rst: in std_logic;
			i2c_data, i2c_clk: inout std_logic;
			ax_out, ay_out: out integer;
			ax1, ay1, az1: out integer;
			gx1, gy1, gz1: out integer
		);
	end component;

	component vga640480 is
		port(
			reset       :         in  STD_LOGIC;
			clk100      :         in  STD_LOGIC; --100M时钟输入
			x, y		:		  out natural; --输出当前要绘制的像素位置
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
			result: in TResult;
			
			vga_clk: in std_logic;	--VGA端的时钟，25MHz
			pixel_x, pixel_y: in natural;	--查询像素的坐标
			rgb: out TColor;					--输出像素颜色
			
			ax, ay: in integer;
			ax1, ay1, az1: in integer;
			gx1, gy1, gz1: in integer
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
			
			sx, sy: buffer natural;
			show_radius: buffer natural
		);
	end component;
	
	component StatusController is
	port (
		clk: in std_logic;			--游戏端时钟，60Hz
		rst, pause_in: in std_logic;	--复位，暂停按钮
		result: in TResult;			--回合结束状态
		status: buffer TStatus;		--游戏状态
		phy_rst, phy_pause: out std_logic --控制物理引擎的复位、暂停（当前是直接与按钮关联，未来可能有变）
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
	
	component vga_controller IS
	  GENERIC(
		 h_pixels :  INTEGER   := 1920;  --horiztonal display width in pixels
		 h_fp     :  INTEGER   := 128;   --horiztonal front porch width in pixels
		 h_pulse  :  INTEGER   := 208;   --horiztonal sync pulse width in pixels
		 h_bp     :  INTEGER   := 336;   --horiztonal back porch width in pixels
		 h_pol    :  STD_LOGIC := '0';   --horizontal sync pulse polarity (1 = positive, 0 = negative)
		 v_pixels :  INTEGER   := 1200;  --vertical display width in rows
		 v_fp     :  INTEGER   := 1;     --vertical front porch width in rows
		 v_pulse  :  INTEGER   := 3;     --vertical sync pulse width in rows
		 v_bp     :  INTEGER   := 38;    --vertical back porch width in rows
		 v_pol    :  STD_LOGIC := '1');  --vertical sync pulse polarity (1 = positive, 0 = negative)
	  PORT(
		 pixel_clk :  IN   STD_LOGIC;  --pixel clock at frequency of VGA mode being used
		 reset_n   :  IN   STD_LOGIC;  --active low asycnchronous reset
		 color_in  :  IN   TColor;
		 color_out :  OUT  TColor;
		 h_sync    :  OUT  STD_LOGIC;  --horiztonal sync pulse
		 v_sync    :  OUT  STD_LOGIC;  --vertical sync pulse
		 column    :  OUT  INTEGER;    --horizontal pixel coordinate
		 row       :  OUT  INTEGER    --vertical pixel coordinate
	  );
	END component;
	
	component altpll0 IS
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	END component;
	
	signal gyro_ax, gyro_ay, gyro_ax1, gyro_ay1, kb_ax, kb_ay, kb_ax1, kb_ay1: integer;
	signal ax, ay, px, py, score: integer;
	signal ax1, ay1, px1, py1, score1: integer;
	signal start_x, start_y: MapXY;
	signal w, a, s, d, w1, a1, s1, d1: std_logic;
	signal vga_vs_temp: std_logic;
	signal color, color_out: TColor;
	signal clk25, clk60, clk_pixel: std_logic;
	signal vga_x, vga_y: integer;
	signal result, result1: TResult;
	
	signal status: TStatus := Init;
	signal phy_rst, phy_pause: std_logic;
	signal ready: std_logic;
	
	signal physics_sx, physics_sy: MapXY;
	signal physics_pos_type: TPos;
	signal renderer_sx, renderer_sy: MapXY;
	signal renderer_pos_type: TPos;
	
	constant unit_size: natural := 16000;
	constant ball_radius: natural := 6000;
	constant scale: natural := 1000;
	
	-- for debug:
	signal result_num: std_logic_vector(3 downto 0); 
	signal px_vec, py_vec: std_logic_vector(11 downto 0);
	signal sx, sy: natural;
	signal ax0, ay0, az0, gx0, gy0, gz0: integer;
	signal show_radius: natural;
begin
	clk60 <= vga_vs_temp;
	vga_vs <= vga_vs_temp;
	gyro1_vcc <= '1';

	--ax <= kb_ax; ay <= kb_ay;
	ax <= gyro_ax; ay <= gyro_ay;
	ax1 <= gyro_ax1; ay1 <= gyro_ay1;
	
	gyr0: Gyro port map (clk100, rst and gyro_rst, i2c_data, i2c_clk, gyro_ax, gyro_ay,
								ax0, ay0, az0, gx0, gy0, gz0);
	gyr1: Gyro port map (clk100, rst and gyro_rst, i2c_data1, i2c_clk1, gyro_ax1, gyro_ay1);
	ktw: KeyboardToWASD port map (keyboard_data, keyboard_clk, clk100, not rst, w, a, s, d, w1, a1, s1, d1);
	wta0: WASDToAcc port map (w, a, s, d, kb_ax, kb_ay);
	wta1: WASDToAcc port map (w1, a1, s1, d1, kb_ax1, kb_ay1);
	reader: SceneReader port map (clk100, rst, physics_sx, physics_sy, renderer_sx, renderer_sy,
					physics_pos_type, renderer_pos_type, start_x, start_y, ready);
	phy: Physics port map (clk60, clk100, phy_rst, phy_pause, 
									physics_sx, physics_sy, physics_pos_type, start_x, start_y, ready,
									unit_size, ball_radius, ax, ay, px, py, score, result, sx, sy, show_radius);
	ctrl: StatusController port map (clk60, rst, pause, result, status, phy_rst, phy_pause);
	--vga: vga640480 port map (rst, clk100, vga_x, vga_y, color, clk25, vga_hs, vga_vs_temp, vga_r, vga_g, vga_b);
	pll: altpll0 port map (clk100, clk_pixel);
	vga_r <= color_out(8 downto 6);
	vga_g <= color_out(5 downto 3);
	vga_b <= color_out(2 downto 0);
	vga1: vga_controller 
		generic map (1440,80,152,232,'0',900,1,3,28,'1')
		--generic map (640,16,96,48,'0',480,10,2,33,'0')
		port map (clk_pixel, rst, color, color_out, vga_hs, vga_vs_temp, vga_x, vga_y);
	ren: Renderer port map (
		clk => clk60,
		sx => renderer_sx,
		sy => renderer_sy,
		pos_type => renderer_pos_type,
		unit_size => unit_size,
		ball_radius => show_radius,
		scale => scale,
		px => px, py => py,
		px1 => px1, py1 => py1,
		score => score,
		status => status,
		result => result,
		vga_clk => clk_pixel,
		pixel_x => vga_x,
		pixel_y => vga_y,
		rgb => color,
		ax => ax, ay => ay,
		ax1 => ax0, ay1 => ay0, az1 => az0, gx1 => gx0, gy1 => gy0, gz1 => gz0
	);
	
	result_num <= "0000" when result = Normal else
					"0001" when result = Win else
					"0010" when result = Die else
					"1111";
	
	px_vec <= std_logic_vector( to_unsigned(px, 12) );
	py_vec <= std_logic_vector( to_unsigned(py, 12) );
	--debug_display(6) <= DisplayNumber(start_x);
	--debug_display(5) <= DisplayNumber(start_y);

	debug_display(3) <= DisplayNumber( ax0 );
	debug_display(2) <= DisplayNumber( ay0 );
	
	debug_display(0) <= DisplayNumber(ay);
	debug_display(1) <= DisplayNumber(ax);
	--debug_display(0) <= DisplayNumber(scancode(3 downto 0));
	--debug_display(1) <= DisplayNumber(scancode(7 downto 4));
end arch ; -- arch