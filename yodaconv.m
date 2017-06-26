% 
% % EpiFar Conversion Level 2
% 
% % Do the conversion, (see jediconv), in the case where micro-electrode
% % signal is discontinued and composed of several parts. 
% % The macro-electrode signal must be complete



%% - Parameters
chunkduration       = 600;  % secondes
downsamplingFactor  = 6;    % from 30kHz to 5kHz
patientNum          = 31;
macroBadChannelNames= {''};
% macroBadChannelNames= {'EEG OP2'};
dayNumMicro         = [];
dayNumMacro         = [];


%% - Inputs
[micro_ns5_dirname]                 = uigetdir   ('C:\Users\deudon\Desktop\EPIFAR','Select micro-electrode directory');
[macro_filename, macro_pathname]    = uigetfile ('*.edf','Select Macro-electrode file');

if isnumeric(micro_ns5_dirname) || isnumeric(macro_filename) || isnumeric(macro_pathname)
    return;
end

dirstruct           = rdir(fullfile(micro_ns5_dirname,'*.ns5'));
microNS5filenames   = {dirstruct.name};

nMicroParts       = length(microNS5filenames);
if nMicroParts < 2
    error ('Chameleon - Use the Jedi Version');
end

%- Check day of recording for micro and Macro 
try
    dayNumMicro = regexp(micro_ns5_pathname,'[dD][aA][yY]\d','match','once');
    dayNumMicro = num2str(cell2mat(regexp(dayNumMicro,'\d*','match')));
end
try
    dayNumMacro = regexp(macro_pathname,'[dD][aA][yY]\d','match','once');
    dayNumMacro = num2str(cell2mat(regexp(dayNumMacro,'\d*','match')));
end

try
    EEG = pop_biosig   (fullfile(macro_pathname,macro_filename));
catch
    disp (['Could not load the macro-electrode file ',fullfile(macro_pathname,macro_filename)]);
    return;
end

if isempty(regexp(microNS5filenames{1},'001','once'))
    error ('The first part is not the first in the file list?');
end
try
    NS_firstpart = openNSx (microNS5filenames{1});
catch
    disp (['Could not load the micro-electrode file ',microNS5filenames{1}]);
    return;
end
NS_parts    = cell(1,nMicroParts);
NS_parts{1} = NS_firstpart;
for i=2:nMicroParts
    if isempty(regexp(microNS5filenames{i},['-00',num2str(i)],'once'))
        error ('Could not detect the order of the micro-electrodes files');
    end
    try
        NS_parts {i} = openNSx (microNS5filenames{i});
    catch
        disp (['Could not load the micro-electrode file ',microNS5filenames{1}]);
        return;
    end
end

%- write a small part a macro file to check for bad channels
EEGpart0 = pop_select(EEG,'time',[0,300]);
pop_writeeeg(EEGpart0,'C:\Users\deudon\Desktop\eegpart0.edf','TYPE','EDF');


%% - Get the time of the first trigger
TRIGGER_THRESHOLD_MICRO = 10000;
TRIGGER_THRESHOLD_MACRO = 1000;

triggers_chan_micro     = abs(NS_firstpart.Data(end,:));
triggers_ind_micro      = nonzeros((triggers_chan_micro>TRIGGER_THRESHOLD_MICRO).*(1:length(triggers_chan_micro)));
if isempty(triggers_ind_micro); 
    error('Could not find trigger in the micro file - If there is no trigger, you can delete this file and restart - If only 1 file left, use jediconv'); 
end
t_first_trigger_micro   = 1000*(triggers_ind_micro(1)-1)/NS_firstpart.MetaTags.SamplingFreq; % in ms

if ~strcmpi(EEG.chanlocs(end).labels,'MKR2+')
    error ('The trigger channel must be the last one and named "mkr2+" (case insensitive)');
end

triggers_t_macro               = nonzeros (EEG.times (abs(EEG.data(end,:))>TRIGGER_THRESHOLD_MACRO));
if isempty(triggers_t_macro) 
    error ('Could not find any trigger in the macro file');
end
t_first_trigger_macro   = triggers_t_macro(1);

