% Parameters
fs = 16000;          % Sampling frequency in Hz
f0 = 1000;           % Frequency to block (tone) in Hz
Q = 30;              % Quality factor (higher = narrower notch)

% Design notch filter
bw = f0 / Q;
[b, a] = iirnotch(f0 / (fs / 2), bw / (fs / 2));

% Normalize for Q1.15
scale = 2^15;

b_q15 = round(b * scale);
a_q15 = round(a * scale);

% Ensure stability: a(1) = 1 (typically) – skip it in Verilog
fprintf('Numerator coefficients (b):\n');
disp(b_q15);
fprintf('Denominator coefficients (a):\n');
disp(a_q15);

% Optional: Write to file for Verilog to read
coeff_file = 'notch_coeffs_q15.txt';
fid = fopen(coeff_file, 'w');
fprintf(fid, '%d\n', b_q15);   % b0, b1, b2
fprintf(fid, '%d\n', a_q15(2:end));  % skip a0 (which is 1.0 typically)
fclose(fid);
