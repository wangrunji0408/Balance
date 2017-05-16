library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.Functions.all;

entity StatusController is
	port (
		clk: in std_logic;			--游戏端时钟，60Hz
		rst, pause: in std_logic;	--复位，暂停按钮
		result: in TResult;			--回合结束状态
		status: buffer TStatus;		--游戏状态
		phy_rst, phy_pause: out std_logic --控制物理引擎的复位、暂停（当前是直接与按钮关联，未来可能有变）
	);
end entity;