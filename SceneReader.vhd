library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.Functions.all;

entity SceneReader is
	port (
		scene: out TMap
	);
end entity;