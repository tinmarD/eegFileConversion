function [] = jediconv_syncanddividemacrofile(NS, EEG, macropathname, chunkduration, patientNum, ...
    dayNum, badChannelNames)
% [] = JEDICONV_SYNCANDDIVIDEMACROFILE (NS, EEG, macropathname, ...
%       chunkduration, patientNum, dayNum, badChannelNames)
%
% Used for synchronizing macro and micro files. The macro file is also
% divided into several parts. The synchronization is done by looking at the
% first trigger in both macro and micro file. In the macro file, the
% triggers should be in the last channel named 'MKR2+'. In the micro file,
% the triggers can be either in the NSX file, in the last channel with one
% of the following names {'ainp1','ainp','trigger','mkr2+','ainp2'}, or in
% the NEV file.
% If the macro file starts after the micro file, a blank signal is added at
% the beggining of the macro file. If the macro file starts before the
% micro one, the beggining of the macro file is cut. 
%
% INPUTS : 
%   - NS                : NSX micro file structure (Blackrock)
%   - EEG               : EEG macro file structure (EDF)
%   - macropathname     : macro file path name
%   - chunkduration     : chunk duration (s)
%   - patientNum        : patient number
%   - dayNum            : day number
%   - badChannelNames   : macro bad channel names. These channels will be
%   removed

%-------------------- SYNC part -----------------------------
TRIGGER_THRESHOLD_MACRO = 60;

%- Triggers in micro file 
[triggers_msec_single, ~, triggerFoundInData] = findtriggers_micro (NS);
tFirstTriggerMicro = triggers_msec_single(1);

%- Triggers in macro file 
if ~strcmpi(EEG.chanlocs(end).labels,'MKR2+')
    error ('The trigger channel must be the last one and named "mkr2+" (case insensitive)');
end
triggers_t_macro               = nonzeros (EEG.times (abs(EEG.data(end,:))>TRIGGER_THRESHOLD_MACRO));
if isempty(triggers_t_macro) 
    error ('Could not find any trigger in the macro file');
end
tFirstTriggerMacro   = triggers_t_macro(1);

% Visualize beginning of micro and macro trigger channels
if triggerFoundInData
    fsMicro         = NS.MetaTags.SamplingFreq;
    fsMacro         = EEG.srate;
    tVisuStart      = max(0,min(tFirstTriggerMacro,tFirstTriggerMicro)/1000-20);
    tVisuEnd        = min([EEG.xmax,NS.MetaTags.DataDurationSec,tVisuStart+60]);
    tVisuMicro      = tVisuStart:(1/fsMicro):tVisuEnd;
    tVisuMacro      = tVisuStart:(1/fsMacro):tVisuEnd;
    indVisuMicro    = 1+fix(tVisuMicro*fsMicro);
    indVisuMacro    = 1+fix(tVisuMacro*fsMacro);
    figure;
    ax(1) = subplot(211); plot(tVisuMicro,NS.Data(end,indVisuMicro)); title('micro trigger channel'); axis tight; xlabel('time (s)');
    ax(2) = subplot(212); plot(tVisuMacro,EEG.data(end,indVisuMacro)); title('Macro trigger channel');axis tight; xlabel('time (s)');
    linkaxes(ax,'x');
end

% Calcul the time difference 
delay = (tFirstTriggerMacro - tFirstTriggerMicro)/1000;
disp (['The delay between macro and micro signal is ',num2str(delay),' secondes']);
if delay<0
    delay = -delay;
    disp ('Macro start after micro recording, a blank signal will be add at the beggining of the macro file');
    EEG.data = [zeros(EEG.nbchan,round(1+delay*EEG.srate)),EEG.data];
    EEG.pnts = size(EEG.data(2));
    EEG.xmax = EEG.xmax+delay;
    EEG.times= linspace(0,EEG.xmax*1000,size(EEG.data,2));
    EEG      = eeg_checkset (EEG);
else
    % Remove the first part of the macro signal
    EEG = pop_select (EEG,'notime',[0 delay]);
end
%- P30 has some channels named 'EEG .....'  - remove them
if patientNum==30
    channelToRemove = find(strcmp({EEG.chanlocs.labels},'EEG .....')==1);
    if ~isempty(channelToRemove)
        disp(['P30 - Removing channels :', EEG.chanlocs(channelToRemove).labels]);
        EEG = pop_select (EEG,'nochannel',channelToRemove);    
    end
end

%- Remove bad channels
if exist('badChannelNames','var')
    notFoundPos = find(ismember(badChannelNames,{EEG.chanlocs.labels})==0);
    if ~isempty(notFoundPos)
        disp('Could not found some bad channels :');
        disp(badChannelNames(notFoundPos));
    end
    badChannelPos = find(ismember({EEG.chanlocs.labels},badChannelNames)==1);
    disp(['Removing bad channels : ',EEG.chanlocs(badChannelPos).labels]);
    EEG = pop_select(EEG,'nochannel',badChannelPos);
end

%- Remove non-eeg channels
nonEegChannelInd = regexp({EEG.chanlocs.labels},'EEG');
nonEegChannelInd = arrayfun(@(x)isempty(cell2mat(x)),nonEegChannelInd);
nonEegChannelPos = find(nonEegChannelInd==1);
nonEegChannelPos(nonEegChannelPos==EEG.nbchan) = [];
disp(['Removing ',num2str(length(nonEegChannelPos)),' non-eeg channels']);
disp({EEG.chanlocs(nonEegChannelPos).labels});
EEG = pop_select(EEG,'nochannel',nonEegChannelPos);

%- Remove duplicate channels
EEG = removeduplicatechannels(EEG);

%-------------------- DIVISION part -----------------------------
duration    = EEG.xmax;
nChunks     = ceil (duration/chunkduration);

filesepinds     = regexp (macropathname, filesep);
filesepind      = fastif (filesepinds(end)==length(macropathname),filesepinds(end-1),filesepinds(end));
outputdir       = fullfile (macropathname (1:filesepind),'monopolaire');
if ~isdir(outputdir)
    success = mkdir (outputdir);
    if ~success
        disp (['Could not create the directory ',outputdir]);
        return;
    end
end

for i=1:nChunks
    disp (['part ',num2str(i),'/',num2str(nChunks)]);
    tStart   = (i-1)*chunkduration;
    tEnd     = min(i*chunkduration,duration);
    % Read part i of the input signal
    EEG_part_i  = pop_select (EEG,'time',[tStart,tEnd]);
    % Export to .edf file
    output_name_i   = ['p',num2str(patientNum),'d',num2str(dayNum),'p',num2str(i),'_',num2str(tStart),'_',num2str(round(tEnd)),'s_',num2str(EEG.srate),'Hz_Macro_m.edf'];
    pop_writeeeg (EEG_part_i,fullfile(outputdir,output_name_i),'TYPE','EDF');
end


end

