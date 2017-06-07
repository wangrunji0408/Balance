library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.Functions.all;

entity StatusController is
	port (
		clk: in std_logic;			--游戏端时钟，60Hz
		rst, pause_in: in std_logic;	--复位，暂停按钮
		result, result1: in TResult;			--回合结束状态
		status: buffer TStatus;		--游戏状态
		phy_rst, phy_pause: out std_logic --控制物理引擎的复位、暂停（当前是直接与按钮关联，未来可能有变）
	);
end entity;

architecture arch of StatusController is
begin
	phy_rst <= rst;
	phy_pause <= '0' when pause_in = '0' or status = Init or status = Gameover else '1';
	process( clk, rst )
	begin
		if rst = '0' then
			status <= Init;
		elsif rising_edge(clk) then
			if status = Init then
				if pause_in = '0' then
					status <= Run;
				else
					status <= Init;
				end if;
			elsif pause_in = '0' then
				status <= Pause;
			elsif result = Die or result = Win or result1 = Die or result1 = Win then
				status <= Gameover;
			else
				status <= Run;
			end if;
		end if;
	end process ;
end arch ; -- arch