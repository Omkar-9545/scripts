%% PARAMETERS
Fs = 2e9;              % 2 GSPS
T = 5e-6;              % Signal duration: 5 microseconds
t = 0:1/Fs:T-1/Fs;     % Time vector
bitwidth = 8;          % Output bit width
fifo_offset = 624;     % FIFO offset based on architecture
fifo_length = 1024;    % FIFO depth
N = length(t);

%% INPUT SIGNAL
stream_in = sin(2*pi*100e6*t); % Example sine input @ 100 MHz

%% STATIC FIR COEFFICIENTS (32-tap LPF)
fir_coeff = fir1(31, 0.2);  % Low-pass filter, normalized freq 0.2

%% FIFO WITH OFFSET
fifo = zeros(1, fifo_length);
write_ptr = 1;
read_ptr = mod(write_ptr + fifo_offset - 1, fifo_length) + 1;
delayed_stream = zeros(1, N);

for i = 1:N
    fifo(write_ptr) = stream_in(i);
    
    if i > fifo_offset
        delayed_stream(i) = fifo(read_ptr);
    else
        delayed_stream(i) = 0;
    end

    write_ptr = mod(write_ptr, fifo_length) + 1;
    read_ptr = mod(read_ptr, fifo_length) + 1;
end

%% THREE-STAGE FILTER CHAIN
filtered1 = filter(fir_coeff, 1, delayed_stream);
filtered2 = filter(fir_coeff, 1, filtered1);
filtered3 = filter(fir_coeff, 1, filtered2);

%% FINAL CONVERSION: SHIFT + ROUND + SATURATE + TRUNCATE
shift_bits = 3;
shifted = filtered3 * 2^shift_bits;

% Round
rounded = round(shifted);

% Saturate
max_val = 2^(bitwidth-1) - 1;
min_val = -2^(bitwidth-1);
saturated = min(max(rounded, min_val), max_val);

% Truncate to int8
final_output = int8(saturated);

% Sticky flag (1 if overflow occurred during saturation)
sticky_flags = (rounded > max_val) | (rounded < min_val);

%% FFT ANALYSIS
NFFT = 1024;
freq = linspace(0, Fs/2, NFFT/2);

fft_input = abs(fft(stream_in, NFFT));
fft_coeff = abs(fft(fir_coeff, NFFT));
fft_output = abs(fft(double(final_output), NFFT));

%% PLOT
figure;

subplot(3,1,1);
plot(freq/1e6, 20*log10(fft_input(1:NFFT/2)));
title('Input Signal Spectrum');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
grid on;

subplot(3,1,2);
plot(freq/1e6, 20*log10(fft_coeff(1:NFFT/2)));
title('FIR Coefficient Spectrum');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
grid on;

subplot(3,1,3);
plot(freq/1e6, 20*log10(fft_output(1:NFFT/2)));
title('Final Output Spectrum');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
grid on;

%% DISPLAY STICKY FLAG STATISTICS
num_sticky = sum(sticky_flags);
fprintf('Number of saturated samples (sticky flags): %d\n', num_sticky);
