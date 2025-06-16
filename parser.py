#Writing a script to parse Vivado reports

import re,csv
import pandas as pd

def extract_utilization(report_text):
    data = {}

    # CLB logic resources
    clb_patterns = {
        "LUT as Logic": r"LUT as Logic\s+\|\s+(\d+)",
        "LUT as Memory": r"LUT as Memory\s+\|\s+(\d+)",
        "Register as Flip Flop": r"Register as Flip Flop\s+\|\s+(\d+)",
        "Register as Latch": r"Register as Latch\s+\|\s+(\d+)",
        "CARRY8": r"CARRY8\s+\|\s+(\d+)",
        "F7 Muxes": r"F7 Muxes\s+\|\s+(\d+)",
        "F8 Muxes": r"F8 Muxes\s+\|\s+(\d+)",
        "F9 Muxes": r"F9 Muxes\s+\|\s+(\d+)"
    }

    for key, pattern in clb_patterns.items():
        match = re.search(pattern, report_text)
        data[key] = int(match.group(1)) if match else 0

    # Memory blocks
    ram_patterns = {
        "RAMB36": r"(RAMB36/FIFO\*?)\s*\|\s*(\d+)",
        "RAMB18": r"RAMB18\s+\|\s+(\d+)",
        "URAM Blocks": r"UltraRAM\s+\|\s+(\d+)"
    }

    for key, pattern in ram_patterns.items():
        match = re.search(pattern, report_text)
        if(key!="RAMB36"):
            data[key] = int(match.group(1)) if match else 0
        else:
            data[key] = int(match.group(2)) if match else 0

    # DSPs
    data["DSP Blocks"] = int(re.search(r"DSPs\s+\|\s+(\d+)", report_text).group(1)) if re.search(r"DSPs\s+\|\s+(\d+)", report_text) else 0

    # I/Os
    data["I/O Block"] = int(re.search(r"Bonded IOB\s+\|\s+(\d+)", report_text).group(1)) if re.search(r"Bonded IOB\s+\|\s+(\d+)", report_text) else 0

    # Clocks

    return data

def extract_clock_info(report_text):
    clock_data = {}
    clock_elements = {
        "BUFG": r"BUFG\s+\|\s+(\d+)",
        "BUFH": r"BUFH\s+\|\s+(\d+)",
        "BUFR": r"BUFR\s+\|\s+(\d+)",
        "MMCME": r"MMCME\d*\s+\|\s+(\d+)",
        "PLLE": r"PLLE\d*\s+\|\s+(\d+)"
    }

    for clk, pattern in clock_elements.items():
        match = re.search(pattern, report_text)
        clock_data[clk] = int(match.group(1)) if match else 0

    return clock_data


filepath = r"C:\Users\omkar\OneDrive\Desktop\FPGA\adder.runs\synth_1\N_Bit_Adder_utilization_synth.rpt"

with open(filepath, "r") as file:
    report_text = file.read()

utilization = extract_utilization(report_text)

# Get the CSV file name
filename = input("Enter the csv filename you want results to save into:\n")

fieldnames = utilization.keys()

with open(filename, mode="w", newline='') as file:
    writer = csv.writer(file)
    writer.writerow(fieldnames)
    writer.writerow(utilization.values())

print(f"CSV file '{filename}' has been created successfully.\n")

df = pd.reas_csv("./data.csv")
df