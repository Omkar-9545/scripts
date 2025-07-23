% Parameters
fs_tx = 1e9;           % Transmitter sampling rate = 1 GHz
f_sig = 200e6;         % Signal frequency = 200 MHz
duration = 20e-6;      % Duration = 20 us
ppm_offset = 200;      % Clock mismatch in ppm

% Derived quantities
fs_rx = fs_tx * (1 + ppm_offset * 1e-6);  % Receiver sampling rate

% Time vectors
t_tx = 0:1/fs_tx:duration;
t_rx = 0:1/fs_rx:duration;

% Original and mismatched signals
x_tx = sin(2*pi*f_sig*t_tx);
x_rx = interp1(t_tx, x_tx, t_rx, 'linear', 0);  % simulate mismatch

% Resample mismatched signal back to tx clock using interpolation
x_rx_corrected = interp1(t_rx, x_rx, t_tx, 'linear', 0);

% Use same FFT length for all
N = 2^nextpow2(length(t_tx));

% Trim all signals to length N
x_tx = x_tx(1:N);
x_rx = x_rx(1:N);
x_rx_corrected = x_rx_corrected(1:N);

% Apply Hann window
win = hann(N).';

xw_tx = x_tx .* win;
xw_rx = x_rx .* win;
xw_corr = x_rx_corrected .* win;

% FFT computation
X_tx = fft(xw_tx);
X_rx = fft(xw_rx);
X_corr = fft(xw_corr);

% Convert to dB
X_tx_mag_db = 20*log10(abs(X_tx) / max(abs(X_tx)));
X_rx_mag_db = 20*log10(abs(X_rx) / max(abs(X_rx)));
X_corr_mag_db = 20*log10(abs(X_corr) / max(abs(X_corr)));

f_tx = fs_tx * (0:N-1)/N;

% Plotting
figure;

subplot(3,1,1);
plot(f_tx/1e6, X_tx_mag_db, 'b');
title('Transmitter FFT with Hann Window (dB)');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
xlim([199.9 200.1]); ylim([-100 5]);

subplot(3,1,2);
plot(f_tx/1e6, X_rx_mag_db, 'r');
title('Receiver FFT with 200 ppm Mismatch (dB)');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
xlim([199.9 200.1]); ylim([-100 5]);

subplot(3,1,3);
plot(f_tx/1e6, X_corr_mag_db, 'g');
title('Corrected Receiver FFT after Resampling (dB)');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
xlim([199.9 200.1]); ylim([-100 5]);
