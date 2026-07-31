/*
 * icebreaker_top.v -- board wrapper around the Clash-generated topEntity.
 *
 * The UP5K's RGB pins (39/40/41) are constant-current open-drain outputs and
 * can only be driven through the SB_RGBA_DRV hard block. Clash has no
 * primitive for it, so we instantiate it here and hand it the three PWM bits
 * the Clash design produces.
 *
 * This is the module yosys synthesises (-top icebreaker_top), not topEntity.
 *
 * Current settings mirror the upstream icebreaker sb_rgba_blink example:
 * half-current mode with the lowest per-channel step, which is plenty bright
 * for an indicator and keeps the LED from washing out.
 */

`default_nettype none

module icebreaker_top (
	input  wire       clk,
	input  wire       btn,
	output wire [2:0] rgb
);

	// {red, green, blue} -- see pack (r, g, b) in MoodLight.Pwm.pwmRGB
	wire [2:0] rgb_pwm;

	topEntity u_moodlight (
		.clk (clk),
		.btn (btn),
		.rgb (rgb_pwm)
	);

	// RGB0/RGB1/RGB2 are hard-wired to pins 39/40/41, i.e. red/green/blue on
	// the iCEbreaker (see LED_RGB in icebreaker-verilog-examples' pcf), so the
	// PWM bits are crossed over here: rgb_pwm[2] (red) drives RGB0PWM.
	SB_RGBA_DRV #(
		.CURRENT_MODE("0b1"),
		.RGB0_CURRENT("0b000001"),
		.RGB1_CURRENT("0b000001"),
		.RGB2_CURRENT("0b000001")
	) rgb_drv_I (
		.RGBLEDEN (1'b1),
		.CURREN   (1'b1),
		.RGB0PWM  (rgb_pwm[2]),   // red
		.RGB1PWM  (rgb_pwm[1]),   // green
		.RGB2PWM  (rgb_pwm[0]),   // blue
		.RGB0     (rgb[2]),
		.RGB1     (rgb[1]),
		.RGB2     (rgb[0])
	);

endmodule

`default_nettype wire
