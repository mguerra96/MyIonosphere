function HandleUndefinedFunctionError(obs_file)

%function that removes the "SYS / PHASE SHIFT" from header when it caused the issuing of a reading error

fclose('all');

obs_file_dir=[obs_file.folder '/' obs_file.name];

finp = fopen(obs_file_dir,'r');

fileBuffer = textscan(finp, '%s', 'Delimiter', '\n', 'whitespace', '');
fileBuffer = fileBuffer{1};

fileBuffer=fileBuffer(~contains(fileBuffer,"SYS / PHASE SHIFT"),:);

fclose(finp);

delete(obs_file_dir)

TempNewName=obs_file.name(1:end-4);

writematrix(char(fileBuffer),[obs_file.folder '/' TempNewName '.txt'],'QuoteStrings','none');

fclose('all');
movefile([obs_file.folder '/' TempNewName '.txt'],[obs_file.folder '/' TempNewName obs_file.name(end-3:end)])

end