% CSCdir_to_EDF_divide
% Given the directory containing all the CSC files and the Configuration
% Log file, convert the files to an EDF file

config_log_filepath = 'C:\Users\deudon\Desktop\Epifar\_Data\TestFiles\EB22-screening1_oddball1_NLX\ConfigurationLog\Micromed128csc8TT.log';
csc_dirpath = 'C:\Users\deudon\Desktop\Epifar\_Data\TestFiles\EB22-screening1_oddball1_NLX';
out_dirpath = 'C:\Users\deudon\Desktop\Epifar\_Data\TestFiles\NLX_EDF_divide';
srate = 32768; % Sampling rate
downsamplingFactorMacro = 16; % From 32768 Hz to 2048 Hz
downsamplingFactorMicro = 1

%% Make output directory
% Get csc directory name 
sep_pos = strfind(csc_dirpath, filesep);
if sep_pos(end) == length(csc_dirpath)
    csc_dir_name =  csc_dirpath(sep_pos(end-1)+1:end-1);
else
     csc_dir_name =  csc_dirpath(sep_pos(end)+1:end);
end
out_dirpath = fullfile(out_dirpath, csc_dir_name);
mkdir(out_dirpath);
%% Read config file
try
    fid = fopen(config_log_filepath, 'r');
catch err
    error(['Error oppening file ',config_log_filepath,'. ',err]);
end
if fid == -1
	error(['Could not open file ',config_log_filepath]);
end

% Get number of channels and channel names
n_chan = 0;
channames = {};
while 1
    line = fgetl(fid);
    if ~ischar(line), break, end
    if ~isempty(regexp(line,'^%ChanName'))
        n_chan = n_chan+1;
        channame_temp = cell2mat(regexp(line,'".+"','match'));
        channames{end+1} = channame_temp(2:end-1);
    end
end
fclose(fid)

% Find micro-electrode channels
macro_chan_ind = zeros(1, n_chan);
micro_chan_ind = zeros(1, n_chan);
for i = 1:n_chan
    channame_i = channames{i};
    if length(channame_i) > 1 && strcmp(channame_i(1:2), 'TT')
        micro_chan_ind(i) = 1;
    else
        macro_chan_ind(i) = 1;
    end
end
n_macro_chan = sum(macro_chan_ind);
n_micro_chan = sum(micro_chan_ind);
macro_chan_pos = find(macro_chan_ind);
micro_chan_pos = find(micro_chan_ind);
macro_channames = channames(macro_chan_pos);
micro_channames = channames(micro_chan_pos);

ncs_filelist = rdir(fullfile(csc_dirpath,'*.ncs'));
ncs_filename = {ncs_filelist.name};

disp(['Found ',num2str(n_macro_chan),' macro channels and ',num2str(n_micro_chan),' micro channels']);

%% CSC files (ncs file format)
readHeader = 1;
FieldSelectionFlags = [1, 1, 1, 1, 1];
ExtractMode = 1;

ADBitVolts_macro = zeros(n_macro_chan);
ADBitVolts_micro = zeros(n_micro_chan);

%% Find the number of files per channel and the number of samples 
% for each of theses files (Read the first channel - All channels should
% have the same number of files)
% TODO : Take only valid samples !!! Could create an offset ???
first_channame = channames{1};
files_first_chan = rdir(fullfile(csc_dirpath,[first_channame,'*.ncs']));
n_files_per_chan = length(files_first_chan);
n_samples_per_files = zeros(n_files_per_chan, 1);
for i = 1:n_files_per_chan
    [~, ~, ~, n_valid_samples, samples_mat_j, header] = Nlx2MatCSC...
        (files_first_chan(i).name, FieldSelectionFlags, readHeader, ExtractMode);
    n_samples_per_files(i) = numel(samples_mat_j);
    if i == n_files_per_chan && sum(n_valid_samples) == 0
        warning('No data in the last part of the files');
        n_files_per_chan = n_files_per_chan - 1;
        n_samples_per_files = n_samples_per_files(1:end-1);
    end
end
n_pnts_total = sum(n_samples_per_files);
disp(['Found ',num2str(n_files_per_chan),' files per channel']);

%% Macro channels 
% For each macro channels, try to read the NCS file based on the channame.
% We assume that the NCS files start with the name of the channel
disp('Macro channels');

ADBitVolts_all_macro = zeros(n_macro_chan, n_files_per_chan);


