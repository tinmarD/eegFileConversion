function [outFilepath, outFilename, EEG_bi] = fileconv_mono2bipolar_macro ...    
(inFilepath, inFilename, badChannelNames, keepTriggers, outFilepath)
%[outFilepath, outFilename, EEG_bi] = FILECONV_MONO2BIPOLAR_MACRO ...
%    (inFilepath, inFilename, patientNum, badChannelNames, keepTriggers, outFilepath)
% Function/Script to convert a monopolar Macro-electrode file in EDF format 
% into a bipolar file in EDF format
%
% Optional Inputs: 
%   - inFilepath            : Input monopolar EDF filepath 
%   - inFilename            : Input monopolar EDF  filename
%   - badChannelNames       : Cell containing the bad channels'names
%   - keepTriggers          : if 1, will keep the trigger channel
%   - outFilepath           : Output EDF filepath 
%
% Outputs:
%   - outFilepath           : Output bipolar EDF filepath 
%   - outFilenames          : Output bipolar EDF filename
%   - EEG_bi                : Output EEG structure with bipolar montage


%% Parameters
if nargin<2
    [inFilename, inFilepath]    = uigetfile ('*.edf','Select monopolar micro-electrode file');
end
if nargin<3
    badChannelNames           	= {};
end
if nargin<4
    keepTriggers              	= 1;
end
if nargin<5
    outFilepath                 = inFilepath;
end

if isnumeric(inFilename) || isnumeric(inFilepath); return; end;
if isempty(patientNum); disp('patientNum is empty'); return; end;

%% Open file
EEG_mono    = pop_biosig (fullfile(inFilepath,inFilename),'importevent','on');

%% Conversion
EEG_bi      = mono2bipolar_macro(EEG_mono,'keepTriggers', keepTriggers, 'badChannelNames', badChannelNames);

%% Write File
outFilename = [inFilename(1:end-4),'_b.edf'];
pop_writeeeg (EEG_bi, fullfile (outFilepath,outFilename), 'TYPE', 'EDF');



