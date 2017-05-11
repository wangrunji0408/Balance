library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package Functions is
	-- FGPA平台显示译码器顺序
	function DisplayNumber (number: std_logic_vector(3 downto 0))
		return std_logic_vector;
	type DisplayNums is array (7 downto 0) of std_logic_vector(6 downto 0);
	type TPos is (None, Road);						--地图每格类型：空，正常道路
	type TMap is array (64 * 64 downto 0) of TPos;	--游戏地图：高6位x，低6位y
	type TResult is (Normal, Die);					--回合结束状态：正常，死亡
	type TStatus is (Init, Run, Pause, Die);		--游戏状态：等待开始，进行中，暂停，结束
end package;

package body Functions is
	function DisplayNumber (number: std_logic_vector(3 downto 0))
		return std_logic_vector is
	begin
		case number is
			when "0000" => return "0111111"; --0;
			when "0001" => return "0000011"; --1;
			when "0010" => return "1011101"; --2;
			when "0011" => return "1001111"; --3;
			when "0100" => return "1100011"; --4;
			when "0101" => return "1101110"; --5;
			when "0110" => return "1111110"; --6;
			when "0111" => return "0001011"; --7;
			when "1000" => return "1111111"; --8;
			when "1001" => return "1101111"; --9;
			when "1010" => return "1111011"; --A;
			when "1011" => return "1110110"; --B;
			when "1100" => return "0111100"; --C;
			when "1101" => return "1010111"; --D;
			when "1110" => return "1111100"; --E;
			when "1111" => return "1111000"; --F;
			when others => return "0000000";
		end case;
	end function;
end package body;