% Calcul the time difference 
delay = (t_first_trigger_macro - t_first_trigger_micro)/1000;
disp (['The delay between macro and micro signal is ',num2str(delay),' secondes']);
if delay<0
    error ('Micro file starts before macro file');
end

% Get absolute starting time of micro file = number of seconds elapsed
% since midnight (micro_absstartime) and duration of each micro file
micro_absstarttimes = zeros(1,nMicroParts);
micro_durations     = zeros(1,nMicroParts);
for i=1:nMicroParts
    micro_datetimeraw       = NS_parts{i}.MetaTags.DateTimeRaw;
    micro_absstarttimes(i)  = micro_datetimeraw(5)*3600+micro_datetimeraw(6)*60+...
        micro_datetimeraw(7)+micro_datetimeraw(8)/1000;
    micro_durations(i)      = NS_parts{i}.MetaTags.DataDurationSec;
end
% Absolute time of first trigger
t_first_trigger_abs = micro_absstarttimes(1) + t_first_trigger_micro/1000;
% Absolute starting time of macro file
macro_absstarttime  = t_first_trigger_abs - t_first_trigger_macro/1000;

% Now, get the starting time of the micro-files in the macro-file temporal
% referentiel
macro_microstarttimes = zeros(1,nMicroParts);
for i=1:nMicroParts
    macro_microstarttimes(i) = micro_absstarttimes(i) - macro_absstarttime;
end



%% Output directories creation
% Macro
filesepinds     = regexp (macro_pathname, filesep);
filesepind      = fastif (filesepinds(end)==length(macro_pathname),filesepinds(end-1),filesepinds(end));
macro_outputdir = fullfile (macro_pathname (1:filesepind),'monopolaire');
if ~isdir(macro_outputdir)
    success = mkdir (macro_outputdir);
    if ~success
        disp (['Could not create the directory ',macro_outputdir]);
        return;
    end
end

% micro
filesepinds     = regexp (micro_ns5_dirname, filesep);
filesepind      = fastif (filesepinds(end)==length(micro_ns5_dirname),filesepinds(end-1),filesepinds(end));
micro_outputdir = fullfile (micro_ns5_dirname (1:filesepind),'monopolaire');
if ~isdir(micro_outputdir)
    success = mkdir (micro_outputdir);
    if ~success
        disp (['Could not create the directory ',micro_outputdir]);
        return;
    end
end

% micro at 30 kHz
filesepinds         = regexp (micro_ns5_dirname, filesep);
filesepind          = fastif (filesepinds(end)==length(micro_ns5_dirname),filesepinds(end-1),filesepinds(end));
micro_outputdir_30k = fullfile (micro_ns5_dirname (1:filesepind),'monopolaire_30kHz');
if ~isdir(micro_outputdir_30k)
    success = mkdir (micro_outputdir_30k);
    if ~success
        disp (['Could not create the directory ',micro_outputdir_30k]);
        return;
    end
end

micro_filename  = microNS5filenames{1};
filesepinds     = regexp (micro_filename, filesep);
filesepind      = fastif (filesepinds(end)==length(micro_filename),filesepinds(end-1),filesepinds(end));
micro_filename  = micro_filename(filesepind+1:end);
micro_filename  = micro_filename(1:end-8);

n_subparts = zeros(1,nMicroParts);
for i=1:nMicroParts
    n_subparts(i) = ceil(micro_durations(i)/chunkduration);
end


%% Macro cleaning
%- P30 has some channels named 'EEG .....'  - remove them
if patientNum==30
    channelToRemove = find(strcmp({EEG.chanlocs.labels},'EEG .....')==1);
    if ~isempty(channelToRemove)
        disp(['P30 - Removing channels :', EEG.chanlocs(channelToRemove).labels]);
        EEG = pop_select (EEG,'nochannel',channelToRemove);    
    end
end

%- Remove bad channels
if exist('macroBadChannelNames','var')
    notFoundPos = find(ismember(macroBadChannelNames,{EEG.chanlocs.labels})==0);
    if ~isempty(notFoundPos)
        disp('Could not found some bad channels :');
        disp(macroBadChannelNames(notFoundPos));
    end
    badChannelPos = find(ismember({EEG.chanlocs.labels},macroBadChannelNames)==1);
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


