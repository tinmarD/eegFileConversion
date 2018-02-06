% Script to convert all monopolar micro-electrodes files in input directory 
% in EDF format into bipolar files
% Look for EDF files in subdirectories also
% Write the new bipolar files in the same directory that the monopolar file


%% Parameters
monoFolder          = uigetdir('Select folder containing EDF monopolar micro files');
patientNum          = str2double(inputdlg('Patient number ?'));
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
    microFilepath   = DirStruct(iFile).name(1:tempSep(end)-1);
    microFilename   = DirStruct(iFile).name(tempSep(end)+1:end);
    % Open file
    EEG_mono        = pop_biosig (fullfile(microFilepath,microFilename),'importevent','on');
    % Conversion
    EEG_bi          = mono2bipolar_micro(EEG_mono, patientNum, ...
            'keepTriggers', keepTriggers, 'badChannelNames', badChannelNames);
    % Write bipolar file in the same directory than the 
    pop_writeeeg (EEG_bi, fullfile (microFilepath,[microFilename(1:end-4),'_b.edf']), 'TYPE', 'EDF');
end