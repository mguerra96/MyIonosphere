function HandleDuplicateName(obs_file)

% Handle the error caused by two observables having the same name (usually happens for Japanase system)
% the second iteration of the name of the same observables is changed to x0x 

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
    if contains(line,"SYS / # / OBS TYPES")
        SplittedLine=split(line(8:end-21));
        [NumOfRep,RepObs]=groupcounts(SplittedLine);
        Obs2Rename=RepObs(NumOfRep>1);
        for iObs=Obs2Rename'
            idx=find(strcmp(SplittedLine,iObs));
            NewObsName=char(iObs);
            NewObsName(2)='0';
            SplittedLine{idx(2)}=NewObsName;
            CorrectedLine=[line(1:7) char(join(SplittedLine,' ')) line(end-20:end)];
            fileBuffer{LineNum}=CorrectedLine;
        end
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


