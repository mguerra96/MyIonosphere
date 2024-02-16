function phase_out = PhaseJumpsCorrector(phase_in, std_max)

phdiff = diff(phase_in);
phstd = std(phdiff);
idx = find(abs(phdiff) > phstd * std_max | abs(phdiff)>1);
idx1 = [idx; numel(phase_in)];

for xx = 1:numel(idx1)-1
    phx = phase_in(idx1(xx)) - phase_in(idx1(xx) + 1);
    phase_in(idx1(xx)+1 : idx1(xx+1)) = phase_in(idx1(xx) + 1:idx1(xx + 1)) + phx;
end

phase_out = phase_in;

end

