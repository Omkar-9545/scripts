def plot_all_ffts_zoom_log(original, mismatched, corrected, Fs_nom):
    N = len(original)
    freq = np.fft.fftfreq(N, d=1/Fs_nom)[:N//2] * 1e-6  # MHz

    # Add small epsilon to avoid log(0)
    epsilon = 1e-12
    fft_orig = np.abs(np.fft.fft(original)[:N//2]) / N + epsilon
    fft_mis  = np.abs(np.fft.fft(mismatched[:N])[:N//2]) / N + epsilon
    fft_corr = np.abs(np.fft.fft(corrected)[:N//2]) / N + epsilon

    # Zoom range: ±10 MHz around 200 MHz
    zoom_center = 200  # MHz
    zoom_width = 10    # MHz
    zoom_indices = np.where((freq >= zoom_center - zoom_width) & (freq <= zoom_center + zoom_width))

    # Plot zoomed and log-scaled frequency
    plt.figure(figsize=(10, 6))
    plt.plot(freq[zoom_indices], 20 * np.log10(fft_orig[zoom_indices]), label='Original Signal')
    plt.plot(freq[zoom_indices], 20 * np.log10(fft_mis[zoom_indices]), label='Mismatched Signal')
    plt.plot(freq[zoom_indices], 20 * np.log10(fft_corr[zoom_indices]), label='Corrected Signal')
    plt.title("Zoomed FFT Comparison (200 ± 10 MHz)")
    plt.xlabel("Frequency (MHz)")
    plt.ylabel("Magnitude (dB)")
    plt.grid(True, which='both', linestyle='--')
    plt.xscale("log")
    plt.legend()
    plt.tight_layout()
    plt.show()
