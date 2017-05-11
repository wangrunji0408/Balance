library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
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
			clk100, rst: in std_logic;
			w, a, s, d: out std_logic
		);
	end component;
	component WASDToAcc is
		port (
			w, a, s, d: in std_logic;
			ax, ay: out integer
		);
	end component;
	signal ax, ay, vx, vy, x, y: integer;
	signal w, a, s, d: std_logic;
begin
	ktw: KeyboardToWASD port map (keyboard_data, keyboard_clk, clk100, rst, w, a, s, d);
	wta: WASDToAcc port map (w, a, s, d, ax, ay);
end arch ; -- arch