library ieee;
use ieee.std_logic_1164.all;

entity Keyboard_tb is
end entity;

architecture arch of Keyboard_tb is
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

	signal w, a, s, d, up, left, down, right: std_logic;
	signal ps2_data, ps2_clk, clk, rst: std_logic;
	signal ax, ay: integer;

	procedure send_code (
		code: in std_logic_vector(7 downto 0);
		signal data, clk: out std_logic
	) is
		variable odd: std_logic;
		variable fullcode: std_logic_vector(10 downto 0);
	begin
		odd := code(0) xor code(1) xor code(2) xor code(3) 
			xor code(4) xor code(5) xor code(6) xor code(7) ;
		fullcode := "1" & (not odd) & code & "0";
		send : for i in 0 to 10 loop
			data <= fullcode(i);
			clk <= '1'; wait for 20 us;
			clk <= '0'; wait for 40 us;
			clk <= '1'; wait for 20 us;
		end loop ; -- send
	end procedure;

	constant c_break: std_logic_vector(7 downto 0) := x"F0";
	constant c_E0: std_logic_vector(7 downto 0) := x"E0";
	constant c_w: std_logic_vector(7 downto 0) := x"1D";
	constant c_a: std_logic_vector(7 downto 0) := x"1C";
	constant c_s: std_logic_vector(7 downto 0) := x"1B";
	constant c_d: std_logic_vector(7 downto 0) := x"23";
	constant c_up: std_logic_vector(7 downto 0) := x"75";
	constant c_left: std_logic_vector(7 downto 0) := x"6B";
	constant c_down: std_logic_vector(7 downto 0) := x"72";
	constant c_right: std_logic_vector(7 downto 0) := x"74";

begin
	ktw: KeyboardToWASD port map (ps2_data, ps2_clk, clk, rst, w, a, s, d, up, left, down, right);
	wta: WASDToAcc port map (w, a, s, d, ax, ay);

	process
	begin
		clk <= '0';
		genclk : for i in 0 to 20000 loop
			clk <= not clk; wait for 1 us;
		end loop ; -- genclk
		wait;
	end process ;

	process
	begin
		ps2_clk <= '1';
		rst <= '0';

		--按下Up
		send_code(x"E0", ps2_data, ps2_clk);
		send_code(x"75", ps2_data, ps2_clk);
		assert up = '1' and left = '0' and down = '0' and right = '0' severity error;
		--按下Left
		send_code(x"E0", ps2_data, ps2_clk);
		send_code(x"6B", ps2_data, ps2_clk);
		assert up = '1' and left = '1' and down = '0' and right = '0' severity error;
		--松开Up
		send_code(x"E0", ps2_data, ps2_clk);
		send_code(x"F0", ps2_data, ps2_clk);
		send_code(x"75", ps2_data, ps2_clk);
		assert up = '0' and left = '1' and down = '0' and right = '0' severity error;
		--松开Left
		send_code(x"E0", ps2_data, ps2_clk);
		send_code(x"F0", ps2_data, ps2_clk);
		send_code(x"6B", ps2_data, ps2_clk);
		assert up = '0' and left = '0' and down = '0' and right = '0' severity error;

		--按下w
		send_code(c_w, ps2_data, ps2_clk);
		assert w = '1' and a = '0' and s = '0' and d = '0' severity error;
		assert ax = 0 and ay = -1 severity error;
		--按下a
		send_code(c_a, ps2_data, ps2_clk);
		assert w = '1' and a = '1' and s = '0' and d = '0' severity error;
		assert ax = -1 and ay = -1 severity error;
		--松开w
		send_code(c_break, ps2_data, ps2_clk);
		send_code(c_w, ps2_data, ps2_clk);
		assert w = '0' and a = '1' and s = '0' and d = '0' severity error;
		assert ax = -1 and ay = 0 severity error;
		--松开a
		send_code(c_break, ps2_data, ps2_clk);
		send_code(c_a, ps2_data, ps2_clk);
		assert w = '0' and a = '0' and s = '0' and d = '0' severity error;
		assert ax = 0 and ay = 0 severity error;
		
		wait;
	end process ;

end arch ; -- arch