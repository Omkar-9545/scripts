// Simple I/Q mismatch simulator in Q1.15
// Applies gain mismatch to Q and rotates (I, Q) by fixed angle

module iq_mismatch_sim #(
    parameter signed [15:0] GAIN_Q   = 16'sd31130,  // ~0.95 in Q1.15 (gain mismatch)
    parameter signed [15:0] COS_THETA = 16'sd32138, // ~cos(20°) = 0.94 in Q1.15
    parameter signed [15:0] SIN_THETA = 16'sd11100  // ~sin(20°) = 0.34 in Q1.15
)(
    input  signed [15:0] I_in,
    input  signed [15:0] Q_in,
    output signed [15:0] I_out,
    output signed [15:0] Q_out
);

    // Apply gain mismatch to Q
    wire signed [31:0] Q_scaled_full = Q_in * GAIN_Q;
    wire signed [15:0] Q_scaled = Q_scaled_full[30:15]; // Q1.15 output

    // Rotate (I, Q) using fixed rotation matrix
    wire signed [31:0] Icos = I_in * COS_THETA;
    wire signed [31:0] Qsin = Q_scaled * SIN_THETA;
    wire signed [31:0] Isin = I_in * SIN_THETA;
    wire signed [31:0] Qcos = Q_scaled * COS_THETA;

    wire signed [15:0] I_rot = (Icos - Qsin) >>> 15;
    wire signed [15:0] Q_rot = (Isin + Qcos) >>> 15;

    assign I_out = I_rot;
    assign Q_out = Q_rot;

endmodule
