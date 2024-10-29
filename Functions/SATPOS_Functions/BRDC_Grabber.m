function BRDC_Grabber(doy,year,DB_Dir)

% this fucntion connects to EUREF FTP and download the BRDC file for the
% given day and it saves it in the brdc_dir

init_dir=pwd;

year=num2str(year);
doy=num2str(doy,'%03d');

Nav_Dir=[DB_Dir '/nav'];

if ~exist(Nav_Dir)
    mkdir(Nav_Dir)
end

if ~isempty(dir([Nav_Dir '/*' year doy '0000*.rnx']))
    return
end

aux_ftp=ftp('www.epncb.oma.be');
cd(aux_ftp,['pub/obs/BRDC/' year ]);
brdc2get=dir(aux_ftp);

for i=1:length(brdc2get)
    if contains(brdc2get(i).name,[year doy])
        mget(aux_ftp,brdc2get(i).name,Nav_Dir);
    end
end

close(aux_ftp)

Unzipper_Path=char(mlreportgen.utils.findFile('7za.exe'));
copyfile(Unzipper_Path,[ Nav_Dir '/7za.exe'])

to_unzip=dir([Nav_Dir '/*.gz']);

cd(Nav_Dir)

for i=1:length(to_unzip)
    [~,~]=system(['7za e ' to_unzip(i).folder '/' to_unzip(i).name]);
end

delete('*.gz')
delete('7za.exe')
cd(init_dir)

end

