import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import resample

# Parameters
f_signal = 200e6           # Signal frequency: 200 MHz
Fs_nominal = 2e9           # Nominal sampling frequency: 2 GHz
ppm_error = 200            # Clock mismatch in ppm
duration = 25e-9           # Total signal duration: 50 ns

# Nominal sampling time vector
t_nominal = np.arange(0, duration, 1/Fs_nominal)
original_signal = np.sin(2 * np.pi * f_signal * t_nominal)

# Mismatched sampling time vector
Fs_mismatch = Fs_nominal * (1 + ppm_error * 1e-6)
t_mismatch = np.arange(0, duration, 1/Fs_mismatch)
mismatched_signal = np.sin(2 * np.pi * f_signal * t_mismatch)

# Resample mismatched signal to same number of samples as original
corrected_signal = resample(mismatched_signal, len(original_signal))

# === Zoom: First 1.5 cycles ===
cycle_time = 1 / f_signal          # 5 ns
zoom_time = 1.5 * cycle_time       # 7.5 ns
zoom_samples = np.sum(t_nominal < zoom_time)

# Trim data
t_nom_zoom = t_nominal[:zoom_samples] * 1e9         # in ns
t_mis_zoom = t_mismatch[:zoom_samples] * 1e9        # in ns
orig_zoom = original_signal[:zoom_samples]
mismatch_zoom = mismatched_signal[:zoom_samples]
corrected_zoom = corrected_signal[:zoom_samples]

# === Plot ===
plt.figure(figsize=(10, 5))
plt.plot(t_nom_zoom, orig_zoom, label="Original Signal", linewidth=1.5)
plt.plot(t_mis_zoom, mismatch_zoom, 's', label="Mismatched Sampling (+200 ppm)", linewidth=1)
plt.plot(t_nom_zoom, corrected_zoom, ':', label="Corrected (Resampled)", linewidth=2)

plt.title("Plot of original signal ,+200 ppm Mismatch, corrected")
plt.xlabel("Time (ns)")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
