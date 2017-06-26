function [outFilepath, outFilename, EEGsync] = filesync_macromicro ...
    (micro_ns5_filepath, micro_ns5_filename, macro_filepath, macro_filename, outFilepath)
% [outFilepath, outFilename, EEGsync] = FILESYNC_MACROMICRO ...
% (micro_ns5_filepath, micro_ns5_filename, macro_filepath, ...
% macro_filename, out_macro_filepath)
%  Function/Script to synchronize a micro-electrode file with a 
%  Macro-electrode file. 
%
%  Write a new Macro file synchronized with the micro file. If the Macro
%  file starts before the micro file, the beginning of the Macro file is cut
%  off. If the Macro file starts after the micro file, a blank signal is
%  added at the beginning of the Macro file.
%
% Optionnal INPUTS:
%   - micro_ns5_filepath        : micro electrode filepath  (NSx format) 
%   - micro_ns5_filename        : micro electrode file name (NSx format)
%   - macro_filepath            : macro electrode filepath  (EDF format)
%   - macro_filename            : macro electrode filename  (EDF format)
%   - outFilepath               : output synchronized macro filepath 
% 
% OUTPUTS:
%   - outFilepath               : output synchronized macro filepath 
%   - outFilename               : output synchronized macro filename
%   - EEGsync                   : synchronized macro electrode EEGLAB structure 
%
% Author: Martin Deudon (2016)


TRIGGER_THRESHOLD_MICRO = 10000;
TRIGGER_THRESHOLD_MACRO = 60;


%% - Inputs
if nargin<4
    [micro_ns5_filename, micro_ns5_filepath] = uigetfile ('*.ns5','Select micro-electrode file');
    if isnumeric(micro_ns5_filename) || isnumeric(micro_ns5_filepath); return; end;
    [macro_filename, macro_filepath]         = uigetfile ('*.edf','Select Macro-electrode file');
    if isnumeric(macro_filename) || isnumeric(macro_filepath); return; end;
end
if nargin<5
    outFilepath = macro_filepath;
end

%% - Open files
try
    NS = openNSx (fullfile(micro_ns5_filepath,micro_ns5_filename));
catch
    disp (['Could not load the micro-electrode file ',fullfile(micro_ns5_filepath,micro_ns5_filename)]);
    return;
end
try
    EEG = pop_biosig   (fullfile(macro_filepath,macro_filename));
catch
    disp (['Could not load the macro-electrode file ',fullfile(macro_filepath,macro_filename)]);
    return;
end


%% Calcul delay
if isempty(cell2mat(regexp(NS.ElectrodesInfo(end).Label,{'ainp1','ainp','trigger','mkr2+','ainp2'})))
    % Search triggers in the NEV file
    warning('Could not find the trigger channel for micro file. The channel name may not be recognized');
    disp('Trying to find triggers in the NEV file')
    try
        NEV = openNEV (fullfile(NS.MetaTags.FilePath,[NS.MetaTags.Filename(1:end-3),'nev']));
    catch
        error ('Could not open the NEV file associated to the NS file');
    end
    TimeStamps  = double(NEV.Data.Spikes.TimeStamp(NEV.Data.Spikes.Electrode==129))/NS.MetaTags.SamplingFreq;
    t_first_trigger_micro = 1000*TimeStamps(1);
else
    % Search triggers in the last channel of the NS file
    triggers_chan_micro     = abs(NS.Data(end,:));
    triggers_ind_micro      = nonzeros((triggers_chan_micro>TRIGGER_THRESHOLD_MICRO).*(1:length(triggers_chan_micro)));
    if isempty(triggers_ind_micro); 
        error('Could not find trigger in the micro file'); 
    end
    t_first_trigger_micro   = 1000*(triggers_ind_micro(1)-1)/NS.MetaTags.SamplingFreq; % in ms
end

if ~strcmpi(EEG.chanlocs(end).labels,'MKR2+')
    error ('The trigger channel must be the last one and named "mkr2+" (case insensitive)');
end
triggers_t_macro               = nonzeros (EEG.times (abs(EEG.data(end,:))>TRIGGER_THRESHOLD_MACRO));
if isempty(triggers_t_macro) 
    error ('Could not find any trigger in the macro file');
end
t_first_trigger_macro   = triggers_t_macro(1);

% Visualize beginning of micro and macro trigger channels
fsMicro         = NS.MetaTags.SamplingFreq;
fsMacro         = EEG.srate;
tVisuStart      = max(0,min(t_first_trigger_macro,t_first_trigger_micro)/1000-20);
tVisuEnd        = min([tVisuStart+60,NS.MetaTags.DataDurationSec,EEG.xmax]);
tVisuMicro      = tVisuStart:(1/fsMicro):tVisuEnd;
tVisuMacro      = tVisuStart:(1/fsMacro):tVisuEnd;
indVisuMicro    = 1+fix(tVisuMicro*fsMicro);
indVisuMacro    = 1+fix(tVisuMacro*fsMacro);
figure;
ax(1) = subplot(211); plot(tVisuMicro,NS.Data(end,indVisuMicro)); title('micro trigger channel'); axis tight; xlabel('time (s)');
ax(2) = subplot(212); plot(tVisuMacro,EEG.data(end,indVisuMacro)); title('Macro trigger channel');axis tight; xlabel('time (s)');
linkaxes(ax,'x');

% Calcul the time difference 
delay = (t_first_trigger_macro - t_first_trigger_micro)/1000;
% delay = -9.0508
disp (['The delay between macro and micro signal is ',num2str(delay),' secondes']);
if delay<0
    delay = -delay;
    disp ('Macro start after micro recording, a blank signal will be add at the beggining of the macro file');
    EEGsync.data = [zeros(EEG.nbchan,round(1+delay*EEG.srate)),EEG.data];
    EEGsync.pnts = size(EEG.data(2));
    EEGsync.xmax = EEG.xmax+delay;
    EEGsync.times= linspace(0,EEG.xmax*1000,size(EEGsync.data,2));
    EEGsync      = eeg_checkset (EEGsync);
else
    % Remove the first part of the macro signal
    EEGsync = pop_select (EEG,'notime',[0 delay]);
end

%% Write synchronized macro file
outFilename = [macro_filename(1:end-4),'_sync.edf'];
pop_writeeeg(EEGsync,fullfile(outFilepath,outFilename),'TYPE','EDF');



