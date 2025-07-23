% Parameters
fs_tx = 1e9;           % Transmitter sampling rate = 1 GHz
f_sig = 200e6;         % Signal frequency = 200 MHz
duration = 20e-6;      % Duration = 20 us
ppm_offset = 200;      % Clock mismatch in ppm

% Derived quantities
fs_rx = fs_tx * (1 + ppm_offset * 1e-6);  % Receiver clock

% Time vectors
t_tx = 0:1/fs_tx:duration;
t_rx = 0:1/fs_rx:duration;

% Signals
x_tx = sin(2*pi*f_sig*t_tx);
x_rx = interp1(t_tx, x_tx, t_rx, 'linear', 0);

% FFT setup
N = 2^nextpow2(min(length(x_tx), length(x_rx)));  % FFT length
x_tx = x_tx(1:N);
x_rx = x_rx(1:N);

% Apply Hann window
win = hann(N).';

xw_tx = x_tx .* win;
xw_rx = x_rx .* win;

% Compute FFTs
X_tx = fft(xw_tx);
X_rx = fft(xw_rx);

% Normalize and convert to dB
X_tx_mag_db = 20*log10(abs(X_tx) / max(abs(X_tx)));
X_rx_mag_db = 20*log10(abs(X_rx) / max(abs(X_rx)));

f_tx = fs_tx * (0:N-1)/N;
f_rx = fs_rx * (0:N-1)/N;

% Plot FFTs in dB
figure;

subplot(2,1,1);
plot(f_tx/1e6, X_tx_mag_db, 'b');
title('Transmitter FFT with Hann Window (dB)');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
xlim([199.9 200.1]); ylim([-100 5]);

subplot(2,1,2);
plot(f_rx/1e6, X_rx_mag_db, 'r');
title('Receiver FFT with 200 ppm Mismatch (dB)');
xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
xlim([199.9 200.1]); ylim([-100 5]);

