function [] = jediconv_macro_mono2bipolar (macropathname, badChannelNames)
% [] = JEDICONV_MACRO_MONO2BIPOLAR (macropathname,badChannelNames)
% 
% Converts the macro monopolar files into a bipolar files. Used for EpiFar
% files. Search for monopolar file in a directory called "monopolaire"
%
% INPUTS : 
%   - macropathname     : EEG macro file (.EDF)
%   - badChannelNames   : bad channel names (cell) [Optional]

if nargin==1
    badChannelNames = {};
end

filesepinds     = regexp    (macropathname, filesep);
if filesepinds(end)==length(macropathname)
    filesepind = filesepinds(end-1);
else
    filesepind = filesepinds(end);
end
inputdir        = fullfile  (macropathname (1:filesepind),'monopolaire');
outputdir       = fullfile  (macropathname (1:filesepind),'bipolaire');
if ~isdir(outputdir)
    success = mkdir (outputdir);
    if ~success
        disp (['Could not create the directory ',outputdir]);
        return;
    end
end
dir_struct = dir (inputdir);

for i=1:length(dir_struct)
    if ~strcmp(dir_struct(i).name,'.') && ~strcmp(dir_struct(i).name,'..')
        macropartfilename   = dir_struct(i).name;
        EEG_mono            = pop_biosig    	 (fullfile(inputdir,macropartfilename));
        EEG_bi              = mono2bipolar_macro (EEG_mono, 'keepTriggers', 1, 'badChannelNames', badChannelNames);
        pop_writeeeg (EEG_bi, fullfile (outputdir,[macropartfilename(1:end-5),'b.edf']), 'TYPE', 'EDF');
    end
end


