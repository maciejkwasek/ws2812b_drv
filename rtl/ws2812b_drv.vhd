library ieee;
use ieee.std_logic_1164.all;

entity ws2812b_drv is
	generic
	(
		LED_NUMBER : natural := 64; -- 8x8 matrix
		
		REFRESH_PERIOD : natural := 1_000_000; -- 20ms

		T_RESET : natural := 10000;	-- 200us
	
		T0H : natural := 20; -- 400ns
		T1H : natural := 40; -- 800ns
		T0L : natural := 40; -- 800ns
		T1L : natural := 20	-- 400ns
	);
	
	port
	(
		clk : in std_logic;
		rst_n : in std_logic;
		
		dout : out std_logic
	);
end entity;

architecture rtl of ws2812b_drv is

	type frame_buffer_t is array (0 to LED_NUMBER-1) of std_logic_vector(23 downto 0);

	-- led test pattern
	function init_frame return frame_buffer_t is
		 variable tmp : frame_buffer_t;
		 constant RED   : std_logic_vector(23 downto 0) := x"000f00";
		 constant GREEN : std_logic_vector(23 downto 0) := x"0f0000";
		 constant BLUE  : std_logic_vector(23 downto 0) := x"00000f";
	begin
		 for i in 0 to LED_NUMBER-1 loop
			  case i mod 3 is
					when 0 =>
						 tmp(i) := RED;
					when 1 =>
						 tmp(i) := GREEN;
					when others =>
						 tmp(i) := BLUE;
			  end case;
		 end loop;

		 return tmp;
	end function;

	signal frame_buffer : frame_buffer_t := init_frame;

	type drv_state_t is (IDLE, RESET_PULSE, LOAD_PIXEL, ALIGN_LOAD_BIT, LOAD_BIT, BIT_H, BIT_L);
	
	signal c_state : drv_state_t := IDLE;
	signal delay_cnt : natural := 0;
	
	signal bit_idx : natural := 0;
	signal led_idx : natural := 0;
	
	signal high_pulse_limit : natural := 0;
	signal low_pulse_limit : natural := 0;
	
	signal pixel_reg : std_logic_vector(23 downto 0);

begin

	process(clk, rst_n)
	begin
		if rst_n = '0' then
			
			delay_cnt <= 0;
			led_idx <= 0;
			bit_idx <= 0;
			c_state <= IDLE;
			dout <= '0';
			
		elsif rising_edge(clk) then

			case c_state is
				when IDLE =>				
					if delay_cnt = REFRESH_PERIOD-1 then
						c_state <= RESET_PULSE;
						delay_cnt <= 0;
						led_idx <= 0;
						bit_idx <= 0;
						dout <= '0';
					else
						delay_cnt <= delay_cnt + 1;
					end if;

				when RESET_PULSE =>
					if delay_cnt = T_RESET-1 then
						delay_cnt <= 0;
						c_state <= LOAD_PIXEL;
						dout <= '1';
					else
						delay_cnt <= delay_cnt + 1;
					end if;
					
				when LOAD_PIXEL =>
					pixel_reg <= frame_buffer(led_idx);
					c_state <= LOAD_BIT;

				when ALIGN_LOAD_BIT =>
					c_state <= LOAD_BIT;

				when LOAD_BIT =>
						if pixel_reg(23-bit_idx) = '1' then
							high_pulse_limit <= T1H-2;
							low_pulse_limit <= T1L;
						else
							high_pulse_limit <= T0H-2;
							low_pulse_limit <= T0L;
						end if;

						c_state <= BIT_H;
						dout <= '1';

				when BIT_H =>
					if delay_cnt = high_pulse_limit-1 then
						delay_cnt <= 0;
						dout <= '0';
						c_state <= BIT_L;
					else
						delay_cnt <= delay_cnt + 1;
					end if;

				when BIT_L =>
					if delay_cnt = low_pulse_limit-1 then
						delay_cnt <= 0;

						if bit_idx = 23 then
							bit_idx <= 0;

							if led_idx < LED_NUMBER-1 then
								led_idx <= led_idx + 1;
								c_state <= LOAD_PIXEL;
							else
								c_state <= IDLE;
							end if;
						else
							bit_idx <= bit_idx + 1;
							c_state <= ALIGN_LOAD_BIT;
						end if;

						dout <= '1';
					else
						delay_cnt <= delay_cnt + 1;
					end if;
			end case;
		end if;
	end process;
	
end architecture;
