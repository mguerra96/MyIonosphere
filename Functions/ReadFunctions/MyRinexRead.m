function [obs, obs_header]=MyRinexRead(obs_file_dir)

version=VersionFinder(obs_file_dir);

switch version(1)
    case '2'
        [obs, obs_header]=my_rinexread2(obs_file_dir);
    case '3'
        [obs, obs_header]=my_rinexread3(obs_file_dir);
    case '4'
        fprintf('RINEX V4.xx Not yet supported\n')
    otherwise
        fprintf('RINEX Version not recognized!\n')
end