Pipelined AWGN Generator in Verilog (Q1.15 Output)
Pipeline Breakdown:
Stage 1: LFSR → Generates uniform random numbers

Stage 2: Accumulate 12 uniform samples

Stage 3: Center the sum

Stage 4: Scale with σ (Q1.15 multiplication)

Stage 5: Normalize result to Q1.15
