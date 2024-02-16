function version=VersionFinder(obs_file_dir)

fID=fopen(obs_file_dir);

while 1
    line=fgetl(fID);
    if contains(line,'RINEX VERSION / TYPE')
        version=split(line);
        break
    end
end

fclose(fID);

version=version{2};

end