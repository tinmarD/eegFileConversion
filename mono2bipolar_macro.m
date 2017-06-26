function [EEG_bi] = mono2bipolar_macro(EEG_mono, varargin)
%MONO2BIPOLAIRE_MACRO transform a monopolar eeg signal into a bipolar eeg signal
% It also remove all the non eeg channels. 
% EEGLAB and ERPLAB are needed 
% 
% EEG_BI = MONO2BIPOLAR (EEG_MONO)
% INPUT 
%   - EEG_mono : EEG structure (from eeglab) of the monopolar file
%   - Optional inputs:
%           mono2bipolar_macro (EEG_mono,'badChannelNames',{'EEG C 8','EEG TB 2',...})
%           remove the specified channels.
%           mono2bipolar_macro (EEG_mono,'keepTriggers',1) will keep the last
%           channel named 'mkr2+' or 'trigger' if 1.
%
% OUTPUT
%   - EEG_bi   : EEG structure (from eeglab) of the bipolar file
%
% 1 - Remove the non eeg channels
% 2 - Keep the trigger channel if asked to
% 3 - Remove the bad channels
% 4 - Create the bipolar file with the remaining channels

p = inputParser;
defaultBadChannelNames      = '';     % Bad Channels to be removed
defaultKeepTriggers         = 0;      % Do you want to keep the triggers (channel mkr2+)

addOptional (p, 'badChannelNames', 	defaultBadChannelNames,     @iscell);
addOptional (p, 'keepTriggers',     defaultKeepTriggers,    @isnumeric);

parse (p,varargin{:});

% First remove non eeg channels :
nb_eeg_channels         = 0;
eegChannelPos        = zeros(1,EEG_mono.nbchan);
% Count the number of eeg channels
for i=1:EEG_mono.nbchan
    if strcmp(EEG_mono.chanlocs(i).labels(1:3), 'EEG')
        % If the channel is not a bad channel
        if sum(strcmp(EEG_mono.chanlocs(i).labels, p.Results.badChannelNames)) == 0
            nb_eeg_channels     = nb_eeg_channels + 1;
            eegChannelPos(nb_eeg_channels) = i;
        end
    end
end
eegChannelPos = nonzeros(eegChannelPos);
% If we want to keep trigger channel (mkr2+) - must be in last position
triggerchanfound = 0;
if p.Results.keepTriggers == 1 && (strcmpi(EEG_mono.chanlocs(EEG_mono.nbchan).labels, 'mkr2+') ...
                                       || strcmpi(EEG_mono.chanlocs(EEG_mono.nbchan).labels, 'trigger'))
    nb_eeg_channels     = nb_eeg_channels + 1;
    eegChannelPos(nb_eeg_channels) = i;
    disp ('found trigger channel');
    triggerchanfound = 1;
elseif p.Results.keepTriggers == 1
    disp ('Could not find the trigger channel - This channel must be named ''MKR2+'' (case insensitive) and must be in last position');
end

eegChannelPos = eegChannelPos(:);
nonEegChannelPos = find(ismember(1:EEG_mono.nbchan,eegChannelPos)==0);
if ~isempty(nonEegChannelPos)
    disp('Removing non eeg channels');
    disp({EEG_mono.chanlocs(nonEegChannelPos).labels});
end
    
if triggerchanfound
    % Keep only the eeg channels (and the trigger channel possibly)
    EEG_mono = pop_select (EEG_mono, 'channel', [eegChannelPos; EEG_mono.nbchan]);
else
    EEG_mono = pop_select (EEG_mono, 'channel', eegChannelPos);
end

% Display bad channel names and remove them :
disp (['Removing ',num2str(length(p.Results.badChannelNames)),' bad channels: ']);
for i=1:length(p.Results.badChannelNames)
    disp (p.Results.badChannelNames{i});
end
EEG_mono = pop_select (EEG_mono, 'nochannel', p.Results.badChannelNames);

channels_name       = cell(1,EEG_mono.nbchan);
electrodes_name     = cell(1,EEG_mono.nbchan);  
plot_number         = cell(1,EEG_mono.nbchan);  
new_channels_name   = {};
erplab_text_cmd     = {};
j                   = 1; % index of new channels
for i=1:EEG_mono.nbchan
    % Get the channel and electrode name
    % Remove all the whitespaces in channel name
    channels_name{i}    = cell2mat(regexp(EEG_mono.chanlocs(i).labels(4:end),'[a-zA-Z0-9'']*', 'match'));   
    if isempty (cell2mat(channels_name(i)));
        channels_name{i} = 'unknown';
    end
    electrodes_name{i}  = cell2mat(regexp(channels_name{i},'[A-Z'']*','match'));
    plot_number{i}      = cell2mat(regexp(channels_name{i},'[0-9]*','match'));
    % If we are on the same electrode
    if i>1 && strcmp(electrodes_name{i},electrodes_name{i-1})
        new_channels_name{j}    = ['EEG ',electrodes_name{i},plot_number{i-1},'-',electrodes_name{i},plot_number{i}];
        erplab_text_cmd{j}      = ['nch', num2str(j), ' = ch', num2str(i-1), ' - ch', num2str(i), ' label ', new_channels_name{j},char(10)];
        j = j+1;
    end
end
if triggerchanfound
	erplab_text_cmd{j}  = ['nch', num2str(j), ' = ch', num2str(EEG_mono.nbchan), ' label MKR2+',char(10)];
end
% The erplab command will look like this (if keepTriggers=1):
% nch1 = ch1 - ch2 label EEG A'1-A'2
% nch2 = ch2 - ch3 label EEG A'2-A'3
% nch3 = ch3 - ch4 label EEG A'3-A'4
% nch114 = ch124 - ch125 label EEG OR15-OR16
% nch115 = ch125 - ch126 label EEG OR16-OR17
% nch116 = ch136 label MKR2+


% Do the substraction between the contacts of each electrodes
EEG_bi = pop_eegchanoperator (EEG_mono, erplab_text_cmd);

EEG_bi = eeg_checkset (EEG_bi);

% % Maybe useful verification :
% for i=1:(EEG_bi.nbchan-triggerchanfound)
%     name_bipolar_channel    = EEG_bi.chanlocs(i).labels;
%     % From the bipolar channel name, find the corresponding monopolar
%     % channels indices
%     dash_ind                = regexp(name_bipolar_channel,'-');
%     name_mono_channel_1     = strtrim(name_bipolar_channel(5:dash_ind-1));
%     name_mono_channel_2     = strtrim(name_bipolar_channel(dash_ind+1:end));
%     % Find the indices
%     ind_mono_channel_1      = nonzeros(strcmp(name_mono_channel_1,channels_name).*(1:length(channels_name)));
%     ind_mono_channel_2      = nonzeros(strcmp(name_mono_channel_2,channels_name).*(1:length(channels_name)));
%     % Calcul the Mean Square Error between the bipolar channel and the
%     % difference between the 2 mono-channels
%     ch_mono_1               = EEG_mono.data(ind_mono_channel_1,:);
%     ch_mono_2               = EEG_mono.data(ind_mono_channel_2,:);
%     ch_mono_sub_2_1         = ch_mono_1 - ch_mono_2;
%     ch_bi_2_1               = EEG_bi.data(i,:);
%     mse = mean((ch_bi_2_1 - ch_mono_sub_2_1).^2);
%     % If the mean square error is different from 0, print it
%     if mse~= 0
%         disp(['Erreur quadratique moyenne pour ',name_bipolar_channel])
%         disp(mse);
%         disp(erplab_text_cmd{i});
%     end
% end

end
