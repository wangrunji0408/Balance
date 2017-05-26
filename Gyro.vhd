library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Gyro is
	port (
		-- 陀螺仪输入信号
		clk100, rst: in std_logic;
		i2c_data, i2c_clk: inout std_logic;
		ax_out, ay_out: out integer
	);
end entity;

architecture arch of Gyro is
	component i2c_master IS
	  GENERIC(
		 input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
		 bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
	  PORT(
		 clk       : IN     STD_LOGIC;                    --system clock
		 reset_n   : IN     STD_LOGIC;                    --active low reset
		 ena       : IN     STD_LOGIC;                    --latch in command
		 addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
		 rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
		 data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
		 busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
		 data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
		 ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
		 sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
		 scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
	END component;

	subtype TAddress is STD_LOGIC_VECTOR(7 DOWNTO 0);
	subtype TData is STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal address: TAddress;
	signal data_read, data_write: TData;
	signal enable, rw, ack_error, busy: std_logic;
	signal last_busy: std_logic;

	signal ax, ay, az: std_logic_vector(15 downto 0);
	signal gx, gy, gz: std_logic_vector(15 downto 0);
	
	constant SMPLRT_DIV		: TAddress := x"19";	-- 陀螺仪采样率，典型值：0x07(125Hz)
	constant CONFIG			: TAddress := x"1A";	-- 低通滤波频率，典型值：0x06(5Hz)
	constant GYRO_CONFIG	: TAddress := x"1B";	-- 陀螺仪自检及测量范围，典型值：0x18(不自检，2000deg/s)
	constant ACCEL_CONFIG	: TAddress := x"1C";	-- 加速计自检、测量范围及高通滤波频率，典型值：0x01(不自检，2G，5Hz)
	constant ACCEL_XOUT_H	: TAddress := x"3B";
	constant ACCEL_XOUT_L	: TAddress := x"3C";
	constant ACCEL_YOUT_H	: TAddress := x"3D";
	constant ACCEL_YOUT_L	: TAddress := x"3E";
	constant ACCEL_ZOUT_H	: TAddress := x"3F";
	constant ACCEL_ZOUT_L	: TAddress := x"40";
	constant TEMP_OUT_H		: TAddress := x"41";
	constant TEMP_OUT_L		: TAddress := x"42";
	constant GYRO_XOUT_H	: TAddress := x"43";
	constant GYRO_XOUT_L	: TAddress := x"44";	
	constant GYRO_YOUT_H	: TAddress := x"45";
	constant GYRO_YOUT_L	: TAddress := x"46";
	constant GYRO_ZOUT_H	: TAddress := x"47";
	constant GYRO_ZOUT_L	: TAddress := x"48";
	constant PWR_MGMT_1		: TAddress := x"6B";	-- 电源管理，典型值：0x00(正常启用)
	constant WHO_AM_I		: TAddress := x"75";	-- IIC地址寄存器(默认数值0x68，只读)
	constant SlaveAddress	: TAddress := x"D0";	-- IIC写入时的地址字节数据，+1为读取

begin
	i2c: i2c_master
		generic map (100_000_000, 400_000)
		port map (clk100, rst, enable, address(6 downto 0), rw, data_write, busy, data_read, ack_error, i2c_data, i2c_clk);
	
	process (clk100)
		variable busy_cnt : natural := 0;
	begin
		if rising_edge(clk100) then
			last_busy <= busy;
			if last_busy = '0' and busy = '1' then
				busy_cnt := busy_cnt + 1;
			end if;
			
			if busy = '0' then 
			case busy_cnt is
				-- Init MPU6050
				when 0 =>
					enable <= '1';
					rw <= '0';
					address <= PWR_MGMT_1;
					data_write <= x"00";
				when 1 =>
					address <= SMPLRT_DIV;
					data_write <= x"07";
				when 2 =>
					address <= CONFIG;
					data_write <= x"06";
				when 3 =>
					address <= GYRO_CONFIG;
					data_write <= x"18";
				when 4 => 
					address <= ACCEL_CONFIG;
					data_write <= x"01";
				-- Read
				when 5 => 
					rw <= '1';
					address <= ACCEL_XOUT_H;
				when 6 => 
					ax(15 downto 8) <= data_read;
					address <= ACCEL_XOUT_L;
				when 7 => 
					ax(7 downto 0) <= data_read;
					address <= ACCEL_YOUT_H;
				when 8 => 
					ay(15 downto 8) <= data_read;
					address <= ACCEL_YOUT_L;
				when 9 => 
					ay(7 downto 0) <= data_read;
					address <= ACCEL_ZOUT_H;
				when 10 => 
					az(15 downto 8) <= data_read;
					address <= ACCEL_ZOUT_L;
				when 11 => 
					az(7 downto 0) <= data_read;
					address <= GYRO_XOUT_H;
				when 12 => 
					gx(15 downto 8) <= data_read;
					address <= GYRO_XOUT_L;
				when 13 => 
					gx(7 downto 0) <= data_read;
					address <= GYRO_YOUT_H;
				when 14 => 
					gy(15 downto 8) <= data_read;
					address <= GYRO_YOUT_L;
				when 15 => 
					gy(7 downto 0) <= data_read;
					address <= GYRO_ZOUT_H;
				when 16 => 
					gz(15 downto 8) <= data_read;
					address <= GYRO_ZOUT_L;
				when 17 => 
					gz(7 downto 0) <= data_read;
					busy_cnt := 5;
				when others => null;
			end case;
			end if;
			
		end if;
	end process;
	
end architecture;