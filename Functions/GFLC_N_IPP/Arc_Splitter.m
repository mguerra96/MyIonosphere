function Arc_ID=Arc_Splitter(Time,t_res)

% Function that searches for data gaps for the couples Receiver-Satellite
% if the data gap is longer than 3 time samples the arc is splitted and an unique ID is assigned to each of them

TimeGapsIdx=find(diff(Time)>seconds(t_res)*3);

Arc_ID=ones(size(Time))*1000; %this ensures that arc 3 is not before arc 10, as for string the first char is what counts

for TimeGapIter=1:length(TimeGapsIdx)
    Arc_ID(TimeGapsIdx(TimeGapIter)+1:end)=Arc_ID(TimeGapsIdx(TimeGapIter)+1:end)+1;
end

Arc_ID=string(Arc_ID);

end