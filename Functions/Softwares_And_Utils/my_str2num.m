function out=my_str2num(input)

% this function is MATLAB native str2num but 10x faster
% funny right?

out=double(string(input));

end