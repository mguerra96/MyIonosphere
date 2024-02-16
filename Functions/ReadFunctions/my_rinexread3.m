function [obs , obs_header]=my_rinexread3(obs_file_dir)

obs=rinexread(obs_file_dir);
obs_header=rinexinfo(obs_file_dir);
obs_header.MarkerName=char(obs_header.MarkerName);
obs_header.MarkerName=obs_header.MarkerName(1:4);
obs_header.FirstObsTime=obs_header.FirstObsTime+minutes(1);

end