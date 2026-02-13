library ieee;
use ieee.std_logic_1164.all;

entity ws2812b_drv_tb is
end entity;

architecture sim of ws2812b_drv_tb is
	signal clk : std_logic;
	signal rst_n : std_logic;
	
	signal dout : std_logic;
begin

	ws2812b_drv_inst : entity work.ws2812b_drv
		generic map
		(
			LED_NUMBER => 4,
			
			REFRESH_PERIOD => 50,
			T_RESET => 10,
			
			T0H => 3,
			T0L => 7,
			
			T1H => 7,
			T1L => 3
		)
		port map
		(
			clk => clk,
			rst_n => rst_n,
			dout => dout
		);

	process
	begin	
		while true loop
			clk <= '1';
			wait for 20 ns;
			clk <= '0';
			wait for 20 ns;
		end loop;
	end process;
	
	process
	begin
		report "dout = " & std_logic'image(dout);
		
		wait until rising_edge(clk);
		rst_n <= '0';
		wait for 80 ns;
		rst_n <= '1';
		wait until rising_edge(clk);
		
		
		wait;
	end process;
	
	
end architecture;