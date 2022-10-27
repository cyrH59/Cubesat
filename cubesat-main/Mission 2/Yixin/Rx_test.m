%% Main code BLE
clear all;
close all;

%addpath('/Users/ferre/Documents/MATLAB/Examples/R2020b/bluetooth/BLEReceiverExample')

%% Initialisation

phyMode = 'LE125K';
bleParam = helperBLEReceiverConfig(phyMode);


signalSource = 'File'; % The default signal source is 'File'
%%  
if strcmp(signalSource,'File')
    switch bleParam.Mode
        case 'LE1M'
            bbFileName = 'bleCapturesLE1M.bb';
        case 'LE2M'
            bbFileName = 'bleCapturesLE2M.bb';
        case 'LE500K'
            bbFileName = 'bleCapturesLE500K.bb';
        case 'LE125K'
            bbFileName = 'bleCapturesLE125K.bb';
        otherwise
            error('Invalid PHY transmission mode. Valid entries are LE1M, LE2M, LE500K and LE125K.');
    end
    sigSrc = comm.BasebandFileReader(bbFileName);
    sigSrcInfo = info(sigSrc);
    sigSrc.SamplesPerFrame = sigSrcInfo.NumSamplesInData;
    bbSampleRate = sigSrc.SampleRate; % 8000000
    bleParam.SamplesPerSymbol = bbSampleRate/bleParam.SymbolRate;

elseif strcmp(signalSource,'ADALM-PLUTO')

    % First check if the HSP exists
    if isempty(which('plutoradio.internal.getRootDir'))
        error(message('comm_demos:common:NoSupportPackage', ...
            'Communications Toolbox Support Package for ADALM-PLUTO Radio',...
            ['<a href="https://www.mathworks.com/hardware-support/' ...
            'adalm-pluto-radio.html">ADALM-PLUTO Radio Support From Communications Toolbox</a>']));
    end

    bbSampleRate = bleParam.SymbolRate * bleParam.SamplesPerSymbol;
    sigSrc = sdrrx('Pluto',...
        'RadioID',             'usb:0',...
        'CenterFrequency',     2.402e9,...
        'BasebandSampleRate',  bbSampleRate,...
        'SamplesPerFrame',     1e7,...
        'GainSource',         'Manual',...
        'Gain',                25,...
        'OutputDataType',     'double');
else
    error('Invalid signal source. Valid entries are File and ADALM-PLUTO.');
end

% Setup spectrum viewer
spectrumScope = dsp.SpectrumAnalyzer( ...
    'SampleRate',       bbSampleRate,...
    'SpectrumType',     'Power density', ...
    'SpectralAverages', 10, ...
    'YLimits',          [-130 0], ...
    'Title',            'Received Baseband BLE Signal Spectrum', ...
    'YLabel',           'Power spectral density');
%% Capture the BLE Packets
% The transmitted waveform is captured as a burst
dataCaptures = sigSrc(); 

% Show power spectral density of the received waveform
spectrumScope(dataCaptures);



%% 
% Initialize System objects for receiver processing
agc = comm.AGC('MaxPowerGain',20,'DesiredOutputPower',2);  

freqCompensator = comm.CoarseFrequencyCompensator('Modulation','OQPSK', ...
    'SampleRate',bbSampleRate,...
    'SamplesPerSymbol',2*bleParam.SamplesPerSymbol,...
    'FrequencyResolution',100); 

% carrierSync = comm.CarrierSynchronizer('Modulation','OQPSK');


prbDet = comm.PreambleDetector(bleParam.RefSeq,'Detections','First');

% Initialize counter variables
pktCnt = 0;
crcCnt = 0;
displayFlag = false; % true if the received data is to be printed

% Loop to decode the captured BLE samples

Max_CFO = 55e3; % Max CFO due to Doppler Effect
dataCaptures = dataCaptures.*exp(1i*2*pi*Max_CFO*[0:length(dataCaptures)-1]/bbSampleRate).'; % change la variable, mais comment le estimer?

while length(dataCaptures) > bleParam.MinimumPacketLen

    % Consider two frames from the captured signal for each iteration

    startIndex = 1;
    endIndex = min(length(dataCaptures),2*bleParam.FrameLength);
    rcvSig = dataCaptures(startIndex:endIndex);

    rcvAGC = agc(rcvSig); 
    rcvDCFree = rcvAGC - mean(rcvAGC); 
    [rcvFreqComp,est] = freqCompensator(rcvDCFree); 
%     [~,phError] = carrierSync(rcvDCFree);
%    estFreqOffset = diff(phError)*bbSampleRate/(2*pi);
    rcvFilt = conv(rcvFreqComp,bleParam.h,'same');

%     % mon estime de frequence decalage
%     fr = 100; %
%     Nfft = 2^(floor(log2(bbSampleRate/fr)));
%     mOrder = 2;
%     
%      fftData = abs(fft(rcvDCFree.^mOrder,Nfft));
% %     
% %      plot(fftData);
%     
%     [maxVaule,maxIndex] = max(fftData);
%
%     if maxIndex>Nfft/2
%         maxIndex = maxIndex - Nfft;
%     end
%     estFreqOffset1 = bbSampleRate/Nfft*(maxIndex-1)/mOrder

    
    % Perform frame timing synchronization
    [~, dtMt] = prbDet(rcvFilt); %
    release(prbDet)
    prbDet.Threshold = max(dtMt);
    prbIdx = prbDet(rcvFilt);

    % Extract message information
    [cfgLLAdv,pktCnt,crcCnt,remStartIdx] = helperBLEPhyBitRecover(rcvFilt,...
        prbIdx,pktCnt,crcCnt,bleParam);  % 

    % Remaining signal in the burst captures
    dataCaptures = dataCaptures(1+remStartIdx:end);

    % Display the decoded information
    if displayFlag && ~isempty(cfgLLAdv)
        fprintf('Advertising PDU Type: %s\n',cfgLLAdv.PDUType);
        fprintf('Advertising Address: %s\n',cfgLLAdv.AdvertiserAddress);
    end

    % Release System objects
    release(freqCompensator)
    release(prbDet)
end

% Release the signal source
release(sigSrc)

% Determine the PER
if pktCnt
    per = 1-(crcCnt/pktCnt);
    fprintf('Packet error rate for %s mode is %f \n',bleParam.Mode,per);
else
    fprintf('\n No BLE packets were detected.\n')
end

% rmean = cumsum(estFreqOffset)./(1:length(estFreqOffset))';
% plot(rmean)
% xlabel('Symbols')
% ylabel('Estimated Frequency Offset (Hz)')
% grid