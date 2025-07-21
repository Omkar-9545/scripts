# Save the MATLAB fixed-point model as a .m file with output to a text file

matlab_code = """
% File: fixed_point_resampler.m
% Fixed-point resampler model matching Verilog implementation

% Setup
T_in     = fixdt(1, 16, 15);  % Q1.15
T_coeff  = fixdt(1, 6, 5);    % Q1.5
T_prod   = fixdt(1, 32, 30);  % Q2.30
T_sum    = fixdt(1, 36, 30);  % Q5.30
T_accum  = fixdt(1, 32, 31);  % Q1.31
T_scaled = fixdt(1, 17, 16);  % Q1.16
T_out    = fixdt(1, 16, 15);  % Q1.15

% Input signal
N = 512;
x = sin(2*pi*0.01*(0:N-1)) * 0.95;
x_fixed = fi(x, T_in, 'RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');

% Filter coefficients (9-tap symmetric differentiator)
diff_coeffs = [-4 -3 -2 -1 0 1 2 3 4] / sum(abs([-4 -3 -2 -1 0 1 2 3 4]));
c_fixed = fi(diff_coeffs, T_coeff, 'RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');

% Initialize buffers and flags
buffer = fi(zeros(1,9), T_in);
sum_5_30 = fi(zeros(1,N), T_sum);
out_scaled = fi(zeros(1,N), T_out);
sticky1 = false;
sticky2 = false;
sticky3 = false;
sticky4 = false;

% Filtering
for i = 1:N
    buffer = [x_fixed(i), buffer(1:end-1)];
    prod_1_30 = fi(zeros(1,9), T_prod);
    
    for j = 1:9
        tmp = fi(buffer(j) * c_fixed(j), T_prod, ...
            'RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');
        sticky1 = sticky1 | isoverflow(tmp);
        prod_1_30(j) = tmp;
    end
    
    acc_5_30 = fi(sum(prod_1_30), T_sum, ...
        'RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');
    sticky2 = sticky2 | isoverflow(acc_5_30);
    sum_5_30(i) = acc_5_30;
end

% PPM Accumulation and final output
ppm_val = 0.75;
accum = fi(0, T_accum);

for i = 5:N
    accum = accum + fi(ppm_val, T_accum);
    if accum >= 1
        accum = accum - fi(1, T_accum);
        
        center = buffer(5);
        ppm_scaled = fi(sum_5_30(i) * accum, T_scaled, ...
            'RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');
        sticky3 = sticky3 | isoverflow(ppm_scaled);
        
        final = fi(ppm_scaled + center, T_out, ...
            'RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate');
        sticky4 = sticky4 | isoverflow(final);
        
        out_scaled(i) = final;
    end
end

% Save result to file
fid = fopen('resampler_output.txt', 'w');
for i = 1:N
    fprintf(fid, '%d\\n', out_scaled(i).int);
end
fclose(fid);

% Optional: Display sticky flags
fprintf('Overflow Flags:\\n');
fprintf('Q2.30 Multiply Overflow: %d\\n', sticky1);
fprintf('Q5.30 Accumulate Overflow: %d\\n', sticky2);
fprintf('Q5.30 * Q1.31 to Q1.16 Overflow: %d\\n', sticky3);
fprintf('Final Q1.16 + Q1.15 to Q1.15 Overflow: %d\\n', sticky4);
"""

# Save the MATLAB code to a .m file
with open("/mnt/data/fixed_point_resampler.m", "w") as f:
    f.write(matlab_code)

"/mnt/data/fixed_point_resampler.m"

