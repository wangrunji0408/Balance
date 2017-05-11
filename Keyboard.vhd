library ieee;
use ieee.std_logic_1164.all;

entity Keyboard is
	port (
		ps2_data, ps2_clk: in std_logic;
		clk, rst: in std_logic;
		ax, ay: out integer
	);
end entity;

library ieee;
use ieee.std_logic_1164.all;

entity KeyboardToWASD is
	port (
		ps2_data, ps2_clk: in std_logic;
		clk, rst: in std_logic;
		w, a, s, d: out std_logic
	);
end entity;

library ieee;
use ieee.std_logic_1164.all;

entity WASDToAcc is
	port (
		w, a, s, d: in std_logic;
		ax, ay: out integer
	);
end entity;

--------------------------------------------------

architecture arch of Keyboard is
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
	signal w, a, s, d: std_logic;
begin
	ktw: KeyboardToWASD port map (ps2_data, ps2_clk, clk, rst, w, a, s, d);
	wta: WASDToAcc port map (w, a, s, d, ax, ay);
end arch ; -- arch


architecture arch of KeyboardToWASD is
	component KeyboardScancode is
	port (
		datain, clkin : in std_logic ; -- PS2 clk and data
		fclk, rst : in std_logic ;  -- filter clock
		scancode : out std_logic_vector(7 downto 0) -- scan code signal output
		);
	end component ;
	signal scancode: std_logic_vector(7 downto 0);
	signal isBreak: boolean := false;
	constant c_break: std_logic_vector(7 downto 0) := "11110000";
	constant c_w: std_logic_vector(7 downto 0) := "11110000";
	constant c_a: std_logic_vector(7 downto 0) := "11110000";
	constant c_s: std_logic_vector(7 downto 0) := "11110000";
	constant c_d: std_logic_vector(7 downto 0) := "11110000";
begin
	ks: KeyboardScancode port map (ps2_data, ps2_clk, clk, rst, scancode);
	process( scancode )
	begin
		case( scancode ) is
			when c_w => if isBreak then w <= '1'; else w <= '0'; end if;
			when c_a => if isBreak then a <= '1'; else a <= '0'; end if;
			when c_s => if isBreak then s <= '1'; else s <= '0'; end if;
			when c_d => if isBreak then d <= '1'; else d <= '0'; end if;
			when others => null;
		end case ;
		isBreak <= scancode = c_break;
	end process ;
end arch ; -- arch


architecture arch of WASDToAcc is
begin
	ax <= 1 when s = '1' else -1 when w = '1';
	ay <= 1 when d = '1' else -1 when a = '1';
end arch ; -- arch