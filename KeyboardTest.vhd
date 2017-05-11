library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.Functions.all;

entity KeyboardTest is
port(
datain,clkin,fclk,rst_in: in std_logic;
seg0,seg1:out std_logic_vector(6 downto 0)
);
end entity;

architecture behave of KeyboardTest is
	component KeyboardScancode is
	port (
		datain, clkin : in std_logic ; -- PS2 clk and data
		fclk, rst : in std_logic ;  -- filter clock
	--	fok : out std_logic ;  -- data output enable signal
		scancode : out std_logic_vector(7 downto 0) -- scan code signal output
		) ;
	end component ;

signal scancode : std_logic_vector(7 downto 0);
signal rst : std_logic;
signal clk_f: std_logic;
begin
rst<=not rst_in;

u0: KeyboardScancode port map(datain,clkin,fclk,rst,scancode);
seg0 <= DisplayNumber(scancode(3 downto 0));
seg1 <= DisplayNumber(scancode(7 downto 4));

end behave;

