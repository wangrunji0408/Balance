library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Mouse is
	port (
		ps2_data, ps2_clk: in std_logic;
		clk, rst: in std_logic;
		ax, ay: out integer
	);
end entity;