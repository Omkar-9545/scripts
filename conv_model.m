function multi_stage_filter_q15_dump(x_in_float, h1_float, h2_float, h3_float, out_file)
  % Convert input and coefficients to Q1.15
  x_in = float_to_q15(x_in_float);
  h1 = float_to_q15(h1_float);
  h2 = float_to_q15(h2_float);
  h3 = float_to_q15(h3_float);

  N = length(x_in);
  y1 = zeros(1, N, 'int16');
  y2 = zeros(1, N, 'int16');
  y3 = zeros(1, N, 'int16');

  % Stage 1
  x_buf1 = int16(zeros(1, length(h1)));
  for n = 1:N
    x_buf1 = [x_in(n), x_buf1(1:end-1)];
    y1(n) = q15_mac(x_buf1, h1);
  end

  % FIFO delay
  fifo1_depth = length(h1)-1;
  x1_delayed = [int16(zeros(1, fifo1_depth)), y1];
  x1_delayed = x1_delayed(1:N);

  % Stage 2
  x_buf2 = int16(zeros(1, length(h2)));
  for n = 1:N
    x_buf2 = [x1_delayed(n), x_buf2(1:end-1)];
    y2(n) = q15_mac(x_buf2, h2);
  end

  % FIFO delay
  fifo2_depth = length(h2)-1;
  x2_delayed = [int16(zeros(1, fifo2_depth)), y2];
  x2_delayed = x2_delayed(1:N);

  % Stage 3
  x_buf3 = int16(zeros(1, length(h3)));
  for n = 1:N
    x_buf3 = [x2_delayed(n), x_buf3(1:end-1)];
    y3(n) = q15_mac(x_buf3, h3);
  end

  % === Write Q1.15 integer output to file ===
  fid = fopen(out_file, 'w');
  for i = 1:N
    fprintf(fid, "%d\n", y3(i));   % Write as decimal integers
  end
  fclose(fid);

  % Optional: Also return float version if needed
  printf("Output written to %s\n", out_file);
end


%x = 0.8 * sin(2*pi*0.03*(0:199));  % Input signal
%h1 = fir1(31, 0.2);                % 32-tap filter
%h2 = fir1(31, 0.3);
%h3 = fir1(31, 0.4);

%multi_stage_filter_q15_dump(x, h1, h2, h3, "ref_output_q15.txt");

