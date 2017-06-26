function NSout = addtriggerchannel_micro ...
    (NS, minTimeBetweenTriggers, triggerChanName, triggerMicroVal)
% NSout = ADDTRIGGERCHANNEL_MICRO ...
%    (NS, minTimeBetweenTriggers, triggerChanName, triggerMicroVal)
%   --- NOT USED ----

microTrigDuration   = 0.005; % sec
microTrigSamples    = microTrigDuration*NS.MetaTags.SamplingFreq;

if nargin<3
    triggerChanName = 'trigger';
    triggerMicroVal = 20000;
elseif nargin<4
    triggerMicroVal = 20000;
end

[triggers_msec_single, ~, triggerFoundInData] = ...
    findtriggers_micro (NS, minTimeBetweenTriggers);

if triggerFoundInData
    disp(['A trigger channel already exists in the NSX file. Trigger channel is named : ',...
        NS.ElectrodesInfo(end).Label]);
elseif ~isempty(triggers_msec_single)
    disp(['Trigger found in the NEV file - Create a trigger channel in last position named :',...
        triggerChanName]);
    NSout       = NS;
    trigChanPos = NS.MetaTags.ChannelCount+1;
    NSout.MetaTags.ChannelCount = NS.MetaTags.ChannelCount+1;
    NSout.MetaTags.ChannelID(trigChanPos) = uint16(0);
    triggerPos  = 1+fix(triggers_msec_single/1000*NS.MetaTags.SamplingFreq);
    triggerChan = zeros(1,NS.MetaTags.DataPoints);
    for i=1:length(triggerPos)
        triggerChan(triggerPos(i):min(NS.MetaTags.DataPoints,triggerPos(i)+microTrigSamples)) = triggerMicroVal;
    end
    NSout.Data  = [NS.Data;triggerChan];
    NSout.ElectrodesInfo(trigChanPos).Type         	= 'CC';
    NSout.ElectrodesInfo(trigChanPos).ElectrodeID    = -1;
    NSout.ElectrodesInfo(trigChanPos).Label          = triggerChanName;
    NSout.ElectrodesInfo(trigChanPos).ConnectorBank  = '-1';
    NSout.ElectrodesInfo(trigChanPos).ConnectorPin   = -1;
    NSout.ElectrodesInfo(trigChanPos).MinDigiValue   = -32767;
    NSout.ElectrodesInfo(trigChanPos).MaxDigiValue   = 32767;
    NSout.ElectrodesInfo(trigChanPos).MinAnalogValue = -5000;
    NSout.ElectrodesInfo(trigChanPos).MaxAnalogValue = 5000;
    NSout.ElectrodesInfo(trigChanPos).AnalogUnits    = 'mv';
    NSout.ElectrodesInfo(trigChanPos).HighFreqCorner = 0;
    NSout.ElectrodesInfo(trigChanPos).HighFreqOrder  = 0;
    NSout.ElectrodesInfo(trigChanPos).HighFilterType = 0;
    NSout.ElectrodesInfo(trigChanPos).LowFreqCorner  = 0;
    NSout.ElectrodesInfo(trigChanPos).LowFreqOrder   = 0;
    NSout.ElectrodesInfo(trigChanPos).LowFilterType  = 0;
end

end

