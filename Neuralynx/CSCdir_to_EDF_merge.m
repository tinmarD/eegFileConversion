% CSCdir_to_EDF_merge
% Given the directory containing all the CSC files and the Configuration
% Log file, convert the files to an EDF file, merging all the channels
% together

config_log_filepath = 'C:\Users\deudon\Desktop\SpikeSorting\_Data\Neuralynx\EB22-screening1_oddball1_NLX\ConfigurationLog\Micromed128csc8TT.log';
csc_dirpath = 'C:\Users\deudon\Desktop\SpikeSorting\_Data\Neuralynx\EB22-screening1_oddball1_NLX';
out_dirpath = 'C:\Users\deudon\Desktop\SpikeSorting\_Data\Neuralynx\EDF_files\';
srate = 32768; % Sampling rate
% ADBitVolts_macro = 0.000000097656250000000005; % To be find in the header from the ncs files
% ADBitVolts_micro = 0.000000097656250000000005; % To be find in the header from the ncs files
downsamplingFactorMacro = 16; % From 32768 Hz to 2048 Hz

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
end
n_pnts_total = sum(n_samples_per_files);

%% Macro channels 
% For each macro channels, try to read the NCS file based on the channame.
% We assume that the NCS files start with the name of the channel
data_macro = zeros(n_macro_chan, n_pnts_total);
for i = 1:n_macro_chan
    channame_i = macro_channames{i};
    % Find all the ncs files that start with the channel name (should be
    % monopolar)
    channame_i_reg = regexprep(channame_i,'+','\\+');
    files_pos_i = find(cellfun(@(x)~isempty(x), regexp(ncs_filename,['\\',channame_i_reg,'[\._]'])));
    files_chan_i = ncs_filename(files_pos_i);
    n_files_i = length(files_chan_i);
    if n_files_i ~= n_files_per_chan
        error(['Channel ',channame_i,' has not the right number of files']);
    end
    data_i_scaled = cell(n_files_i, 1);
    ADBitVolts_i = zeros(n_files_i, 1);
    for j = 1:n_files_i
        [timestamps, ~, srates, ~, samples_mat_j, header] = Nlx2MatCSC...
            (files_chan_i{j}, FieldSelectionFlags, readHeader, ExtractMode);
        ADBitVolts_line = find(cellfun(@(x) ~isempty(x), regexp(header, 'ADBitVolts')));
        ADBitVolts_i_j = str2double(header{ADBitVolts_line}(13:end));
        data_i_scaled{j} = samples_mat_j(:) .* ADBitVolts_i_j .* 1E6;
        ADBitVolts_i(j) = ADBitVolts_i_j;
    end
    if length(unique(ADBitVolts_i)) > 1
        warning(['ADBitVolts is differents for the different files of channel ',macro_channames{i}]);
    end
    % Add new value of ADBitVolts_i_j (for reporting)
    ADBitVolts_macro(i) = ADBitVolts_i_j;
    % stack the data and scale it given the value of ADBitVolts
    % We multiply by 1E6 to get the amplitude in uV
    data_i_row = vertcat(data_i_scaled{:});
    data_macro(i, :) = data_i_row ;
end

% Decimate the macro data
disp ('Decimating Macro data...');
temp_var                = decimate(data_macro(1,:), downsamplingFactorMacro);
data_macro_decimated    = zeros(n_macro_chan,size(temp_var,2));
for i=1:n_macro_chan
    data_macro_decimated (i,:) = decimate(double(data_macro(i,:)),downsamplingFactorMacro);
    fprintf ('.')
end
new_srate   = srate / downsamplingFactorMacro;
disp ('  Done');
disp (['The new sampling frequency is now ', num2str(new_srate), ' Hz']);

CSCconv_writedatatoedf(data_macro_decimated, new_srate, macro_channames, out_dirpath, 'macro_edf_file_2.edf');

%% Micro channels 
% For each micro channels, try to read the NCS file based on the channame.
% We assume that the NCS files start with the name of the channel
data_micro = zeros(n_micro_chan, n_pnts_total);
for i = 1:n_micro_chan
    channame_i = micro_channames{i};
    % Find all the ncs files that start with the channel name (should be
    % monopolar)
    channame_i_reg = regexprep(channame_i,'+','\\+');
    files_pos_i = find(cellfun(@(x)~isempty(x), regexp(ncs_filename,['\\',channame_i_reg,'[\._]'])));
    files_chan_i = ncs_filename(files_pos_i);
    n_files_i = length(files_chan_i);
    if n_files_i ~= n_files_per_chan
        error(['Channel ',channame_i,' has not the right number of files']);
    end
    data_i_scaled = cell(n_files_i, 1);
    ADBitVolts_i = zeros(n_files_i, 1);
    for j = 1:n_files_i
        [timestamps, ~, srates, ~, samples_mat_j, header] = Nlx2MatCSC...
            (files_chan_i{j}, FieldSelectionFlags, readHeader, ExtractMode);
        ADBitVolts_line = find(cellfun(@(x) ~isempty(x), regexp(header, 'ADBitVolts')));
        ADBitVolts_i_j = str2double(header{ADBitVolts_line}(13:end));
        data_i_scaled{j} = samples_mat_j(:) .* ADBitVolts_i_j .* 1E6;
        ADBitVolts_i(j) = ADBitVolts_i_j;
    end
    if length(unique(ADBitVolts_i)) > 1
        warning(['ADBitVolts is differents for the different files of channel ',micro_channames{i}]);
    end
    % Add new value of ADBitVolts_i_j (for reporting)
    ADBitVolts_micro(i) = ADBitVolts_i_j;
    % stack the data and scale it given the value of ADBitVolts
    % We multiply by 1E6 to get the amplitude in uV
    data_i_row = vertcat(data_i_scaled{:});
    data_micro(i, :) = data_i_row ;
end

CSCconv_writedatatoedf(data_micro, srate, micro_channames, out_dirpath, 'micro_edf_file.edf');


