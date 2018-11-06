function [] = CSCconv_writedatatoedf(data, srate, channames, out_dirpath, out_filename)
%CSCconv_writedatatoedf write the data matrix to an EDF file
%   First construct an EEGLAB structure, then write the EEGLAB dataset to
% an EDF file.
%
% INPUTS : 
%   - data          : Data matrix [n_chan * n_pnts]
%   - srate         : Sampling rate (Hz)
%   - channames     : channel names 
%   - out_dirpath   : Output directory
%   - out_filename  : Output filename

EEG = eeg_emptyset;
% Add the data and sampling rate info
EEG.data    = double (data);
EEG.srate   = srate;
EEG.nbchan  = length(channames);
% eeg_checkset will automatically fill some fields
EEG         = eeg_checkset (EEG);

% Fill the chanlocs information (electrode's label)
for i=1:length(channames)
    EEG.chanlocs(i).labels = ['EEG ',channames{i}];
end
EEG         = eeg_checkset (EEG);

% Save file
if ~isdir(out_dirpath)
    warning([out_dirpath,' does not exist. Creating it']);
    mkdir(out_dirpath);
end
pop_writeeeg (EEG,fullfile(out_dirpath, out_filename),'TYPE','EDF');


end

