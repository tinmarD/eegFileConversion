function [outFilepath, outFilenames] = filedivide_edf ...
    (inFilepath, inFilename, chunkDuration, outFilepath)
% [outFilepath, outFilenames] = FILEDIVIDE_EDF ...
%     (inFilepath, inFilename, chunkDuration, outFilepath)
% Function/script to divide an edf file into separates edf files
% Can be call as a script with no arguments
%
% Optional Inputs: 
%   - inFilepath            : Input NSx filepath 
%   - inFilename            : Input NSx filename
%   - chunkDuration         : File will be divided in chunks of
%                             chunkDuration seconds
%   - outFilepath           : Output EDF filepath 
%
% Outputs:
%   - outFilepath           : Output EDF filepath 
%   - outFilenames          : Output filename(s) [string or cell]
%


%% Open file
if nargin<2
    [inFilename, inFilepath] = uigetfile ('*.edf','Select edf file');
end
EEG     = pop_biosig(fullfile(inFilepath,inFilename));
Fs     	= EEG.srate;
nPoints = EEG.pnts;

%% Parameters
if nargin<3
    chunkDuration = 600;   % sec
end
if nargin<4
    outFilepath = inFilepath;
end

%% File segmentation
if int32(Fs/1000)==Fs/1000
    FsStr       = [num2str(Fs/1000),'kHz'];
else
    FsStr       = [num2str(Fs),'Hz'];
end

durationSec     = EEG.xmax;
nChunks         = ceil (durationSec/chunkDuration);
if nChunks<1; disp(['Wrong argument chunkDuration : ',chunkDuration]); return; end
outFilenames    = cell(1,nChunks);
for iChunk=1:nChunks
        disp (['part ',num2str(iChunk),'/',num2str(nChunks)]);
        indStart    = 1+(iChunk-1)*chunkDuration*Fs;
        indEnd      = min(1+iChunk*chunkDuration*Fs,nPoints);
        tStart      = round((indStart-1)/Fs);
        tEnd        = round((indEnd-1)/Fs);
        EEGpart_i   = pop_select(EEG,'time',[tStart tEnd]);
        %- Write file
        outFilenames{iChunk} = [inFilename(1:end-4),'_p',num2str(iChunk),'_',num2str(tStart),'_',num2str(tEnd),'s_',FsStr,'.edf'];
        pop_writeeeg (EEGpart_i,fullfile(outFilepath,outFilenames{iChunk}),'TYPE','EDF');
end


