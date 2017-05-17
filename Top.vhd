library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
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
	component KeyboardScancode is
	port (
		datain, clkin : in std_logic ; -- PS2 clk and data
		fclk, rst : in std_logic ;  -- filter clock
	--	fok : out std_logic ;  -- data output enable signal
		scancode : out std_logic_vector(7 downto 0) -- scan code signal output
		) ;
	end component ;
	component KeyboardToWASD is
		port (
			ps2_data, ps2_clk: in std_logic;
			clk, rst: in std_logic;
			w, a, s, d: out std_logic
		);
	end component;
	component WASDToAcc is
		port (
			w, a, s, d: in std_logic;
			ax, ay: out integer
		);
	end component;
	component SceneReader is
	port (
		clk100, rst: in std_logic;
		available: out std_logic;
		scene: out TMap;
		start_x, start_y: out natural
	);
	end component;
	component vga640480 is
	 port(
			reset       :         in  STD_LOGIC;
			clk100      :         in  STD_LOGIC; --100M时钟输入
			x, y		:		  out std_logic_vector(9 downto 0); --输出当前要绘制的像素位置
			r_in, g_in, b_in :    in std_logic_vector(2 downto 0); --输入给定像素位置的颜色
			clk25       :		  out std_logic; --输出25MHz工作时钟
			hs,vs       :         out STD_LOGIC; --行同步、场同步信号
			r,g,b       :         out STD_LOGIC_vector(2 downto 0) --输出的颜色信号
	  );
	end component;
	component Renderer is
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
		rgb: out TColor											--输出像素颜色
	);
	end component;
	
	component Physics is
	port (
		clk, rst, pause: in std_logic;	--游戏端时�?0Hz，复位（恢复初态），暂停（0为暂停，1为正常）
		scene: in TMap;			--地图信息
		start_x, start_y: in natural;
		unit_size: in natural; 	--每格的边�?
		ball_radius: in natural;--球的半径
		ax, ay: in integer; 	--加速度
		
		px, py: buffer integer; 	--位置
		add_score: out integer; 	--加分
		result: buffer TResult;		--结果
		
		sx, sy: out natural;
		nowt: out TPos 
	);
	end component;
	
	signal ax, ay, vx, vy, px, py, add_score: integer;
	signal start_x, start_y: natural;
	signal w, a, s, d: std_logic;
	signal vga_vs_temp: std_logic;
	signal color: TColor;
	signal clk25, clk60: std_logic;
	signal vga_x, vga_y: std_logic_vector(9 downto 0);
	signal scene: TMap;
	signal scene_available: std_logic := '0';
	signal result: TResult;
	constant unit_size: natural := 50;
	constant ball_radius: natural := 20;
	constant scale: natural := 5;
	
	-- for debug:
	signal scancode : std_logic_vector(7 downto 0);
	signal result_num: std_logic_vector(3 downto 0); 
	signal px_vec, py_vec: std_logic_vector(11 downto 0);
	signal nowt: TPos;
	signal sx, sy: natural;
begin
	clk60 <= vga_vs_temp;
	vga_vs <= vga_vs_temp;
	
	u0: KeyboardScancode port map(keyboard_data, keyboard_clk, clk100, not rst, scancode);
	ktw: KeyboardToWASD port map (keyboard_data, keyboard_clk, clk100, not rst, w, a, s, d);
	wta: WASDToAcc port map (w, a, s, d, ax, ay);
	reader: SceneReader port map (clk100, rst, scene_available, scene, start_x, start_y);
	phy: Physics port map (clk60, rst, pause, scene, start_x, start_y, unit_size, ball_radius, ax, ay, px, py, add_score, result, sx, sy, nowt);
	vga: vga640480 port map (
		reset => rst,
		clk100 => clk100,
		x => vga_x,
		y => vga_y,
		r_in => color(8 downto 6),
		g_in => color(5 downto 3),
		b_in => color(2 downto 0),
		clk25 => clk25,
		hs => vga_hs,
		vs => vga_vs_temp,
		r => vga_r,
		g => vga_g,
		b => vga_b
	);
	ren: Renderer port map (
		clk => '0',
		scene => scene,
		unit_size => unit_size,
		ball_radius => ball_radius,
		scale => scale,
		px => px, py => py,
		score => 0,
		status => Init,
		
		vga_clk => clk25,
		pixel_x => vga_x, pixel_y => vga_y,
		rgb => color
	);
	
	result_num <= "0000" when result = Normal else
					"0001" when result = Win else
					"0010" when result = Die else
					"1111";
	
	px_vec <= std_logic_vector( to_unsigned(px, 12) );
	py_vec <= std_logic_vector( to_unsigned(py, 12) );
	debug_display(7) <= DisplayNumber( PosTypeToNum(nowt) );
	debug_display(6) <= DisplayNumber( std_logic_vector( to_unsigned(sx, 4) ) );
	debug_display(5) <= DisplayNumber( std_logic_vector( to_unsigned(sy, 4) ) );

	--debug_display(3) <= DisplayNumber( "000" & rst );
	--debug_display(2) <= DisplayNumber( "000" & pause );
	
	debug_display(0) <= DisplayNumber( std_logic_vector( to_unsigned(ay, 4) ) );
	debug_display(1) <= DisplayNumber( std_logic_vector( to_unsigned(ax, 4) ) );
	--debug_display(0) <= DisplayNumber(scancode(3 downto 0));
	--debug_display(1) <= DisplayNumber(scancode(7 downto 4));
end arch ; -- arch