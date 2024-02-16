function LeapSeconds=ReadLeapSeconds(nav_dir)

fID=fopen(nav_dir);

while ~feof(fID)
    tline=fgetl(fID);
    if contains(tline,'LEAP SECONDS')
        leaps=tline;
    end
end

leaps=split(leaps);
LeapSeconds=str2double(leaps{2});

fclose(fID);

end