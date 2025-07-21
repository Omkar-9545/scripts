%% PARAMETERS
Fs = 2e9;                  % 2 GSPS
T = 1e-6;                  % 1 us duration
t = 0:1/Fs:T-1/Fs;         % Time vector
N = length(t);

% Fixed-point definitions
word_in = 16; frac_in = 15;              % Q1.15
word_coeff = 6; frac_coeff = 5;          % Q1.5
word_accum = 32; frac_accum = 30;        % Q2.30 or Q5.30 intermediate
word_out = 16; frac_out = 15;            % Q1.15 output
shift_amt = 3;

%% INPUT SIGNAL (Q1.15)
x = fi(sin(2*pi*100e6*t), 1, word_in, frac_in);

%% FIR COEFFICIENTS (Q1.5)
coeffs = fi(fir1(31, 0.2), 1, word_coeff, frac_coeff);

%% FIFO PARAMETERS
fifo_depth = 1024;
fifo_offset = 624;

%% FIFO FUNCTION
function [delayed, sticky_fifo] = fifo_with_offset(signal, offset, depth)
    delayed = fi(zeros(size(signal)), 1, 16, 15);
    fifo = fi(zeros(1, depth), 1, 16, 15);
    sticky_fifo = false(size(signal));
    write_ptr = 1;
    read_ptr = mod(write_ptr + offset - 1, depth) + 1;

    for i = 1:length(signal)
        fifo(write_ptr) = signal(i);
        if i > offset
            delayed(i) = fifo(read_ptr);
        else
            delayed(i) = fi(0, 1, 16, 15);
        end
        write_ptr = mod(write_ptr, depth) + 1;
        read_ptr = mod(read_ptr, depth) + 1;
    end
end

%% FIR FILTER FUNCTION (with Q2.30 accumulation and rounding)
function [y, sticky_flag] = fixed_fir_q30(x, coeffs)
    len = length(coeffs);
    y = fi(zeros(size(x)), 1, 32, 30);
    sticky_flag = false(size(x));
    reg = fi(zeros(1, len), 1, 16, 15);

    for n = 1:length(x)
        reg = [x(n), reg(1:end-1)];
        acc = fi(0, 1, 32, 30);
        for k = 1:len
            mul = fi(reg(k) * coeffs(k), 1, 32, 30);
            acc = acc + mul;
        end
        y(n) = acc;
    end
end

%% CONVERSION BLOCK: Q8.30 → Q1.15
function [out, sticky] = convert_830_to_115(x, shift_bits)
    x_shifted = bitshift(x, shift_bits);  % Logical shift left
    x_rounded = round(x_shifted);         % Round to nearest
    max_val = 2^(15)-1;
    min_val = -2^(15);
    sticky = (x_rounded > max_val) | (x_rounded < min_val);
    x_sat = min(max(x_rounded, min_val), max_val);
    out = fi(x_sat / 2^15, 1, 16, 15);    % Truncate and convert to Q1.15
end

%% === STAGE-BY-STAGE PIPELINE ===

% Stage 1
[x1_fifo, sticky1] = fifo_with_offset(x, fifo_offset, fifo_depth);
[y1, sticky_f1] = fixed_fir_q30(x, coeffs);

% Stage 2
[x2_fifo, sticky2] = fifo_with_offset(y1, fifo_offset, fifo_depth);
[y2, sticky_f2] = fixed_fir_q30(x1_fifo, coeffs);

% Stage 3
[x3_fifo, sticky3] = fifo_with_offset(y2, fifo_offset, fifo_depth);
[y3, sticky_f3] = fixed_fir_q30(x2_fifo, coeffs);

% Final FIR stage
[y4, sticky_f4] = fixed_fir_q30(x3_fifo, coeffs);

% Final conversion
[y_out, sticky_final] = convert_830_to_115(y4, shift_amt);

%% === STICKY STATS ===
total_sticky = sticky1 | sticky2 | sticky3 | ...
               sticky_f1 | sticky_f2 | sticky_f3 | sticky_f4 | sticky_final;
fprintf("Total samples with overflow: %d\n", sum(total_sticky));

%% === FFT ANALYSIS ===
NFFT = 1024;
freq = linspace(0, Fs/2, NFFT/2);

fft_input = abs(fft(double(x), NFFT));
fft_output = abs(fft(double(y_out), NFFT));

figure;
subplot(2,1,1);
plot(freq/1e6, 20*log10(fft_input(1:NFFT/2)));
title('Input Spectrum (Q1.15)');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)'); grid on;

subplot(2,1,2);
plot(freq/1e6, 20*log10(fft_output(1:NFFT/2)));
title('Final Output Spectrum (Q1.15)');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)'); grid on;
