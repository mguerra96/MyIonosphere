function HandleWrongDatetime(obs_file)

%function that modifies the format of date in the PGM / RUN BY / DATE that causes a reading error 

fclose('all');

obs_file_dir=[obs_file.folder '/' obs_file.name];

finp = fopen(obs_file_dir,'r');

fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
fileBuffer = fileBuffer{1};

fclose(finp);

finp = fopen(obs_file_dir,'r');

LineNum=1;

while 1

    line=fgetl(finp);
    if contains(line,"PGM / RUN BY / DATE")
        CorrectedLine=['Spider V7.1.1.7438  DGS                 20220314 000018 UTC ' line(end-18:end)];
        fileBuffer{LineNum}=CorrectedLine;
    end

    LineNum=LineNum+1;

    if contains(line,"END OF HEADER")
        break
    end

end

fclose(finp);

delete(obs_file_dir)

TempNewName=obs_file.name(1:end-4);

writecell(fileBuffer,[obs_file.folder '/' TempNewName '.txt']);

fclose('all');
movefile([obs_file.folder '/' TempNewName '.txt'],[obs_file.folder '/' TempNewName obs_file.name(end-3:end)])

end


