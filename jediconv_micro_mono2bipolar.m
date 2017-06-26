function [] = jediconv_micro_mono2bipolar (microPathname, patientNum, FS)
% [] = JEDICONV_MICRO_MONO2BIPOLAR (microPathname, patientNum, FS)
% 
% Converts the micro monopolar files into bipolar files. The montage used
% for the conversion should be specified in the function
% mono2bipolar_micro.
%
% INPUTS : 
%   - microPathname     : micro path name 
%   - patientNum        : patient number
%   - FS                : sampling frequency (Hz)
%
% See also : mono2bipolar_micro

if int32(FS/1000)==FS/1000
    FsOutStr = [num2str(FS/1000),'k'];
else
    FsOutStr = [num2str(FS)];
end

filesepinds     = regexp    (microPathname, filesep);
filesepind      = fastif    (filesepinds(end)==length(microPathname),filesepinds(end-1),filesepinds(end));
inputdir        = fullfile  (microPathname (1:filesepind),['monopolaire_',FsOutStr]);
outputdir       = fullfile  (microPathname (1:filesepind),['bipolaire_tt_',FsOutStr]);
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
        micropartfilename   = dir_struct(i).name;
        EEG_mono    = pop_biosig            (fullfile(inputdir,micropartfilename), 'importevent', 'on');
        EEG_bi      = mono2bipolar_micro    (EEG_mono, patientNum, 'keepTriggers', 1);
        pop_writeeeg (EEG_bi, fullfile (outputdir,[micropartfilename(1:end-5),'b.edf']), 'TYPE', 'EDF');
    end
end