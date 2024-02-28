function [obs, obs_header]=MyRinexRead(obs_file)

%Function that identifies Rinex version and read obs files
% this functions also checks for read errors and modifies obs files to ensure that they are readable

obs_file_dir=[obs_file.folder '/' obs_file.name];

version=VersionFinder(obs_file_dir);

NumOfTries=1;

while NumOfTries<=3

try

    switch version(1)
        case '2'
            NumOfTries=4;
            [obs, obs_header]=my_rinexread2(obs_file_dir);
        case '3'
            [obs, obs_header]=my_rinexread3(obs_file_dir);
        case '4'
            fprintf('RINEX V4.xx Not yet supported\n')
        otherwise
            fprintf('RINEX Version not recognized!\n')
    end
     
    NumOfTries=4;

catch ME

    if strcmp(ME.identifier,'MATLAB:table:DuplicateVarNames')

        HandleDuplicateName(obs_file); % Try to fix the duplicate obs field 

    elseif strcmp(ME.identifier,'MATLAB:datetime:ParseErr')

        HandleWrongDatetime(obs_file); % Try to fix the wrong datetime format header field

    elseif strcmp(ME.identifier,'nav_positioning:rinexInternal:InvalidFileVersion')

        HandleVersionError(obs_file);   %try to fix rinex obs files with " at the beginning and end of each line of the file

    elseif strcmp(ME.identifier,'MATLAB:string:PositionOutOfRange')

        HandlePositionOutOfRangeError(obs_file);    % Remove the "PRN / # OF OBS" line from rinex to avoid the reading error

    elseif strcmp(ME.identifier,'MATLAB:UndefinedFunction')
        
        HandleUndefinedFunctionError(obs_file);     % Remove the "SYS / PHASE SHIFT" line from rinex to avoid the reading error

    end
    
    NumOfTries=NumOfTries+1;

end

end