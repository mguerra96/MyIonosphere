function Unzip_And_DeHata(DB_Dir)

init_dir=pwd;

Unzipper_Path=char(mlreportgen.utils.findFile('7za.exe'));
copyfile(Unzipper_Path,[ DB_Dir '\obs\7za.exe'])

cd([DB_Dir '\obs']);

files2unzip=[dir('*.gz') ; dir('*.Z') ; dir('*.z') ; dir('*.tar') ; dir('*.rar')];

if ~isempty(files2unzip)
    fprintf('Unzipping obs files...\n')
    parfor i=1:length(files2unzip)
        [~,~]=dos(['7z e ' files2unzip(i).name]);
        delete(files2unzip(i).name);
    end
end

delete 7za.exe

DeHata_Path=char(mlreportgen.utils.findFile('crx2rnx.exe'));
copyfile(DeHata_Path,[ DB_Dir '\obs\crx2rnx.exe'])

files2dehata=[dir('*.crx') ; dir('*.*d') ; dir('*.*D')];

if ~isempty(files2dehata)
    fprintf('De-Hatanaka obs files...\n')
    parfor i=1:length(files2dehata)
        dos(['crx2rnx ' files2dehata(i).name]);
        delete(files2dehata(i).name);
    end
end

delete crx2rnx.exe

cd(init_dir)

end