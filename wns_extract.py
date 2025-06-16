def extract_wns_whs(file_path):
    with open(file_path, "r") as f:
        lines = f.readlines()

    header_index = None
    for i, line in enumerate(lines):
        if "WNS(ns)" in line and "TNS(ns)" in line:
            header_index = i
            break

    if header_index is None:
        return None, None

    for line in lines[header_index + 1:]:
        if line.strip() and not line.strip().startswith("---"):
            values = line.split()
            wns = float(values[0])
            whs = float(values[4])
            return wns, whs

    return None, None


file_path = r"C:\Users\omkar\OneDrive\Desktop\FPGA\adder.runs\impl_1\N_Bit_Adder_timing_summary_routed.rpt"
wns, whs = extract_wns_whs(file_path)
print(f"WNS: {wns} ns, WHS: {whs} ns")
