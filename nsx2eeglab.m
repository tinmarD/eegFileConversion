function EEG = nsx2eeglab(NS, downsamplingFactor, addTriggerChannel)
% EEG = NSXTOEEGLAB (NS, downsamplingFactor, addTriggerMicro)
% Convert a NSx file (Blackrock format for continuously sampled information
% LFPs) to an EEGLAB dataset
%
% INPUTS :
%   - NS                    : Blackrock NSx structure
%   - downsamplingFactor    : Downsampling factor (default 6)
%   - addTriggerChannel     : If 1, will try to add a trigger channel in
%                             the micro .edf file (default 1)
%
% OUTPUTS:
%   - EEG                   : Corresponding EEGLAB structure
%
% 
% Procedure : 
%   1/ Decimate the data by a factor downsamplingFactor 
%   2/ Divide the amplitude by 4 to get an amplitude in µV
%   3/ Create an empty EEGLAB structure and fill the structure with the data
% and channels information.
%
%
% Author(s) : Martin Deudon (Juin 2017)

if nargin==1
    downsamplingFactor  = 6;
    addTriggerChannel 	= 1;
elseif nargin==2
    addTriggerChannel 	= 1;
end

%% Trigger micro parameters
triggerChanName     = 'trigger';
triggerMicroVal     = 20000;
microTrigDuration   = 0.005; % sec
%% 


% Get the NS data and divide the amplitude by 4 (to get an amplitude in µV)
if iscell(NS.Data)
    error('The NS file data is composed of 2 parts. Use the NPKM scripts to fix this');
end    
NS_Data = double(NS.Data/4);
disp ('Amplitude divided by 4');

nchan = size(NS_Data,1);

% Decimate the data
if downsamplingFactor ~= 1
    disp ('Decimating data...');
    temp_var        = decimate (NS_Data(1,:), downsamplingFactor);
    data_decimated  = zeros (nchan,size(temp_var,2));
    for i=1:nchan
        data_decimated (i,:) = decimate (double(NS_Data(i,:)),downsamplingFactor);
        fprintf ('.')
    end
    new_srate   = NS.MetaTags.SamplingFreq/downsamplingFactor;
    disp ('  Done');
    disp (['The new sampling frequency is now ', num2str(new_srate), ' Hz']);
else
    new_srate = NS.MetaTags.SamplingFreq;
    data_decimated = NS_Data;
    disp (['Sampling frequency is ', num2str(new_srate), ' Hz']);
end

% 50 Hz notch filter : 
% freqRatio   = 50/(new_srate/2);     % Ratio of notch freq. to Nyquist freq.
% notchWidth  = 0.025;                 % Width of the notch
% Compute zeros and poles
% h_zeros   = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )];
% h_poles   = (1-notchWidth) * h_zeros;
% b_notch = poly( h_zeros ); % Get moving average filter coefficients
% a_notch = poly( h_poles ); % Get autoregressive filter coefficients
% % freqz (b_notch,a_notch,1000);
% disp ('Notch filter applied on :');
% for i=channels_to_notch_filter_ind
%     data (i,:) = filter (b_notch,a_notch,data(i,:));
%     disp (NS.ElectrodesInfo(i).Label);
% end


% Create an empty eeglab structure
EEG         = eeg_emptyset;
% Add the data and sampling rate info
EEG.data    = double (data_decimated);
EEG.srate   = new_srate;
EEG.nbchan  = size(data_decimated,1);
% eeg_checkset will automatically fill some fields
EEG         = eeg_checkset (EEG);

% Fill the chanlocs information (electrode's label)
for i=1:EEG.nbchan
    channel_name = strtrim(NS.ElectrodesInfo(i).Label);
    if ~isempty(regexpi (channel_name,'trigger')) || ~isempty(regexpi (channel_name,'ainp1'))
        EEG.chanlocs(i).labels = triggerChanName;
    else
        EEG.chanlocs(i).labels = ['EEG ',channel_name];
    end
end

if addTriggerChannel
    [triggers_msec_single, ~, triggerFoundInData] = ...
        findtriggers_micro (NS);
    if triggerFoundInData
        disp('Micro-file triggers were found in the data structure NSx. No need to add a trigger channel');
    elseif ~isempty(triggers_msec_single)
        disp('Creating a new trigger channel from trigger times, adding it to the EEGLAB structure');
        microTrigSamples    = round(microTrigDuration*new_srate);
        triggerPos          = 1+fix(triggers_msec_single/1000*new_srate);
        triggerChan         = zeros(1,EEG.pnts);
        for i=1:length(triggerPos)
            triggerChan(triggerPos(i):min(EEG.pnts,triggerPos(i)+microTrigSamples)) = triggerMicroVal;
        end
        %- if the EEG structure already contain a trigger channel (a bad
        % one, replace the data)
        if strcmp(EEG.chanlocs(end).labels,triggerChanName)
            EEG.data(end,:)     = triggerChan;
        else
            EEG.data(end+1,:)   = triggerChan;
        end
    end
end


EEG         = eeg_checkset (EEG);

end

