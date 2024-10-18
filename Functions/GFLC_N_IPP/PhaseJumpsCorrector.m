function [phase_out,time] = PhaseJumpsCorrector(phase_in, time, std_max)

% function that searches for phase junps in the GFLC and correctes them

phdiff = diff(phase_in);
phstd = std(phdiff);
% idx = find(abs(phdiff) > phstd * std_max | abs(phdiff)>1); %phase junps are difened as junps bigger than std_max*std(diff(phase)) or bigger then 0.5 TECu
idx = find(abs(phdiff) > phstd * std_max); %phase junps are difened as junps bigger than std_max*std(diff(phase)) 


idx1 = [idx; numel(phase_in)]; %find indexes of phase junp

for xx = 1:numel(idx1)-1
    phx = phase_in(idx1(xx)) - phase_in(idx1(xx) + 1);
    phase_in(idx1(xx)+1 : idx1(xx+1)) = phase_in(idx1(xx) + 1:idx1(xx + 1)) + phx;  %correct phase jumps by assing t+1=t where t correspond to timestamp before pahse jump
end

phase_out = phase_in-min(phase_in)+5;  %perform mean of GFLC after phase jumps correction for better verticalization

end

