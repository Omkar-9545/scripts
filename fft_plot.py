import numpy as np
import matplotlib.pyplot as plt

# Length of signal
N = 64

# Create two signals of length N
x = np.hanning(N)              # Signal 1
h = np.random.rand(N)          # Signal 2

# Pointwise multiplication in time domain
y = x * h                      # Element-wise product

# Compute FFT of the result
Y = np.fft.fft(y)

# === Plot ===
plt.figure(figsize=(12, 6))

plt.subplot(2, 1, 1)
plt.plot(y, label='y[n] = x[n] * h[n] (time domain)')
plt.title('Time-Domain Pointwise Product')
plt.legend()
plt.grid(True)

plt.subplot(2, 1, 2)
plt.plot(np.abs(Y), label='|FFT(y)|')
plt.title('FFT Magnitude of y[n]')
plt.xlabel('Frequency Bin')
plt.legend()
plt.grid(True)

plt.tight_layout()
plt.show()
