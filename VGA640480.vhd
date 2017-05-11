library	ieee;
use		ieee.std_logic_1164.all;
use		ieee.std_logic_unsigned.all;
use		ieee.std_logic_arith.all;

entity vga640480 is
	 port(
			reset       :         in  STD_LOGIC;
			clk100      :         in  STD_LOGIC; --100M时钟输入
			x, y		:		  out std_logic_vector(9 downto 0); --输出当前要绘制的像素位置
			r_in, g_in, b_in :    in std_logic_vector(2 downto 0); --输入给定像素位置的颜色
			clk25       :		  out std_logic; --输出25MHz工作时钟
			hs,vs       :         out STD_LOGIC; --行同步、场同步信号
			r,g,b       :         out STD_LOGIC_vector(2 downto 0) --输出的颜色信号
	  );
end vga640480;

architecture behavior of vga640480 is
	
	signal r1,g1,b1   : std_logic_vector(2 downto 0);					
	signal hs1,vs1    : std_logic;				
	signal vector_x : std_logic_vector(9 downto 0);		--X坐标
	signal vector_y : std_logic_vector(8 downto 0);		--Y坐标
	signal clk, clk50	:	 std_logic;
begin
 -----------------------------------------------------------------------
 	x <= vector_x when vector_x >= 0 and vector_x < 640 else (others => '0');
	y <= "0" & vector_y when vector_y >= 0 and vector_y < 480 else (others => '0');
 -----------------------------------------------------------------------
	process(clk100)	--对100M输入信号二分频
	begin
        if(rising_edge(clk100)) then 
             clk50 <= not clk50;
        end if;
	end process;

	process(clk50)	--对50M输入信号二分频
    begin
        if(rising_edge(clk50)) then 
             clk <= not clk;
        end if;
 	end process;

	clk25 <= clk;
 -----------------------------------------------------------------------
	 process(clk,reset)	--行区间像素数（含消隐区）
	 begin
	  	if reset='0' then
	   		vector_x <= (others=>'0');
	  	elsif clk'event and clk='1' then
	   		if vector_x=799 then
	    		vector_x <= (others=>'0');
	   		else
	    		vector_x <= vector_x + 1;
	   		end if;
	  	end if;
	 end process;

  -----------------------------------------------------------------------
	 process(clk,reset)	--场区间行数（含消隐区）
	 begin
	  	if reset='0' then
	   		vector_y <= (others=>'0');
	  	elsif clk'event and clk='1' then
	   		if vector_x=799 then
	    		if vector_y=524 then
	     			vector_y <= (others=>'0');
	    		else
	     			vector_y <= vector_y + 1;
	    		end if;
	   		end if;
	  	end if;
	 end process;
 
  -----------------------------------------------------------------------
	 process(clk,reset) --行同步信号产生（同步宽度96，前沿16）
	 begin
		  if reset='0' then
		   hs1 <= '1';
		  elsif clk'event and clk='1' then
		   	if vector_x>=656 and vector_x<752 then
		    	hs1 <= '0';
		   	else
		    	hs1 <= '1';
		   	end if;
		  end if;
	 end process;
 
 -----------------------------------------------------------------------
	 process(clk,reset) --场同步信号产生（同步宽度2，前沿10）
	 begin
	  	if reset='0' then
	   		vs1 <= '1';
	  	elsif clk'event and clk='1' then
	   		if vector_y>=490 and vector_y<492 then
	    		vs1 <= '0';
	   		else
	    		vs1 <= '1';
	   		end if;
	  	end if;
	 end process;
 -----------------------------------------------------------------------
	 process(clk,reset) --行同步信号输出
	 begin
	  	if reset='0' then
	   		hs <= '0';
	  	elsif clk'event and clk='1' then
	   		hs <=  hs1;
	  	end if;
	 end process;

 -----------------------------------------------------------------------
	 process(clk,reset) --场同步信号输出
	 begin
	  	if reset='0' then
	   		vs <= '0';
	  	elsif clk'event and clk='1' then
	   		vs <=  vs1;
	  	end if;
	 end process;
	
 -----------------------------------------------------------------------	
	process(reset,clk,vector_x,vector_y) -- XY坐标定位控制
	begin  
		if reset='0' then
			        r1  <= "000";
					g1	<= "000";
					b1	<= "000";	
		elsif(clk'event and clk='1')then
			-- 如果在显示范围内，则从外部读取颜色值输出，否则输出0
		 	if vector_x >= 0 and vector_x < 640 and vector_y >= 0 and vector_y < 480 then
				r1 <= r_in;
				g1 <= g_in;
				b1 <= b_in;
			else
				r1  <= "000";
				g1	<= "000";
				b1	<= "000";
			end if;
		end if;		 
	end process;	

	-----------------------------------------------------------------------
	process (hs1, vs1, r1, g1, b1)	--色彩输出
	begin
		if vector_x < 640 and vector_y < 480 then
			r	<= r1;
			g	<= g1;
			b	<= b1;
		else
			r	<= (others => '0');
			g	<= (others => '0');
			b	<= (others => '0');
		end if;
	end process;

end behavior;

