function y = float_to_q15(x)
  y = int16(round(x * 2^15));
end

function y = q15_to_float(x)
  y = double(x) / 2^15;
end

function y = q15_mul(a, b)
  % a, b are int16
  prod = int32(a) .* int32(b); % Q1.15 * Q1.15 = Q2.30
  y = int16(bitshift(prod, -15)); % Downscale to Q1.15
end

function y = q15_mac(x, h)
  acc = int32(0);
  for i = 1:length(x)
    acc += int32(x(i)) * int32(h(i));
  end
  y = int16(bitshift(acc, -15)); % Return Q1.15
end

