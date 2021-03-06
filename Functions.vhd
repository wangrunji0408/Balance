library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package Functions is
	-- FGPA平台显示译码器顺序
	function DisplayNumber (number: unsigned(3 downto 0)) return std_logic_vector;
	function DisplayNumber (number: integer) return std_logic_vector;
	subtype DisplayCode is std_logic_vector(6 downto 0);
	subtype MapXY is natural range 0 to 63;
	type DisplayNums is array (7 downto 0) of DisplayCode;
	type TPos is (None, Ice, Pin, Land, GlassWall, WoodWall, IronWall, StartPoint, EndPoint, Hole,
					SpringU, SpringD, SpringL, SpringR, AccU, AccD, AccL, AccR,
					ToGlass, ToWood, ToIron, Gate1, Gate2, GlassBall, WoodBall, IronBall);
	subtype TBall is TPos range GlassBall to IronBall;
	type TResult is (Normal, Die, Win);					--回合结束状态：正常，死亡，赢
	type TStatus is (Init, Run, Pause, Gameover);		--游戏状态：等待开始，进行中，暂停，结束
	subtype TColor is std_logic_vector(8 downto 0); 	--颜色：[R2R1R0 G2G1G0 B2B1B0]
	function ToPosType (x: std_logic_vector(5 downto 0)) return TPos;
	function ToColor (t: TPos) return TColor;
	function ToBase64Id (c: character) return natural;
	function isWall (t: TPos) return boolean;
	function toString (x: integer range -100000 to 100000) return string;
	function toChar (x: integer range 0 to 9) return character;
	function in_circle (dx, dy: integer; r: natural) return boolean;
	function limit (x, min, max: integer) return integer;
	function max (a, b: integer) return integer;
end package;

package body Functions is
	function max (a, b: integer) return integer is
	begin
		if a < b then return b; else return a; end if;
	end function;
	function limit (x, min, max: integer) return integer is
	begin
		if x > max then return max;
		elsif x < min then return min;
		else return x;
		end if;
	end function;

	function in_circle (dx, dy: integer; r: natural) return boolean is
	begin
		return abs(dx) <= r and abs(dy) <= r and dx * dx + dy * dy <= r * r;
	end function;

	function toChar (x: integer range 0 to 9) return character is
	begin
		return character'val(character'pos('0') + x);
	end function;

	function toString (x: integer range -100000 to 100000) return string is
		variable s: string(1 to 6);
		constant minus: boolean := x < 0;
		variable absx: natural range 0 to 100000;
	begin
		if minus then absx := -x; else absx := x; end if;
		s(6) := toChar(absx mod 10);
		s(5) := toChar(absx / 10 mod 10);
		s(4) := toChar(absx / 100 mod 10);
		s(3) := toChar(absx / 1000 mod 10);
		s(2) := toChar(absx / 10000 mod 10);
		if minus then s(1) := '-'; else s(1) := ' '; end if;
		return s;
	end function;

	function isWall (t: TPos) return boolean is
	begin
		return t = GlassWall or t = WoodWall or t = IronWall;
	end function;

	function ToBase64Id (c: character) return natural is
		constant ascii: natural := CHARACTER'POS(c);
	begin
		if ascii >= CHARACTER'POS('A') and ascii <= CHARACTER'POS('Z') then 
			return 0 + ascii - CHARACTER'POS('A');
		elsif ascii >= CHARACTER'POS('a') and ascii <= CHARACTER'POS('z') then 
			return 26 + ascii - CHARACTER'POS('z');
		elsif ascii >= CHARACTER'POS('0') and ascii <= CHARACTER'POS('9') then 
			return 52 + ascii - CHARACTER'POS('0');
		else
			return 63;
		end if;
	end function;

	function ToPosType (x: std_logic_vector(5 downto 0))
		return TPos is
	begin
		return TPos'val(to_integer(unsigned(x)));
		-- case( x ) is
		-- 	when 0 => return None;
		-- 	when 1 => return Ice;
		-- 	when 6 => return IronWall;
		-- 	when 7 => return StartPoint;
		-- 	when 8 => return EndPoint;
		-- 	when others => return None;
		-- end case ;
	end function;
	
	function ToColor (t: TPos)
		return TColor is
	begin
		case( t ) is
			when None => return o"000";
			when Ice => return o"222";
			when EndPoint => return o"700";
			when IronWall => return o"070";
			when StartPoint => return o"222";
			when others => return o"007";
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