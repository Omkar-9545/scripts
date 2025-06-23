function [I_q15_out, Q_q15_out] = iq_mismatch_sim_q15(I_q15_in, Q_q15_in)

    % Inputs:
    % - I_q15_in, Q_q15_in: column vectors of input I and Q samples in Q1.15 (int16)
    % Outputs:
    % - I_q15_out, Q_q15_out: output samples after mismatch in Q1.15 (int16)

    % Parameters (same as Verilog)
    GAIN_Q     = 0.95;
    COS_THETA  = cosd(20);   % ~0.9397
    SIN_THETA  = sind(20);   % ~0.3420

    % Convert to Q1.15 format
    GAIN_Q_q15    = int32(round(GAIN_Q    * 2^15));
    COS_THETA_q15 = int32(round(COS_THETA * 2^15));
    SIN_THETA_q15 = int32(round(SIN_THETA * 2^15));

    % Ensure input is int16 column vectors
    I_q15_in = int16(I_q15_in(:));
    Q_q15_in = int16(Q_q15_in(:));

    % Apply gain mismatch to Q
    Q_scaled = bitshift(int32(Q_q15_in) .* GAIN_Q_q15, -15);  % Q1.15

    % Rotate (I, Q)
    Icos = int32(I_q15_in) .* COS_THETA_q15;
    Qsin = Q_scaled .* SIN_THETA_q15;
    Isin = int32(I_q15_in) .* SIN_THETA_q15;
    Qcos = Q_scaled .* COS_THETA_q15;

    I_rot = bitshift(Icos - Qsin, -15); % Q1.15
    Q_rot = bitshift(Isin + Qcos, -15); % Q1.15

    % Clip to int16 range
    I_q15_out = int16(max(min(I_rot, 32767), -32768));
    Q_q15_out = int16(max(min(Q_rot, 32767), -32768));
end


% Generate example Q1.15 inputs
I_in_float = 0.5;   % example: 0.5
Q_in_float = 0.5;   % example: 0.5

I_q15 = int16(round(I_in_float * 2^15));
Q_q15 = int16(round(Q_in_float * 2^15));

[I_out, Q_out] = iq_mismatch_sim_q15(I_q15, Q_q15);

fprintf('I_out = %d  (%.5f)\n', I_out, double(I_out)/2^15);
fprintf('Q_out = %d  (%.5f)\n', Q_out, double(Q_out)/2^15);
