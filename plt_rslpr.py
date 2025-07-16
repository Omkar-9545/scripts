import matplotlib.pyplot as plt

# Load samples
def load_samples(file):
    with open(file, 'r') as f:
        lines = f.readlines()
    return [int(line.strip()) for line in lines if line.strip()]

input_samples = load_samples('input_samples.txt')
output_samples = load_samples('output_samples.txt')

# Generate time axis assuming 1 clock per input
input_times = list(range(len(input_samples)))
output_times = []

# Estimate output sample time using relative output rate
input_len = len(input_samples)
output_len = len(output_samples)

# Time scaling: If output rate is faster, the spacing will be smaller
rate_ratio = output_len / input_len if input_len > 0 else 1.0
for i in range(len(output_samples)):
    output_times.append(i / rate_ratio)

# Plot
plt.figure(figsize=(12, 6))
plt.plot(input_times, input_samples, label='Input Samples', marker='o', linestyle='-', color='blue')
plt.plot(output_times, output_samples, label='Output Samples (Resampled)', marker='x', linestyle='--', color='orange')
plt.title("Resampler Input vs Output (Time-Aligned)")
plt.xlabel("Sample Index / Time Units")
plt.ylabel("Sample Value")
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()
