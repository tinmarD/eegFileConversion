function [outDirpath, outFilename, EEG_downsampled] = ...
    fileconv_downsample_edf(downsamplingFactor, inDirpath, inFilename, writeFile, outDirpath)
%[outFilepath, outFilename, EEG_downsampled] = FILECONV_DOWNSAMPLE_EDF ...
%       (downsamplingFactor, inDirpath, inFilename, writeFile, outDirpath) 
% Downsample the edf file specified by inDirpath and inFilename by a
% factor downsamplingFactor
%
% Inputs:
%   - downsamplingFactor    : Downsampling factor
% Inputs (Optionnals): 
%   - inDirpath             : Input EDF file directory path 
%   - inFilename            : Input EDF filename
%   - writeFile             : if True, write the downsampled file
%   - outDirpath            : Output directory path
%
% Ouputs:
%   - outDirpath            : Output downsampled EDF directory path
%   - outFilenames          : Output downsampled EDF filename
%   - EEG_downsampled       : Output EEG structure downsampled

if nargin<1
    error('You must specify the down-sampling factor');
else
    if floor(downsamplingFactor) ~= downsamplingFactor
        error('downsamplingFactor must be a positive integer')
    end
    if downsamplingFactor <= 0
        error('downsamplingFactor must be a positive integer')
    end
end
if nargin<3
    [inFilename, inDirpath]    = uigetfile ('*.edf','Select monopolar micro-electrode file');
end
if nargin<4
    writeFile = 1;
end
if nargin<5
    outDirpath = inDirpath;
end

EEG_in = pop_biosig (fullfile(inDirpath,inFilename),'importevent','on');

FsOut = EEG_in.srate / downsamplingFactor;
if int32(FsOut/1000)==FsOut/1000
    FsOutStr    = [num2str(FsOut/1000),'kHz'];
else
    FsOutStr    = [num2str(FsOut),'Hz'];
end

EEG_downsampled = pop_resample(EEG_in, FsOut);

if writeFile
    i_start = regexp(inFilename,'\d+[khHz]+', 'start');
    i_end = regexp(inFilename,'\d+[khHz]+', 'end');
    if ~isempty(i_start)
        outFilename = [inFilename(1:i_start-1), FsOutStr, inFilename(i_end+1:end)];
    else
        outFilename = [inFilename(1:end-4),'_',FsOutStr,'.edf'];
    end        
    pop_writeeeg (EEG_downsampled,fullfile(outDirpath, outFilename));
end

end

