function [triggers_msec_single, triggers_msec_raw, triggerFoundInData] = ...
    findtriggers_micro (NS, minTimeBetweenTriggers)
%[triggers_msec_single, triggers_msec_raw] = ...
%   FINDTRIGGERS_MICRO (NS, minTimeBetweenTriggers)
%   Found the triggers in the NS file (Blackrock). These triggers can be
%   either in the NSX data file or in the NEV file (in the Timestamps or in
%   NEV.Data.SerialDigitalIO.TimeStampSec).
%   Triggers_msec_raw_single contain the trigger times with the removal of
%   double triggers. Double triggers are triggers closer than 
%   minTimeBetweenTriggers sec in time. 
%   
% INPUTS : 
%	- NS                        : NS micro file structure
%   - minTimeBetweenTriggers    : if the time between 2 triggers is
%   inferior to this value, the second one will be deleted
%   
% OUTPUTS : 
%   - triggers_msec_raw_single  : Trigger times (msec) with removal of
%   double triggers
%   - trigger_msec_raw          : Trigger times (msec) without removal of
%   double triggers
%   - triggerFoundInData        : 1 if the triggers are in the data file
%   (NSX), 0 if they are in the NEV file.
%
% Author(s) : Martin Deudon (June 2017)

% Parameters
TRIGGER_THRESHOLD_MICRO     = 10000;
MINTIME_BETWEEN_TRIGGERS    = 0.070;

if nargin==1
    minTimeBetweenTriggers = MINTIME_BETWEEN_TRIGGERS;
end
%- Get NEV filename
if strcmp(NS.MetaTags.Filename(end-3:end),'.ns5')
    nevFilename = [NS.MetaTags.Filename(1:end-4),'.nev'];
else
    nevFilename = [NS.MetaTags.Filename,'.nev'];
end
    
triggerFoundInData      = 0;
triggers_msec_raw       = [];
%- Triggers in micro file 
triggersFound           = 0;
if ~isempty(cell2mat(regexp(NS.ElectrodesInfo(end).Label,{'ainp1','ainp','trigger','mkr2+','ainp2'})))
    disp('Searching trigger in the data file...');
    % Search triggers in the last channel of the NS file
    triggerChan         = abs(NS.Data(end,:));
    triggerThresh    	= logical(triggerChan>TRIGGER_THRESHOLD_MICRO);
    if sum(triggerThresh)==0
        warning('Could not find trigger in the micro data file'); 
    else
        triggerInd          = triggerThresh(1:end)==1 & [0,triggerThresh(1:end-1)]==0;
        triggerPos          = find(triggerInd);
        triggers_msec_raw 	= 1000*(triggerPos-1)/NS.MetaTags.SamplingFreq;
        triggersFound       = 1;
        triggerFoundInData  = 1;
    end
end
if ~triggersFound
    % Search triggers in the NEV file
    disp('Searching triggers in the NEV file...')
    try
        NEV = openNEV (fullfile(NS.MetaTags.FilePath,nevFilename),'overwrite');
    catch
        warning ('Could not open the NEV file associated to the NS file');
    end
    if isempty(NEV)
        triggersFound = 0;
    else
        TimeStamps  = double(NEV.Data.Spikes.TimeStamp(NEV.Data.Spikes.Electrode==129))/NS.MetaTags.SamplingFreq;
        if ~isempty(TimeStamps)
            triggers_msec_raw = 1000*TimeStamps;
            disp('Triggers found in NEV.Data.Spikes.TimeStamp');
        else
            disp('Searching triggers in NEV.Data.SerialDigitalIO.TimeStampSec...');
            try
                triggers_msec_raw           = 1000*NEV.Data.SerialDigitalIO.TimeStampSec';
            catch
                error('Could not find the triggers in the data file and in the NEV file');
            end
            disp('Triggers found in NEV.Data.SerialDigitalIO.TimeStampSec');
            triggersFound = 1;
        end
    end
end

if triggersFound
    %- Remove double triggers
    triggerIntSec   = (triggers_msec_raw(2:end)-triggers_msec_raw(1:end-1))/1000;
    triggerToRemove = [0;triggerIntSec(:)<minTimeBetweenTriggers];
    triggers_msec_single = triggers_msec_raw(~(logical(triggerToRemove)));
    disp(['Found ',num2str(sum(triggerToRemove)),'/',num2str(length(triggers_msec_raw)),' doubled triggers - deleting the doubled ones']);
else
    triggers_msec_single = [];
    warning('Could not find the triggers');
end
    
end

