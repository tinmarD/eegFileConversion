function [outputdir, outputfilename] = jediconv_syncmacrofile (NS, EEG, macropathname, macrofilename)
% [] = jediconv_syncmacrofile (NS, EEG, macropathname, macrofilename)


TRIGGER_THRESHOLD_MICRO = 10000;
TRIGGER_THRESHOLD_MACRO = 1000;

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
%     t_first_trigger_micro   = 1000*(57545245-1)/NS.MetaTags.SamplingFreq; % in ms
end


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
    error ('delay < 0');
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

% Output dir
filesepinds     = regexp (macropathname, filesep);
filesepind      = fastif (filesepinds(end)==length(macropathname),filesepinds(end-1),filesepinds(end));
outputdir       = fullfile (macropathname (1:filesepind),'brut_sync');
if ~isdir(outputdir)
    success = mkdir (outputdir);
    if ~success
        disp (['Could not create the directory ',outputdir]);
        return;
    end
end

%% Write the file ..
outputfilename =  [macrofilename(1:end-4),'_sync.edf'];
pop_writeeeg (EEG,fullfile(outputdir,outputfilename),'TYPE','EDF');


end