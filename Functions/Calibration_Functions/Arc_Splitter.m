function Arc_ID=Arc_Splitter(Time,t_res)

TimeGapsIdx=find(diff(Time)>seconds(t_res)*4);
Arc_ID=zeros(size(Time));
for TimeGapIter=1:length(TimeGapsIdx)
    Arc_ID(TimeGapsIdx(TimeGapIter)+1:end)=Arc_ID(TimeGapsIdx(TimeGapIter)+1:end)+1;
end

Arc_ID=num2str(Arc_ID,'%03d');

end