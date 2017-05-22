library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package Functions is
	-- FGPA平台显示译码器顺序
	function DisplayNumber (number: unsigned(3 downto 0)) return std_logic_vector;
	function DisplayNumber (number: integer) return std_logic_vector;
	subtype DisplayCode is std_logic_vector(6 downto 0);
	type DisplayNums is array (7 downto 0) of DisplayCode;
	type TPos is (None, Road, Terminal, Wall, Start);		--地图每格类型：空，正常道路
	type TMap is array (16*16-1 downto 0) of TPos;	--游戏地图：高6位x，低6位y
	type TResult is (Normal, Die, Win);					--回合结束状态：正常，死亡，赢
	type TStatus is (Init, Run, Pause, Gameover);		--游戏状态：等待开始，进行中，暂停，结束
	subtype TColor is std_logic_vector(8 downto 0); 	--颜色：[R2R1R0 G2G1G0 B2B1B0]
	function ToPosType (x: std_logic_vector(3 downto 0)) return TPos;
	function PosTypeToNum (t: TPos) return std_logic_vector;
	function ToColor (t: TPos) return TColor;
end package;

package body Functions is

	function ToPosType (x: std_logic_vector(3 downto 0))
		return TPos is
	begin
		case( x ) is
			when "0000" => return None;
			when "0001" => return Road;
			when "0010" => return Terminal;
			when "0011" => return Wall;
			when "0100" => return Start;
			when others => return None;
		end case ;
	end function;

	function PosTypeToNum (t: TPos)
		return std_logic_vector is
	begin
		case( t ) is
			when None => return "0000";
			when Road => return "0001";
			when Terminal => return "0010";
			when Wall => return "0011";
			when Start => return "0100";
			when others => return "1111";
		end case ;
	end function;
	
	function ToColor (t: TPos)
		return TColor is
	begin
		case( t ) is
			when None => return "000000000";
			when Road => return "010010010";
			when Terminal => return "111000000";
			when Wall => return "000111000";
			when Start => return "010010010";
			when others => return "000000111";
		end case ;
	end function;

	function DisplayNumber (number: unsigned(3 downto 0))
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
	
	function DisplayNumber (number: integer)
		return std_logic_vector is
	begin
		return DisplayNumber(to_unsigned(number, 4));
	end function;
end package body;