library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Gyro is
	port (
		-- 陀螺仪输入信号
		ax, ay: out integer
	);
end entity;