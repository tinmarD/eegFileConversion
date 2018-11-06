function [outDirpath, outFilenames, EEGs] = fileconv_nsx2edf ...
    (inDirpath, inFilename, chunkDuration, downsamplingFactor, outDirpathEDF)
% [outDirpath, outFilenames, EEGs] = FILECONV_NSX2EDF 
%               (inputFilepath, chunkDuration, downsamplingFactor)
% Function/script to convert a NSx file to EDF format. Can be call as a
% script with no arguments
%
% Optional Inputs: 
%   - inDirpath             : Input NSx directory path 
%   - inFilename            : Input NSx filename
%   - chunkDuration         : File will be divided in chunks of
%                             chunkDuration seconds, 
%                             if -1 file will not be divided
%   - downsamplingFactor    : Downsampling factor
%   - outDirpath           : Output EDF filepath 
%
% Outputs:
%   - outDirpath            : Output EDF directory path 
%   - outFilenames          : Output filename(s) [Cell]
%   - EEGs                  : Cell containing the different EEG structure
%                             for each segment


%% Read file
outFilenames = {};
EEGs = {};
if nargin < 5
    outDirpath = '';
end
if nargin<2
    NS          = openNSx();
    if ~isstruct(NS); disp('Could not open NSx file'); return; end;
    inDirpath  = NS.MetaTags.FilePath;
    inFilename  = NS.MetaTags.Filename;
    if ~strcmp(inFilename(1:end-4),NS.MetaTags.FileExt)
        inFilename = [inFilename, NS.MetaTags.FileExt];
    end
else
    NS          = openNSx(fullfile(inDirpath,inFilename));
    if ~isstruct(NS); disp(['Could not open NSx file : ',fullfile(inDirpath,inFilename)]); return; end;
end

%% Parameters
if nargin<3
    chunkDuration       = -1;   % sec - if -1 no file segmentation
end
if nargin<4
    downsamplingFactor  = 6;    % from 30kHz to 5kHz (if 6)
end
if nargin<5
    outDirpath = inDirpath;
end

%% NSX file parameters
Fs              = NS.MetaTags.SamplingFreq;
FsOut           = Fs/downsamplingFactor;
nPoints         = NS.MetaTags.DataPoints;
if int32(FsOut/1000)==FsOut/1000
    FsOutStr    = [num2str(FsOut/1000),'kHz'];
else
    FsOutStr    = [num2str(FsOut),'Hz'];
end

%% Conversion
if chunkDuration<0
    nChunks     = 1;
else
    durationSec = NS.MetaTags.DataDurationSec;
    nChunks    	= ceil(durationSec/chunkDuration);
end

outFilenames    = cell(1,nChunks);
EEGs            = cell(1,nChunks);
if chunkDuration<0
    EEGs{1}         = nsx2eeglab(NS, downsamplingFactor);
    outFilenames{1} = [inFilename(1:end-4),'_',num2str(FsOutStr),'.edf'];
    pop_writeeeg (EEGs{1},fullfile(outDirpath,outFilenames{1}),'TYPE','EDF');
else
    for iChunk=1:nChunks
        disp (['part ',num2str(iChunk),'/',num2str(nChunks)]);
        indStart    = 1+(iChunk-1)*chunkDuration*Fs;
        indEnd      = min(1+iChunk*chunkDuration*Fs,nPoints);
        tStart      = round((indStart-1)/Fs);
        tEnd        = round((indEnd-1)/Fs);
        % Read part i of the input signal
        NSpart_i  	= openNSx (fullfile(inDirpath,inFilename),...
            'precision','double',['t:',num2str(indStart),':',num2str(indEnd)],'sample');   
        % Conversion
        EEGs{iChunk}   = nsx2eeglab(NSpart_i, downsamplingFactor);
        % Write file
        outFilenames{iChunk} = [NS.MetaTags.Filename(1:end-4),'_p',num2str(iChunk),'_',num2str(tStart),'_',num2str(tEnd),'s_',FsOutStr,'.edf'];
        pop_writeeeg (EEGs{iChunk},fullfile(outDirpath,outFilenames{iChunk}),'TYPE','EDF');
    end
end


