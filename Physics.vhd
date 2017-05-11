library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.Functions.all;

entity Physics is
	port (
		clk, rst, pause: in std_logic;	--游戏端时钟60Hz，复位（恢复初态），暂停（0为暂停，1为正常）
		scene: in TMap;			--地图信息
		unit_size: in natural; 	--每格的边长
		ball_radius: in natural;--球的半径
		ax, ay: in integer; 	--加速度
		
		px, py: buffer integer; 	--位置
		add_score: out integer; 	--加分
		result: buffer TResult		--结果
	);
end entity;