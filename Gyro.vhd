library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Functions.all;

entity Gyro is
	port (
		clk100, rst: in std_logic;
		i2c_data, i2c_clk: inout std_logic;
		ax_out, ay_out: out integer;
		ax1, ay1, az1: out integer;
		gx1, gy1, gz1: out integer
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

	subtype TData is STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal data_read, data_write: TData;
	signal enable, rw, ack_error, busy: std_logic;
	signal last_busy: std_logic;

	signal ax, ay, az: std_logic_vector(15 downto 0);
	signal gx, gy, gz: std_logic_vector(15 downto 0);
	
	constant SMPLRT_DIV		: TData := x"19";	-- 陀螺仪采样率，典型值：0x07(125Hz)
	constant CONFIG			: TData := x"1A";	-- 低通滤波频率，典型值：0x06(5Hz)
	constant GYRO_CONFIG	: TData := x"1B";	-- 陀螺仪自检及测量范围，典型值：0x18(不自检，2000deg/s)
	constant ACCEL_CONFIG	: TData := x"1C";	-- 加速计自检、测量范围及高通滤波频率，典型值：0x01(不自检，2G，5Hz)
	constant ACCEL_XOUT_H	: TData := x"3B";
	constant ACCEL_XOUT_L	: TData := x"3C";
	constant ACCEL_YOUT_H	: TData := x"3D";
	constant ACCEL_YOUT_L	: TData := x"3E";
	constant ACCEL_ZOUT_H	: TData := x"3F";
	constant ACCEL_ZOUT_L	: TData := x"40";
	constant TEMP_OUT_H		: TData := x"41";
	constant TEMP_OUT_L		: TData := x"42";
	constant GYRO_XOUT_H	: TData := x"43";
	constant GYRO_XOUT_L	: TData := x"44";	
	constant GYRO_YOUT_H	: TData := x"45";
	constant GYRO_YOUT_L	: TData := x"46";
	constant GYRO_ZOUT_H	: TData := x"47";
	constant GYRO_ZOUT_L	: TData := x"48";
	constant PWR_MGMT_1		: TData := x"6B";	-- 电源管理，典型值：0x00(正常启用)
	constant WHO_AM_I		: TData := x"75";	-- IIC地址寄存器(默认数值0x68，只读)
	constant SlaveAddress	: TData := x"D0";	-- IIC写入时的地址字节数据，+1为读取

begin
	i2c: i2c_master
		generic map (100_000_000, 400_000)
		port map (clk100, rst, enable, SlaveAddress(7 downto 1), rw, data_write, busy, data_read, ack_error, i2c_data, i2c_clk);
	
	ax1 <= to_integer(signed(ax));
	ay1 <= to_integer(signed(ay));
	az1 <= to_integer(signed(az));
	gx1 <= to_integer(signed(gz));
	gy1 <= to_integer(signed(gy));
	gz1 <= to_integer(signed(gz));
	ax_out <= to_integer(SHIFT_RIGHT(signed(ay),10));
	ay_out <= to_integer(SHIFT_RIGHT(signed(ax),10));
	
	process (clk100)
		variable busy_event_cnt : natural := 0;
		variable silent_cnt: natural range 0 to 100_000 := 0;
	begin
		if rst = '0' or silent_cnt = 100_000 then
			busy_event_cnt := 0;
			enable <= '0';
			rw <= '0';
			data_write <= x"00";
			silent_cnt := 0;
		elsif rising_edge(clk100) then
			last_busy <= busy;
			if (last_busy xor busy) = '1' then
				busy_event_cnt := busy_event_cnt + 1;
				silent_cnt := 0;
			else
				silent_cnt := silent_cnt + 1;
			end if;
			
			case busy_event_cnt is
				-- Init MPU6050		
				when 1 =>
					enable <= '1';
					rw <= '0';
					data_write <= PWR_MGMT_1;
				when 2 to 3 => 
					data_write <= x"00";
				when 4 => 
					enable <= '0';
				when 5 =>
					enable <= '1';
					data_write <= SMPLRT_DIV;
				when 6 to 7 => 
					data_write <= x"07";
				when 8 =>
					enable <= '0';
				when 9 =>
					enable <= '1';
					data_write <= CONFIG;
				when 10 to 11 =>
					data_write <= x"06";
				when 12 =>
					enable <= '0';
				when 13 => 
					enable <= '1';
					data_write <= GYRO_CONFIG;
				when 14 to 15 =>
					data_write <= x"18";
				when 16 =>
					enable <= '0';
				when 17 => 
					enable <= '1';
					data_write <= ACCEL_CONFIG;
				when 18 to 19 =>
					data_write <= x"01";
				when 20 =>
					enable <= '0';
					
					--Begin Read
				when 21 =>
					enable <= '1';
					rw <= '0';
					data_write <= ACCEL_XOUT_H;
				when 22 to 23 =>
					rw <= '1';
				when 24 =>
					enable <= '0';
				when 25 =>
					ax(15 downto 8) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= ACCEL_XOUT_L;
				when 26 to 27 =>
					rw <= '1';
				when 28 =>
					enable <= '0';
				when 29 =>
					ax(7 downto 0) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= ACCEL_YOUT_H;
				when 30 to 31 =>
					rw <= '1';
				when 32 =>
					enable <= '0';
				when 33 =>
					ay(15 downto 8) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= ACCEL_YOUT_L;
				when 34 to 35 =>
					rw <= '1';
				when 36 =>
					enable <= '0';
				when 37 =>
					ay(7 downto 0) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= ACCEL_ZOUT_H;
				when 38 to 39 =>
					rw <= '1';
				when 40 =>
					enable <= '0';
				when 41 =>
					az(15 downto 8) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= ACCEL_ZOUT_L;
				when 42 to 43 =>
					rw <= '1';
				when 44 =>
					enable <= '0';
				when 45 =>
					az(7 downto 0) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= GYRO_XOUT_H;
				when 46 to 47 =>
					rw <= '1';
				when 48 =>
					enable <= '0';
				when 49 =>
					gx(15 downto 8) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= GYRO_XOUT_L;
				when 50 to 51 =>
					rw <= '1';
				when 52 =>
					enable <= '0';
				when 53 =>
					gx(7 downto 0) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= GYRO_YOUT_H;
				when 54 to 55 =>
					rw <= '1';
				when 56 =>
					enable <= '0';
				when 57 =>
					gy(15 downto 8) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= GYRO_YOUT_L;
				when 58 to 59 =>
					rw <= '1';
				when 60 =>
					enable <= '0';
				when 61 =>
					gy(7 downto 0) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= GYRO_ZOUT_H;
				when 62 to 63 =>
					rw <= '1';
				when 64 =>
					enable <= '0';
				when 65 =>
					gz(15 downto 8) <= data_read;
					enable <= '1';
					rw <= '0';
					data_write <= GYRO_ZOUT_L;
				when 66 to 67 =>
					rw <= '1';
				when 68 =>
					enable <= '0';
				when 69 =>
					gz(7 downto 0) <= data_read;
					busy_event_cnt := 21;
				when others =>
					busy_event_cnt := 0;
			end case;
			
		end if;
	end process;
	
end architecture;