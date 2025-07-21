import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d

# === Parameters ===
f_signal = 200e6        # Signal frequency: 200 MHz
Fs_nominal = 2e9        # Nominal sampling frequency: 2 GHz
ppm_error = 200         # Clock mismatch in ppm
duration = 25e-9        # Total signal duration: 50 ns

# === Nominal sampling ===
t_nominal = np.arange(0, duration, 1 / Fs_nominal)
original_signal = np.sin(2 * np.pi * f_signal * t_nominal)

# === Mismatched sampling ===
Fs_mismatch = Fs_nominal * (1 + ppm_error * 1e-6)
t_mismatch = np.arange(0, duration, 1 / Fs_mismatch)
mismatched_signal = np.sin(2 * np.pi * f_signal * t_mismatch)

# === Resample using interpolation ===
interp_func = interp1d(t_mismatch, mismatched_signal, kind='linear', fill_value="extrapolate")
corrected_signal = interp_func(t_nominal)

# === FFT Plot Function ===
def plot_all_ffts(original, mismatched, corrected, Fs_nom):
    N = len(original)
    freq = np.fft.fftfreq(N, d=1/Fs_nom)[:N//2] * 1e-6  # MHz

    fft_orig = np.abs(np.fft.fft(original)[:N//2]) / N
    fft_mis  = np.abs(np.fft.fft(mismatched[:N])[:N//2]) / N
    fft_corr = np.abs(np.fft.fft(corrected)[:N//2]) / N

    plt.figure(figsize=(10, 6))
    plt.plot(freq, 20 * np.log10(fft_orig), label='Original Signal')
    plt.plot(freq, 20 * np.log10(fft_mis), label='Mismatched Signal')
    plt.plot(freq, 20 * np.log10(fft_corr), label='Corrected Signal')
    plt.title("FFT Comparison of Signals")
    plt.xlabel("Frequency (MHz)")
    plt.ylabel("Magnitude (dB)")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.show()

# === Plot the FFTs ===
plot_all_ffts(original_signal, mismatched_signal, corrected_signal, Fs_nominal)
