% Script to convert all NSx files in input directory to EDF format
% Look for NSx files in subdirectories also
% Keep the same directory structure than in the input directory


%% Parameters
chunkDuration       = 600;   % secondes
downsamplingFactor  = 1;    
% NSfolder            = uigetdir('Select folder containing .NS5 files');
% EDFoutputDir        = uigetdir('Select output directory');
NSfolder            = 'C:\Users\deudon\Desktop\FichiersAConvertir\TA18_Stim\micro';
EDFoutputDir        = 'C:\Users\deudon\Desktop\FichiersAConvertir\TA18_Stim\micro\EDF';
addTriggerChannel   = 0;

%% Read input directory
nsxDirStruct    = rdir(fullfile(NSfolder,['**',filesep,'*.ns5']));
if isempty(nsxDirStruct); 
    disp(['Could not find any NSx file in ',NSfolder]);
    return;
else
    nFiles = length(nsxDirStruct);
    disp(['Found ',num2str(nFiles),' NSx files']);
end

for iFile=1:nFiles
    NS          = openNSx(nsxDirStruct(iFile).name);
    Fs          = NS.MetaTags.SamplingFreq;
    FsOut           = Fs/downsamplingFactor;
    nPoints         = NS.MetaTags.DataPoints;
    if int32(FsOut/1000)==FsOut/1000; FsOutStr = [num2str(FsOut/1000),'kHz'];
    else FsOutStr = [num2str(FsOut),'Hz'];
    end
    sepPos      = regexp(nsxDirStruct(iFile).name,filesep);
    dirFilei    = nsxDirStruct(iFile).name(length(NSfolder)+1:end);
    dirFileiSep = regexp(dirFilei,filesep);
    fileNamei   = dirFilei(dirFileiSep(end)+1:end);
    fileNamei   = [fileNamei(1:end-3),'edf'];
    dirFilei    = dirFilei(1:dirFileiSep(end)-1);
    
    mkdir(fullfile(EDFoutputDir,dirFilei));
    outputDir   = fullfile(EDFoutputDir,dirFilei);
    
    %- Convert file
    if chunkDuration<0
        EEG             = nsx2eeglab(NS, downsamplingFactor);
        outputFilename  = [NS.MetaTags.Filename(1:end-4),'_',num2str(FsOutStr),'.edf'];
        pop_writeeeg (EEG,fullfile(outputDir,outputFilename),'TYPE','EDF');
    else
        durationSec     = NS.MetaTags.DataDurationSec;
        nChunks         = ceil (durationSec/chunkDuration);
        for iChunk=1:nChunks
            disp (['part ',num2str(iChunk),'/',num2str(nChunks)]);
            indStart    = 1+(iChunk-1)*chunkDuration*Fs;
            indEnd      = min(1+iChunk*chunkDuration*Fs,nPoints);
            tStart      = round((indStart-1)/Fs);
            tEnd        = round((indEnd-1)/Fs);
            % Read part i of the input signal
            NSpart_i  	= openNSx (fullfile(NS.MetaTags.FilePath,[NS.MetaTags.Filename, NS.MetaTags.FileExt]),...
                'precision','double',['t:',num2str(indStart),':',num2str(indEnd)],'sample');   
            % Conversion
            EEGpart_i   = nsx2eeglab(NSpart_i, downsamplingFactor, addTriggerChannel);
            % Write file
            outputFilename_i = [NS.MetaTags.Filename(1:end-4),'_p',num2str(iChunk),'_',num2str(tStart),'_',num2str(tEnd),'s_',FsOutStr,'.edf'];
            pop_writeeeg (EEGpart_i,fullfile(outputDir,outputFilename_i),'TYPE','EDF');
        end
    end
end
