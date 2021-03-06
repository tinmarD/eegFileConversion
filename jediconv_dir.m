% Jediconv for directory. Used for EpiFar data.
% Take as input the patient directory where the macro and micro data is
% stored. 
%
% The patient directory must contain : 
%   - The clean NS5 file of micro-electrodes recording (in one piece) 
%   (Make sure that the Line Noise Cancellation was activated, otherwise use 
%   Central software to apply the LNC and rewrite the file)
%   - The EDF file of macro-electrodes recording
%
%* Outputs : 
%   - Bipolar files for both micro and macro signals divided in 10min
%   segments
%
%
%* Operations :
%   1 Convert the micro/.NS5 file in .edf format (create a new file) and 
%       divide it in 10-min segments
%   2 Synchronize the Macro/.edf file with the micro/.NS5 file
%   3 Divide the Macro/.edf file in 10-min segments
%   4 Convert the macro monopolar files into bipolar files
%   5 Convert the micro monopolar files into bipolar files
%   (tetrode/tetrode)
%
%
%* Directory structure :
% micro / brut          / micro_ns_file
%       / monopolaire   / 
%       / bipolaire_tt  / 
%
% macro / brut          / macro_edf_file
%       / brut_sync     / macro_edf_file_sync
%       / monopolaire   /
%       / bipolaire     /
%
% Checklist before, during and after conversion : 
% 
% - Check that the LNC (Line Noise Cancellation) was selected during
% micro-electrodes recordings - Use Central server to open .NS5 files
% - After macro segmentation, check the monopolar files to detect bad
% channels and add them to the list
% - At the end check the synchronization between macro and micro recordings
% using the trigger channel.
%
% Requires : rdir, EEGLAB

%% Parameters
chunkduration       = 600;  % secondes
downsamplingfactor  = 6;    % from 30kHz to 5kHz
patientNum          = 43;
macrobadchannels    = {};
dayNumMicro         = [];
dayNumMacro         = [];
%- Add trigger channel in micro NSX file
addMicroTriggerChannel   = 1;
% minTimeBetweenTriggers  =  0.070;
% triggerChanName         = 'trigger';
% triggerMicroVal         = 20000;

%% Inputs
% Selectionner le dossier contenant les différents jours
dirName     = uigetdir('','Select patient data directory'); 
if isnumeric(dirName)
    return;
end
DirStruct       = dir(dirName);
DirStruct(1:2)  = [];
nDays           = length(DirStruct);
if nDays~=5
    warning([num2str(nDays),' day directories were found, expected 5']);
end

for iDay=1:nDays
    
    % Get the files name
    micro_dir_struct    = rdir(fullfile(dirName,DirStruct(iDay).name,['**',filesep,'*.ns5']));
    if length(micro_dir_struct)>1
        warning(['micro directory contains more than 1 file, skip it. ', fullfile(dirName,DirStruct(iDay))]);
        continue;
    elseif isempty(micro_dir_struct)
        warning(['micro filename not found. In ', fullfile(dirName,DirStruct(iDay))]);
        continue;        
    end
    micro_ns5_pathname  = micro_dir_struct.name;
    macro_dir_struct    = rdir(fullfile(dirName,DirStruct(iDay).name,['**',filesep,'*.edf']));
    if length(macro_dir_struct)>1
        %- search if any of the paths contain 'brut' 
        brutVect = regexp({macro_dir_struct.name},'brut');
        brutVect = cellfun(@(x)~isempty(x),brutVect);
        if sum(brutVect)==1
            macro_pathname      = macro_dir_struct(brutVect).name;
        else
            warning(['macro directory contains more than 1 file and could not find the raw file,', ...
                'skip this directory. In ', fullfile(dirName,DirStruct(iDay).name)]);
            continue;
        end
    elseif isempty(macro_dir_struct)
        warning(['macro filename not found. In ', fullfile(dirName,DirStruct(iDay).name)]);
        continue;     
    else
        macro_pathname      = macro_dir_struct.name;
    end
    
    
    %- Check patient number
    if isempty(regexpi(macro_pathname,['p',num2str(patientNum)],'once')) 
        disp (['The macro-electrode directory does not math the patient number (p',num2str(patientNum),')']);
        disp (macro_pathname);
        return;
    end
    if isempty(regexpi(micro_ns5_pathname,['p',num2str(patientNum)],'once')) 
        disp (['The micro-electrode directory does not math the patient number (p',num2str(patientNum),')']);
        disp (micro_ns5_dirname);
        return;
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
    if isempty(dayNumMicro); warning('Could not determine micro recording day number'); 
    elseif isempty(dayNumMacro); warning('Could not determine Macro recording day number'); 
    elseif dayNumMicro~=dayNumMacro
        error('Macro and micro days of recording seem to be different');
    else
        disp(['Day ',num2str(dayNumMicro),' of recording']);
    end

    try
        NS = openNSx (micro_ns5_pathname);
    catch
        disp (['Could not load the micro-electrode file ',fullfile(micro_ns5_dirname,micro_ns5_pathname)]);
        return;
    end
    try
        EEG = pop_biosig   (macro_pathname);
    catch
        disp (['Could not load the macro-electrode file ',fullfile(macro_dirname,macro_pathname)]);
        return;
    end
    
    fsep = regexp(micro_ns5_pathname,filesep);
    micro_ns5_filename  = micro_ns5_pathname(fsep(end)+1:end);
    micro_ns5_pathname  = micro_ns5_pathname(1:fsep(end)-1);
    fsep = regexp(macro_pathname,filesep);
    macro_pathname      = macro_pathname(1:fsep(end)-1);

%     % - write a small part a macro file to check for bad channels
%     EEGpart0    = pop_select(EEG,'time',[0,300]);
%     pop_writeeeg(EEGpart0,'C:\Users\deudon\Desktop\MacroPart0.edf','TYPE','EDF');
%     NSpart0     = openNSx(fullfile(micro_ns5_pathname,micro_ns5_filename),'t:0:300','sec');
%     NSpart0eeg  = jediconv_NSxToEeglab(NSpart0,downsamplingfactor);
%     pop_writeeeg(NSpart0eeg,'C:\Users\deudon\Desktop\microPart0.edf','TYPE','EDF');

    %% Conversions
    % 1 - ns5 to edf conversion and file segmentation
    jediconv_nsx2edf      (NS, chunkduration, downsamplingfactor, patientNum, dayNumMicro, addMicroTriggerChannel)

    % 2 - Macro edf file synchronization with the micro file
    jediconv_syncanddividemacrofile (NS, EEG, macro_pathname, chunkduration, patientNum, dayNumMacro, macrobadchannels);

    % 3 - Convert the Macro monopolar files into bipolar files
    jediconv_macro_mono2bipolar (macro_pathname);

    % 4 - Convert the micro monopolar files into bipolar files
    jediconv_micro_mono2bipolar (micro_ns5_pathname, patientNum, NS.MetaTags.SamplingFreq/downsamplingfactor);

    % 5 - 30kHz monopolar - Convert micro file without downsampling for AP research
    jediconv_nsx2edf      (NS, chunkduration, 1, patientNum, dayNumMicro)

    % 6 - Convert the micro 30kHz monopolar files into 30kHz bipolar files
    jediconv_micro_mono2bipolar (micro_ns5_pathname, patientNum, NS.MetaTags.SamplingFreq);

end



