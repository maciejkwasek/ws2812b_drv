library ieee;
use ieee.std_logic_1164.all;

entity ws2812b_drv is
	generic
	(
		LED_NUMBER : natural := 8; -- 8x8 matrix
		
		REFRESH_PERIOD : natural := 1_000_000; -- 20ms @ 50MHz

		T_RESET : natural := 4500;	-- 90us
	
		T0H : natural := 20; -- 400ns
		T1H : natural := 40; -- 800ns
		T0L : natural := 42; -- 840ns
		T1L : natural := 22	-- 440ns
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

	signal frame_buffer : frame_buffer_t :=
	(
		0 => x"ff0000",
		1 => x"00ff00",
		2 => x"0000ff",
		3 => x"112233",
		others => x"00ff00"
	);

	type drv_state_t is (IDLE, RESET_PULSE, LOAD_BIT, BIT_H, BIT_L);
	
	signal c_state : drv_state_t := IDLE;
	signal delay_cnt : natural := 0;
	
	signal bit_idx : natural := 0;
	signal led_idx : natural := 0;
	
	signal high_pulse_limit : natural := 0;
	signal low_pulse_limit : natural := 0;
	
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
					if delay_cnt = REFRESH_PERIOD then
						c_state <= RESET_PULSE;
						delay_cnt <= 0;
						led_idx <= 0;
						bit_idx <= 0;
						dout <= '0';
					else
						delay_cnt <= delay_cnt + 1;
						dout <= '1';
					end if;

				when RESET_PULSE =>
					if delay_cnt = T_RESET-1 then
						delay_cnt <= 0;
						c_state <= LOAD_BIT;
						dout <= '1';
					else
						delay_cnt <= delay_cnt + 1;
					end if;
					
				when LOAD_BIT =>
						if frame_buffer(led_idx)(23-bit_idx) = '1' then
							high_pulse_limit <= T1H-1;
							low_pulse_limit <= T1L;
						else
							high_pulse_limit <= T0H-1;
							low_pulse_limit <= T0L;
						end if;
						
						if bit_idx = 23 then
							bit_idx <= 0;
							if led_idx < LED_NUMBER-1 then
								led_idx <= led_idx + 1;
							end if;
						else
							bit_idx <= bit_idx + 1;
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
						if led_idx = LED_NUMBER-1 and bit_idx = 23 then
							c_state <= IDLE;

							led_idx <= 0;
							bit_idx <= 0;
						else
							c_state <= LOAD_BIT;
						end if;
						dout <= '1';
					else
						delay_cnt <= delay_cnt + 1;
					end if;
			end case;
		end if;
	end process;
	
end architecture;