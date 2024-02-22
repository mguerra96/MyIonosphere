function Unzip_And_DeHata(DB_Dir)

% function that unzips and de-hatanaka the given obs files
% Input is database directory

init_dir=pwd;

Unzipper_Path=char(mlreportgen.utils.findFile('7za.exe')); %find path to 7za
copyfile(Unzipper_Path,[ DB_Dir '\obs\7za.exe']) %copy 7za to obs folder

cd([DB_Dir '\obs']);

files2unzip=[dir('*.gz') ; dir('*.Z') ; dir('*.z') ; dir('*.tar') ; dir('*.rar')]; %get list of files to unzip

if ~isempty(files2unzip)
    fprintf('Unzipping obs files...\n')
    parfor i=1:length(files2unzip)
        [~,~]=dos(['7z e ' files2unzip(i).name]); %unzip files
        delete(files2unzip(i).name);
    end
end

delete 7za.exe

DeHata_Path=char(mlreportgen.utils.findFile('crx2rnx.exe')); %find path to crx2rnx
copyfile(DeHata_Path,[ DB_Dir '\obs\crx2rnx.exe'])  %copy crx2rnx to to obs dir

files2dehata=[dir('*.crx') ; dir('*.*d') ; dir('*.*D')];

if ~isempty(files2dehata)
    fprintf('De-Hatanaka obs files...\n')
    parfor i=1:length(files2dehata)
        dos(['crx2rnx ' files2dehata(i).name]); %perfom de-hatanaka
        delete(files2dehata(i).name);
    end
end

delete crx2rnx.exe

cd(init_dir)

end