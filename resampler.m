function [y_out, ptr_log] = resampler_full_model(x_in, h, ppm, fs, fifo_depth)
  % Inputs
  %   x_in       : Input signal (vector)
  %   h          : Filter coefficients (length 9)
  %   ppm        : Resampling error in PPM (e.g. ±200)
  %   fs         : Sampling frequency in Hz
  %   fifo_depth : FIFO buffer depth (e.g. 1024)
  %
  % Outputs
  %   y_out      : Resampled output
  %   ptr_log    : Log of read/write pointers (for analysis)

  % Initialize
  L = length(h);          % FIR length
  half_len = floor(L / 2);
  fifo = zeros(1, fifo_depth);
  wr_ptr = 1;
  rd_ptr = 1;

  % Resampler accumulator
  ppm_accum = 0;
  delta = ppm / 1e6;       % fractional offset

  y_out = [];
  ptr_log = [];

  for i = 1:length(x_in)
    % Write to FIFO
    fifo(wr_ptr) = x_in(i);
    wr_ptr = mod(wr_ptr, fifo_depth) + 1;

    % Log pointers
    ptr_log(end+1, :) = [wr_ptr, rd_ptr];   %Create a new row at the end of the array

    % Update accumulator
    ppm_accum += delta;

    % Check if we need to read a sample (overflow or underflow condition)
    if abs(ppm_accum) >= 1
      sign_ppm = sign(ppm_accum);
      ppm_accum -= sign_ppm;

      % Check boundary
      idx_start = rd_ptr - half_len;
      idxs = mod((idx_start : idx_start + L - 1) - 1, fifo_depth) + 1;

      % Read window and apply filter
      x_window = fifo(idxs);
      y = sum(x_window .* h);
      y_out(end+1) = y;

      % Update read pointer
      rd_ptr = mod(rd_ptr, fifo_depth) + 1;
    end
  end
end


%fs = 2e9;
%t = 0:1/fs:1e-6;           % 1 microsecond signal
%x = sin(2*pi*10e6*t);      % 10 MHz sine
%h = fir1(8, 0.2);          % Example 9-tap lowpass filter
%ppm = 200;
%fifo_depth = 1024;

%[y, log] = resampler_full_model(x, h, ppm, fs, fifo_depth);

% Plot result
%subplot(2,1,1); plot(y); title("Resampled Output");
%subplot(2,1,2); plot(log(:,1), log(:,2)); title("Write vs Read Pointer");
%xlabel('Time'); ylabel('Pointer');
%legend('Write Ptr', 'Read Ptr');


