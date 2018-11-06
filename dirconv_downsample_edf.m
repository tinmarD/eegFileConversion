% Script to downsample all EDF files in input directory 
% Look for EDF files in subdirectories also

%% Parameters
downsamplingFactor  = 6;  
inputEDFdir = 'C:\Users\deudon\Desktop\SpikeSorting\_Data\002RM\EDF\signal_EDF_30kHz\Day1_20.03.15\monopolaire_30kHz';
outputEDFdir = 'C:\Users\deudon\Desktop\SpikeSorting\_Data\002RM\EDF\signal_EDF_30kHz\Day1_20.03.15\monopolaire_5kHz';


%% Read input directory
DirStruct    = rdir(fullfile(inputEDFdir,['**',filesep,'*.edf']));
if isempty(DirStruct); 
    disp(['Could not find any edf file in ',inputEDFdir]);
    return;
else
    nFiles = length(DirStruct);
    disp(['Found ',num2str(nFiles),' edf files']);
end

%% Create output directory if it does not exist
if ~isdir(outputEDFdir)
    mkdir(outputEDFdir)
end

%% Downsample each edf file
for iFile=1:nFiles
    tempSep         = regexp(DirStruct(iFile).name,filesep);
    inDirpath_i     = DirStruct(iFile).name(1:tempSep(end)-1);
    inFilename_i    = DirStruct(iFile).name(tempSep(end)+1:end);
    fileconv_downsample_edf(downsamplingFactor, inDirpath_i, inFilename_i, 1, outputEDFdir);    
end

