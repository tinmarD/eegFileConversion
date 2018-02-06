% Script to convert all monopolar Macro-electrodes files in input directory 
% in EDF format into bipolar files
% Look for EDF files in subdirectories also
% Write the new bipolar files in the same directory that the monopolar file

%% Parameters
monoFolder          = uigetdir('Select folder containing EDF monopolar Macro files');
badChannelNames   	= {};
keepTriggers        = 1;


%% Read input directory
DirStruct    = rdir(fullfile(monoFolder,['**',filesep,'*.edf']));
if isempty(DirStruct); 
    disp(['Could not find any edf file in ',monoFolder]);
    return;
else
    nFiles = length(DirStruct);
    disp(['Found ',num2str(nFiles),' edf files']);
end


%% Conversion
for iFile=1:nFiles
    tempSep         = regexp(DirStruct(iFile).name,filesep);
    macroFilepath   = DirStruct(iFile).name(1:tempSep(end)-1);
    macroFilename   = DirStruct(iFile).name(tempSep(end)+1:end);
    % Open file
    EEG_mono        = pop_biosig (fullfile(macroFilepath,macroFilename),'importevent','on');
    % Conversion
    EEG_bi          = mono2bipolar_macro(EEG_mono,'keepTriggers', keepTriggers, 'badChannelNames', badChannelNames);

    % Write bipolar file in the same directory than the 
    pop_writeeeg (EEG_bi, fullfile (macroFilepath,[macroFilename(1:end-4),'_b.edf']), 'TYPE', 'EDF');
end
