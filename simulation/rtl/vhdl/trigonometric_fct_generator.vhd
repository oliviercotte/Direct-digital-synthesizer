-- Filename: trigonometric_function_generator.vhd
-- Author: Olivier Cotte
-- Date: Jan-2017
-- Description:

use work.cordic_types.all;
	
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library IEEE_PROPOSED;
use IEEE_PROPOSED.FIXED_PKG.ALL;

entity trigonometric_function_generator is
	port (
		clk, rst_n : in std_logic;
		mode_reg : in std_logic;
		coordinate_system_reg : in std_logic_vector(2 downto 0);
		ddfs_function_sig : in ddfs_function_t;
		trig_fct_out : out std_logic_vector(BIT_WIDTH-1 downto 0)
	);
end trigonometric_function_generator;

architecture rtl of trigonometric_function_generator is
-- CORDIC --
signal coordinate_system_i_next, coordinate_system_i_ff : std_logic_vector(2 downto 0);
signal x_in, y_in, z_in : std_logic_vector(BIT_WIDTH-1 downto 0);
signal x_out, y_out, z_out : std_logic_vector(BIT_WIDTH-1 downto 0);
signal OK : std_logic;
begin
	------------------------------------------------------------------------------------------------
	-- phase_gen : 
	------------------------------------------------------------------------------------------------
	phase_gen : entity work.phase_generator(rtl)
	port map (
		clk => clk,
		rst_n => rst_n,
		function_type_sig => ddfs_function_sig,
		phase_out => z_in
	);
	
	------------------------------------------------------------------------------------------------
	-- cordic_algorithm : 
	------------------------------------------------------------------------------------------------
	cordic_algorithm : entity work.cordic_core(pipelined_arch)
	port map(
		clk => clk,
		rst_n => rst_n,
		mode => mode_reg,
		coordinate_system => coordinate_system_reg,
		x_in => x_in,
		y_in => y_in,
		z_in => z_in,
		valid => OK,
		x_out => x_out,
		y_out => y_out,
		z_out => z_out
	);
	
	------------------------------------------------------------------------------------------------
	-- mux_cordic_output : 
	------------------------------------------------------------------------------------------------ 
	mux_ddfs_output : process(ddfs_function_sig, x_out, y_out, z_out) is
	begin
		case ddfs_function_sig is
			when COSINE | ARCCOSINE | COSINE_H | SEC_H => trig_fct_out <= x_out;
			when SINE | ARCSINE | SINE_H | GEN_SOLITON_SHAPE => trig_fct_out <= y_out;
			when EXPONENTIAL => trig_fct_out <= to_slv(resize(Hyperbolic_Coordinate_t(x_out) + Hyperbolic_Coordinate_t(y_out), Hyperbolic_Coordinate_t(x_out)));
			when others => trig_fct_out <= (others => '0');
		end case;
	end process mux_ddfs_output;
end rtl; 