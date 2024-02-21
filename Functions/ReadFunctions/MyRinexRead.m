function [obs, obs_header]=MyRinexRead(obs_file)

obs_file_dir=[obs_file.folder '\' obs_file.name];

version=VersionFinder(obs_file_dir);

try

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

catch ME

    if strcmp(ME.identifier,'MATLAB:table:DuplicateVarNames')

        HandleDuplicateName(obs_file); % Try to fix the duplicate obs field and reread the file

    elseif strcmp(ME.identifier,'MATLAB:datetime:ParseErr')

        HandleWrongDatetime(obs_file); % Try to fix the wrong datetime format header field and reread the file

    elseif strcmp(ME.identifier,'nav_positioning:rinexInternal:InvalidFileVersion')

        HandleVersionError(obs_file);

    elseif strcmp(ME.identifier,'MATLAB:string:PositionOutOfRange')

        HandlePositionOutOfRangeError(obs_file);

    elseif strcmp(ME.identifier,'MATLAB:UndefinedFunction')
        
        HandleUndefinedFunctionError(obs_file);

    end

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

end

end