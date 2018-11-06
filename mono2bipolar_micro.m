function [EEG_bi] = mono2bipolar_micro(EEG_mono, patientNum, varargin)
%MONO2BIPOLAIRE transform a monopolar signal into a bipolar signal
% It also remove all the non eeg channels. 
% EEGLAB and ERPLAB are needed 
% 
% EEG_BI = MONO2BIPOLAR (EEG_MONO, patient_nb)
% INPUT 
%   - EEG_mono : EEG structure (from eeglab) of the monopolar file
%   - patientNum : Patient number
%   - Optional inputs:
%           mono2bipolar_micro(..., 'badChannelNames', {'EEG C 8', 'EEG TB 2', ...})
%           remove the specified channels.
%           mono2bipolar_micro (..., 'keepTriggers', 1) will keep the last
%           channel named 'mkr2+' or 'trigger' if 1.
%
% OUTPUT
%   - EEG_bi   : EEG structure (from eeglab) of the bipolar file
%
% 1 - Remove the non eeg channels
% 2 - Keep the trigger channel if asked to
% 3 - Remove the bad channels
% 4 - Create the bipolar file with the remaining channels

%_______________________ Optional inputs _________________________
p = inputParser;
defaultBadChannelNames  = '';     % Bad Channels to be removed
defaultKeepTriggers     = 0;      % Do you want to keep the triggers (channel mkr2+)
defaultAverageMontage   = 0;      % If 1 use the common average montage

addOptional (p, 'badChannelNames',  defaultBadChannelNames, @iscell);
addOptional (p, 'keepTriggers',     defaultKeepTriggers,    @isnumeric);
addOptional (p, 'averageMontage',   defaultAverageMontage,  @isnumeric);

parse (p,varargin{:});
%__________________________________________________________________


% First remove non eeg channels :
nEegChan        = 0;
eegChanInd      = zeros(1,EEG_mono.nbchan);
% Count the number of eeg channels
for i=1:EEG_mono.nbchan
    if strcmp(EEG_mono.chanlocs(i).labels(1:3), 'EEG')
        % If the channel is not a bad channel
        if sum(strcmp(EEG_mono.chanlocs(i).labels, p.Results.badChannelNames)) == 0
            nEegChan     = nEegChan + 1;
            eegChanInd(nEegChan) = i;
        end
    end
end
eegChanInd = nonzeros(eegChanInd);
% If we want to keep trigger channel (mkr2+ or trigger) - must be in last position
triggerChanFound = 0;
if p.Results.keepTriggers == 1 && (strcmpi(EEG_mono.chanlocs(EEG_mono.nbchan).labels, 'mkr2+') ...
                                       || strcmpi(EEG_mono.chanlocs(EEG_mono.nbchan).labels, 'trigger'))
    nEegChan                = nEegChan+1;
    eegChanInd(nEegChan)    = i;
    disp ('found trigger channel');
    triggerChanFound        = 1;
elseif p.Results.keepTriggers == 1
    disp ('Could not find the trigger channel - This channel must be named ''MKR2+'' or ''trigger'' (case insensitive) and must be in last position');
end

eegChanInd = eegChanInd(:);
if triggerChanFound
    % Keep only the good eeg channels (and the trigger channel if asked to)
    EEG_mono = pop_select (EEG_mono,'channel',[eegChanInd; EEG_mono.nbchan]);
else
    EEG_mono = pop_select (EEG_mono,'channel',eegChanInd);
end
% Display the bad channel names
disp (['Removing ',num2str(length(p.Results.badChannelNames)),' bad channels: ']);
for i=1:length(p.Results.badChannelNames)
    disp (p.Results.badChannelNames{i});
end


%________________ Create the erplab command string  ___________________
% channels_name       = cell(1,EEG_mono.nbchan);
% electrodes_name     = cell(1,EEG_mono.nbchan);  
% plot_number         = cell(1,EEG_mono.nbchan);  
% new_channels_name   = {};
% erplab_text_cmd     = {};
% j                   = 1; % index of new channels