%% Write monopolar files (micro and Macro)
EEGparts    = cell(1,sum(n_subparts));
FsMicro   	= NS_firstpart.MetaTags.SamplingFreq;
FsOutMicro 	= FsMicro/downsamplingFactor;
if int32(FsOutMicro/1000)==FsOutMicro/1000
    FsOutStr = [num2str(FsOutMicro/1000),'kHz'];
else
    FsOutStr = [num2str(FsOutMicro),'Hz'];
end

for i=1:nMicroParts
    for j=1:n_subparts(i)
        if i==1
            part_ind = j;
        else
            part_ind = sum(n_subparts(1:i-1))+j;
        end

        % Macro
        tStart = macro_microstarttimes(i)+(j-1)*chunkduration;
        tEnd   = macro_microstarttimes(i)+j*chunkduration;
        tEnd   = min(tEnd,macro_microstarttimes(i)+micro_durations(i));
        disp (['Part ',num2str(part_ind),' : [',num2str(tStart),'s - ',num2str(tEnd),'s]']);
        EEGparts{part_ind} = pop_select (EEG,'time',[tStart tEnd]);
        
        % micro
        tStartMicro       = (j-1)*chunkduration;
        tEndMacro         = min(j*chunkduration,micro_durations(i));
        NS_part_i         = openNSx (microNS5filenames{i},'precision','double',['t:',num2str(tStartMicro),':',num2str(tEndMacro)],'sec');   
        % Get corresponding EEGLAB structure
        EEG_micro_part_i    = jediconv_NSxToEeglab (NS_part_i, downsamplingFactor);
        EEG_micro_part_i_30k= jediconv_NSxToEeglab (NS_part_i, 1);
        
        % See if there is still a delay between micro and macro signals
        if i==1 && j==1
            sigdelay = 0;
        else            
            sigdelay = yodaconv_getsignalsdelay(NS_part_i,EEGparts{part_ind},1);
            if isempty(sigdelay); continue; end;
        end
        if patientNum==31 && dayNumMacro==1 && i==2
            sigdelay = -25.2882;
        end
        disp(['The delay between macro and micro signal is ',num2str(sigdelay),' secondes']);
        if sigdelay>0 % macro signal is late, cut the start of macro signal
            EEGparts{part_ind} = pop_select (EEGparts{part_ind},'notime',[0,sigdelay]);
        elseif sigdelay<0 % macro signal is early
            EEG_micro_part_i    = pop_select (EEG_micro_part_i,'notime',[0,-sigdelay]);
            EEG_micro_part_i_30k= pop_select (EEG_micro_part_i_30k,'notime',[0,-sigdelay]);
        end
        
        % Write files
        macroOutputNamei  	= ['p',num2str(patientNum),'d',num2str(dayNumMacro),'p',num2str(i),'_',num2str(round(tStart)),'_',num2str(round(tEnd)),'s_',num2str(EEG.srate),'Hz_Macro_m.edf'];
        pop_writeeeg (EEGparts{part_ind},fullfile(macro_outputdir,macroOutputNamei),'TYPE','EDF');
        microOuputNamei   	= ['p',num2str(patientNum),'d',num2str(dayNumMicro),'p',num2str(i),'_',num2str(round(tStart)),'_',num2str(round(tEnd)),'s_',FsOutStr,'_micro_m.edf'];
        pop_writeeeg (EEG_micro_part_i,fullfile(micro_outputdir,microOuputNamei),'TYPE','EDF');
        micro_output_name_i_30k = micro_output_name_i;
        pop_writeeeg (EEG_micro_part_i,fullfile(micro_outputdir_30k,micro_output_name_i_30k),'TYPE','EDF');

    end
end


%% Write bipolar files 
% Macro
jediconv_macro_mono2bipolar (macro_outputdir)
% micro
jediconv_micro_mono2bipolar (micro_outputdir, patientNum)