for i_file = 1:n_files_per_chan
    n_samples_per_files_i = n_samples_per_files(i_file);
    % Load the first channel and resample it to get the number of data
    % points once the signal is resampled.
    if i_file==1
        first_channame_i = [macro_channames{1},'.ncs'];
    else
        part_str = num2str(i_file-1);
        first_channame_i = [macro_channames{1},'_',repmat('0',1,4-length(part_str)),part_str,'.ncs'];
    end
    [~, ~, ~, n_valid_samples, samples_mat_first_chan, header] = Nlx2MatCSC...
        (fullfile(csc_dirpath,first_channame_i), FieldSelectionFlags, readHeader, ExtractMode);
    first_chan_sig = samples_mat_first_chan(:);
    % Decimate the first channel
    first_chan_sig_decimated = decimate(double(first_chan_sig),downsamplingFactorMacro);
    n_samples_per_files_i_decimated = length(first_chan_sig_decimated);
    data_macro_i_decimated = zeros(n_macro_chan, n_samples_per_files_i_decimated);
    disp(['|',blanks(round(n_macro_chan/3)-1),'|']);
    for i_chan = 1:n_macro_chan
        if i_chan==1 || i_chan==n_macro_chan
            fprintf('|');
            if i_chan==n_macro_chan, fprintf(char(10)); end;
        elseif rem(i_chan,3) == 0
            fprintf('.');
        end
        % Get the filename
        if i_file == 1
            filepath_ii = fullfile(csc_dirpath,[macro_channames{i_chan},'.ncs']);
        else
            part_str = num2str(i_file-1);
            filepath_ii = fullfile(csc_dirpath,[macro_channames{i_chan},'_',repmat('0',1,4-length(part_str)),part_str,'.ncs']);
        end
        if ~exist(filepath_ii,'file')
            error(['File ',filepath_ii,' does not exist']);
        end
        % Load the data
        [timestamps, ~, srates, ~, samples_mat_ii, header] = Nlx2MatCSC...
            (filepath_ii, FieldSelectionFlags, readHeader, ExtractMode);
        data_ii = samples_mat_ii(:);
        % Scale it 
        ADBitVolts_line = find(cellfun(@(x) ~isempty(x), regexp(header, 'ADBitVolts')));
        ADBitVolts_all_macro(i_chan, i_file) = str2double(header{ADBitVolts_line}(13:end));
        data_ii_scaled = data_ii .* ADBitVolts_all_macro(i_chan, i_file);
        % Decimate it
        data_macro_i_decimated(i_chan, :) = decimate(double(data_ii_scaled),downsamplingFactorMacro);
    end
    new_srate_macro = srate / downsamplingFactorMacro;
    if int32(new_srate_macro/1000)==new_srate_macro/1000
        new_srate_macro_str    = [num2str(new_srate_macro/1000),'kHz'];
    else
        new_srate_macro_str    = [num2str(new_srate_macro),'Hz'];
    end
    CSCconv_writedatatoedf(data_macro_i_decimated, new_srate_macro, macro_channames, out_dirpath, ['macro_part_',num2str(i_file),'_',new_srate_macro_str,'.edf']);
end
    


%% Micro channels
ADBitVolts_all_micro = zeros(n_micro_chan, n_files_per_chan);

disp('Micro channels');
for i_file = 1:n_files_per_chan
    n_samples_per_files_i = n_samples_per_files(i_file);
    % Load the first channel and resample it to get the number of data
    % points once the signal is resampled.
    if i_file==1
        first_channame_i = [micro_channames{1},'.ncs'];
    else
        part_str = num2str(i_file-1);
        first_channame_i = [micro_channames{1},'_',repmat('0',1,4-length(part_str)),part_str,'.ncs'];
    end
    [~, ~, ~, n_valid_samples, samples_mat_first_chan, header] = Nlx2MatCSC...
        (fullfile(csc_dirpath,first_channame_i), FieldSelectionFlags, readHeader, ExtractMode);
    first_chan_sig = samples_mat_first_chan(:);
    % Decimate the first channel
    first_chan_sig_decimated = decimate(double(first_chan_sig),downsamplingFactorMacro);
    n_samples_per_files_i_decimated = length(first_chan_sig_decimated);
    data_micro_i_decimated = zeros(n_micro_chan, n_samples_per_files_i_decimated);
    disp(['|',blanks(round(n_micro_chan/3)-1),'|']);
    for i_chan = 1:n_micro_chan
        if i_chan==1 || i_chan==n_micro_chan
            fprintf('|');
            if i_chan==n_micro_chan, fprintf(char(10)); end;
        elseif rem(i_chan,3) == 0
            fprintf('.');
        end
        % Get the filename
        if i_file == 1
            filepath_ii = fullfile(csc_dirpath,[micro_channames{i_chan},'.ncs']);
        else
            part_str = num2str(i_file-1);
            filepath_ii = fullfile(csc_dirpath,[micro_channames{i_chan},'_',repmat('0',1,4-length(part_str)),part_str,'.ncs']);
        end
        if ~exist(filepath_ii,'file')
            error(['File ',filepath_ii,' does not exist']);
        end
        % Load the data
        [timestamps, ~, srates, ~, samples_mat_ii, header] = Nlx2MatCSC...
            (filepath_ii, FieldSelectionFlags, readHeader, ExtractMode);
        data_ii = samples_mat_ii(:);
        % Scale it 
        ADBitVolts_line = find(cellfun(@(x) ~isempty(x), regexp(header, 'ADBitVolts')));
        ADBitVolts_all_micro(i_chan, i_file) = str2double(header{ADBitVolts_line}(13:end));
        data_ii_scaled = data_ii .* ADBitVolts_all_micro(i_chan, i_file);
        % Decimate it
        data_micro_i_decimated(i_chan, :) = decimate(double(data_ii_scaled),downsamplingFactorMacro);
    end
    new_srate_micro = srate / downsamplingFactorMicro;
    if int32(new_srate_micro/1000)==new_srate_micro/1000
        new_srate_micro_str    = [num2str(new_srate_micro/1000),'kHz'];
    else
        new_srate_micro_str    = [num2str(new_srate_micro),'Hz'];
    end
    CSCconv_writedatatoedf(data_micro_i_decimated, new_srate_micro, micro_channames, out_dirpath, ['micro_part_',num2str(i_file),'_',new_srate_micro_str,'.edf']);
end
    
