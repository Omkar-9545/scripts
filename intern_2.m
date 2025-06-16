function [y_out, ptr_log] = resampler_fixed_q15(x_in_float, h_float, ppm, fifo_depth)

  function q15 = float_to_q15(x)
    q15 = int16(round(x * 2^15));
  end

  function x = q15_to_float(q15)
    x = double(q15) / 2^15;
  end

  function result = q15_mul(a, b)
    prod = int32(a) * int32(b);          % Q15 * Q15 = Q30
    result = int16(min(max(round(prod / 2^15), -2^15), 2^15-1));  % back to Q15
  end

  function result = q15_dot(a, b)
    acc = int32(0);
    for i = 1:length(a)
      acc += int32(a(i)) * int32(b(i));
    end
    result = int16(min(max(round(acc / 2^15), -2^15), 2^15-1));  % back to Q15
  end

  % Convert input and coefficients to Q1.15
  x_q15 = float_to_q15(x_in_float);
  h_q15 = float_to_q15(h_float);

  % Setup
  L = length(h_q15);
  half_len = floor(L / 2);
  fifo = int16(zeros(1, fifo_depth));
  wr_ptr = 1;
  rd_ptr = 1;

  ppm_accum = 0;
  delta = ppm / 1e6;

  y_out = [];
  ptr_log = [];

  dff_chain = int16(zeros(1, L));  % represents DFFs before taps

  for i = 1:length(x_q15)
    % === Write Pointer Clock Gating ===
    fifo(wr_ptr) = x_q15(i);
    wr_ptr = mod(wr_ptr, fifo_depth) + 1;

    % Accumulate ppm offset
    ppm_accum += delta;

    % === Clock Gating Condition ===
    if abs(ppm_accum) >= 1
      sign_ppm = sign(ppm_accum);
      ppm_accum -= sign_ppm;

      % === Read Pointer Clock Gating ===
      % Tap inputs from FIFO into DFF chain
      idx_start = rd_ptr - half_len;
      idxs = mod((idx_start : idx_start + L - 1) - 1, fifo_depth) + 1;
      dff_chain = fifo(idxs);

      % Compute output
      y_q15 = q15_dot(dff_chain, h_q15);
      y_out(end+1) = y_q15;

      % Update read pointer
      rd_ptr = mod(rd_ptr, fifo_depth) + 1;
    end

    ptr_log(end+1, :) = [wr_ptr, rd_ptr];
  end

  % Convert output back to float for plotting
  y_out = q15_to_float(int16(y_out));
end


%fs = 2e9;
%t = 0:1/fs:1e-6;
%x = sin(2*pi*10e6*t);        % 10 MHz input
%h = fir1(8, 0.2);            % 9-tap lowpass filter
%ppm = 200;
%fifo_depth = 1024;

%[y, log] = resampler_fixed_q15(x, h, ppm, fifo_depth);

%subplot(2,1,1); plot(y); title("Resampled Output (Fixed-Point Q1.15)");
%subplot(2,1,2); plot(log(:,1), log(:,2)); title("Write vs Read Pointer"); xlabel("Time"); ylabel("Pointer");