% The erplab command will look like this (if keepTriggers=1 and for bipolar montage):
%   nch1 = ch1 - ch2 label EEG A'1-A'2
%   nch2 = ch2 - ch3 label EEG A'2-A'3
%   nch3 = ch3 - ch4 label EEG A'3-A'4
%   nch114 = ch124 - ch125 label EEG OR15-OR16
%   nch115 = ch125 - ch126 label EEG OR16-OR17
%   nch116 = ch136 label MKR2+
% For Average Reference montage (where N_EEG_CHAN is the number of the last eeg channel:
%   nch1 = ch1 - avgchan(1:N_EEG_CHAN) label EEG A'1-avgref
%   nch2 = ch2 - avgchan(1:N_EEG_CHAN) label EEG A'2-avgref

% For micro/macro electrode:
% A micro-electrode is composed of 3 tetrode 
% Each tetrode has 4 recording plots
% Thus each micro-electrode records 12 signals

switch patientNum
    case 30 %P30
        microNames              = {'h','op','a','or'''};  
        nChanPerMicro           = [12,12,12,12];
%         bipolar_montage         = { [1,2;2,3;3,4;4,1;5,6;6,7;7,8;8,5;9,10;10,11;11,12;12,9],...
%                                     [1,2;2,3;3,4;4,1;5,6;6,7;7,8;8,5;9,10;10,11;11,12;12,9],...
%                                     [1,2;2,3;3,4;4,1;5,6;6,7;7,8;8,5;9,10;10,11;11,12;12,9],...
%                                     [1,2;2,3;3,4;4,1;5,6;6,7;7,8;8,5;9,10;10,11;11,12;12,9]}; % intra-tetrode
        bipolarMontage          = { [1,5;2,6;3,7;4,8;1,9;2,10;3,11;4,12;5,9;6,10;7,11;8,12],...
                                    [1,5;2,6;3,7;4,8;1,9;2,10;3,11;4,12;5,9;6,10;7,11;8,12],...  
                                    [1,5;2,6;3,7;4,8;1,9;2,10;3,11;4,12;5,9;6,10;7,11;8,12],...  
                                    [1,5;2,6;3,7;4,8;1,9;2,10;3,11;4,12;5,9;6,10;7,11;8,12]};   % tetrode-tetrode
    case 31 % P31
        microNames              = {'a','tb','b'}; 
        nChanPerMicro           = [12,8,8];
        bipolarMontage          = {[1,5;2,6;3,7;4,8;5,9;6,10;7,11;8,12;1,9;2,10;3,11;4,12],...
                                    [ 1,5;2,6;3,7;4,8],...
                                    [ 1,5;2,6;3,7;4,8]};
                                
    case 32 % P32
        microNames              = {'fd','cr','tp'}; 
        nChanPerMicro           = [12,12,8];
        bipolarMontage          = {[ 1,5;2,6;3,7;4,8;5,9;6,10;7,11;8,12;1,9;2,10;3,11;4,12],...
                                   [ 1,5;2,5;3,5;4,5;5,1;6,1;7,1;8,1;9,6;10,6;11,6;12,6],...
                                   [ 1,7;2,7;3,7;4,7;5,3;6,3;7,3;8,3]}; 
    case 33 % P33
        microNames              = {'b''','c''','b'}; 
        nChanPerMicro           = [8,8,8];
        bipolarMontage          = { [ 1,5;2,6;3,7;4,8],...
                                    [ 1,5;2,6;3,7;4,8],...
                                    [ 1,5;2,6;3,7;4,8]};
                                
    case 34 % P34
        microNames              = {'b','tb','b'''}; 
        nChanPerMicro           = [12,8,12];
        bipolarMontage          = {[ 1,5;2,6;3,7;4,8;5,9;6,10;7,11;8,12;1,9;2,10;3,11;4,12],...
                                   [ 1,5;2,6;3,7;4,8],...
                                   [ 1,5;2,6;3,7;4,8;5,9;6,10;7,11;8,12;1,9;2,10;3,11;4,12]};
                               
    case 35 % P35
        microNames              = {'b','a'''};
        nChanPerMicro           = [8,8];
        bipolarMontage          = { [1,5;2,6;3,7;4,8],...
                                    [1,5;2,6;3,7;4,8]};
        
    case 36 % P36
        microNames              = {'crp','fdp','tpp','cc'};
        nChanPerMicro           = [12,8,8,8];
        bipolarMontage          = { [1,5;2,6;3,7;4,8;5,9;6,10;7,11;8,12;1,9;2,10;3,11;4,12],...
                                    [1,5;2,6;3,7;4,8],...
                                    [1,5;2,6;3,7;4,8],...
                                    [1,5;2,6;3,7;4,8]};
                                
    otherwise
        warning(['Unknown montage for patient ',num2str(patientNum),'. Cannot continue.']);
        return;       
                               
end

% conv_file               = '';
erplabTxtCommand        = {};
% n_eeg_channels          = length(micro_names)*n_channel_per_micro;



%- Bipolar Montage
if ~p.Results.averageMontage
    for k=1:length(microNames)
        montageLength_k(k)     = size(bipolarMontage{k},1);
        if k==1; 
            channel_per_micro_past=0; 
        else
            channel_per_micro_past=sum(nChanPerMicro(1:k-1));
        end
        for i=1:montageLength_k(k)
            nch = fastif (isempty(erplabTxtCommand),1,length(erplabTxtCommand)+1);
            erplabTxtCommand{nch} = ['nch',num2str(nch),' = ch', num2str(channel_per_micro_past+bipolarMontage{k}(i,1)),' - ch',num2str(channel_per_micro_past+bipolarMontage{k}(i,2)),' label EEG ',cell2mat(microNames(k)), num2str(bipolarMontage{k}(i,1)),'-',cell2mat(microNames(k)), num2str(bipolarMontage{k}(i,2))];
        end
    end
    montage_length = sum(montageLength_k);
    if EEG_mono.nbchan == sum(nChanPerMicro)+1
        erplabTxtCommand{end+1} = ['nch',num2str(length(erplabTxtCommand)+1),' = ch', num2str(sum(nChanPerMicro)+1),' label MKR2+'];
    end
%- Average Reference Montage
else
    nChanPerMicro     = 12;
    nEegChan          = nChanPerMicro*length(microNames);
    for k=1:length(microNames)
        for i=1:nChanPerMicro
            erplabTxtCommand{(k-1)*nChanPerMicro+i} = ['nch',num2str((k-1)*nChanPerMicro+i),' = ch', num2str((k-1)*nChanPerMicro+i),' - avgchan(1:',num2str(nEegChan),') label EEG ',cell2mat(microNames(k)), num2str(i),'-avgref'];
        end
    end
    erplabTxtCommand{nChanPerMicro*length(microNames)+1} = ['nch',num2str(nChanPerMicro*length(microNames)+1),' = ch', num2str(12*length(microNames)+1),' label MKR2+'];
end
% Display the montage (monopolaire to bipolaire)
for k=1:length(erplabTxtCommand)
    disp (erplabTxtCommand{k});
end

% Do the substraction between the contacts of each electrodes using ErpLab
EEG_bi = pop_eegchanoperator (EEG_mono, erplabTxtCommand);
%______________________________________________________________________


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
