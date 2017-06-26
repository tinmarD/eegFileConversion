function [] = jediconv_nsx2edf (NS, chunkDuration, downsamplingFactor, patientNum, ...
    dayNum, addTriggerChannel, outputDirName)
% [] = JEDICONV_NSX2EDF (NS, chunkDuration, downsamplingFactor, ...
%                    patientNum, dayNum, outputDirName, addTriggerMicro)
%
% Convert a NSX file (Blackrock) into EDF files. The NSX file is divided
% into chunks of chunkDuration seconds and downsampled. Each part of the
% input file is written as a EDF file.
%
% INPUTS : 
%   - NS                    : NSX file structure (Blackrock)
%   - chunkDuration         : chunk duration for dividing the file. If -1,
%                             keep only 1 file
%   - downsamplingFactor    : downsampling factor
%   - patientNum            : patient number
%   - dayNum                : day number of EpiFar
%   - addTriggerChannel     : if 1 will add a trigger channel in the .edf
%                             file 
%   - outputDirName         : name of the directory where the output file
%                             is written
% 
% OUTPUTS : []
% 
%
% Author(s) : Martin Deudon (Juin 2017)


Fs              = NS.MetaTags.SamplingFreq;
FsOut           = Fs/downsamplingFactor;
nPoints         = NS.MetaTags.DataPoints;
duration        = (nPoints-1)/Fs;
nChunks         = ceil (duration/chunkDuration);
nsFilePath      = NS.MetaTags.FilePath;
nsFilename      = NS.MetaTags.Filename;
if ~strcmpi(nsFilename(end-3:end),'.ns5')
    nsFilename  = [nsFilename,'.ns5'];
end

if chunkDuration<0
    chunkDuration = NS.MetaTags.DataDurationSec;
end

if int32(FsOut/1000)==FsOut/1000
    FsOutStr = [num2str(FsOut/1000),'kHz'];
else
    FsOutStr = [num2str(FsOut),'Hz'];
end

if nargin<8 
    outputDirName = ['monopolaire_',FsOutStr];
end
filesepinds     = regexp (nsFilePath, filesep);
filesepind      = fastif (filesepinds(end)==length(nsFilePath),filesepinds(end-1),filesepinds(end));
outputDir       = fullfile (nsFilePath (1:filesepind),outputDirName);
if ~isdir(outputDir)
    success = mkdir (outputDir);
    if ~success
        disp (['Could not create the directory ',outputDir]);
        return;
    end
end

for i=1:nChunks
    disp (['part ',num2str(i),'/',num2str(nChunks)]);
    indStart    = 1+(i-1)*chunkDuration*Fs;
    indEnd      = min(1+i*chunkDuration*Fs,nPoints);
    tStart      = round((indStart-1)/Fs);
    tEnd        = round((indEnd-1)/Fs);
    
    % Read part i of the input signal
    NS_part_i       = openNSx (fullfile(nsFilePath,nsFilename),'precision','double',['t:',num2str(indStart),':',num2str(indEnd)],'sample');   
    
    % Inversion des électrodes pour P34 Day1
    if patientNum==34 && dayNum==1
        warning('ATTENTION INVERSION DES 12 premiers electrodes avec les 8 autres!!!!!!! pour DAY1 P34 seulement!!!!');
        labelsBackup = {NS_part_i.ElectrodesInfo(1:20).Label};
        [NS_part_i.ElectrodesInfo(1:8).Label] = labelsBackup{13:20};
        [NS_part_i.ElectrodesInfo(9:20).Label]= labelsBackup{1:12};
    end
    
    % Get corresponding EEGLAB structure
    EEGLAB_part_i   = nsx2eeglab (NS_part_i, downsamplingFactor, addTriggerChannel);
    % Export to .edf file
    output_name_i   = ['p',num2str(patientNum),'d',num2str(dayNum),'p',num2str(i),'_',num2str(tStart),'_',num2str(tEnd),'s_',FsOutStr,'_micro_m.edf'];

    pop_writeeeg (EEGLAB_part_i,fullfile(outputDir,output_name_i),'TYPE','EDF');
end


end

