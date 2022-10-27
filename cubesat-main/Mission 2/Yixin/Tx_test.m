clear;
clc;
close;



%% Check for Support Package Installation

% Check if the 'Communications Toolbox Library for the Bluetooth Protocol'
% support package is installed or not.
commSupportPackageCheck('BLUETOOTH');

%%

% Configure an advertising channel PDU



cfgLLAdv = bleLLAdvertisingChannelPDUConfig;
cfgLLAdv.PDUType         = 'Advertising indication';
% cfgLLAdv.AdvertisingData = '0123456789ABCDEF'; 
cfgLLAdv.AdvertisingData = '0123456789'; 
cfgLLAdv.AdvertiserAddress = '1234567890AB';
% Generate an advertising channel PDU
messageBits = bleLLAdvertisingChannelPDU(cfgLLAdv);

%%


phyMode = 'LE125K'; % Select one mode from the set {'LE1M','LE2M','LE500K','LE125K'}
sps = 8;          % Samples per symbol 
channelIdx = 37;  % Channel index value in the range [0,39]
accessAddLen = 32;% Length of access address
accessAddHex = '8E89BED6';  % Access address value in hexadecimal
accessAddBin = de2bi(hex2dec(accessAddHex),accessAddLen)'; % Access address in binary

% Symbol rate based on |'Mode'|
symbolRate = 1e6;
if strcmp(phyMode,'LE2M')
    symbolRate = 2e6;
end


txWaveform = bleWaveformGenerator(messageBits,...
    'Mode',            phyMode,...
    'SamplesPerSymbol',sps,...
    'ChannelIndex',    channelIdx,...
    'AccessAddress',   accessAddBin);

% Setup spectrum viewer
spectrumScope = dsp.SpectrumAnalyzer( ...
    'SampleRate',       symbolRate*sps,...
    'SpectrumType',     'Power density', ...
    'SpectralAverages', 10, ...
    'YLimits',          [-130 0], ...
    'Title',            'Baseband BLE Signal Spectrum', ...
    'YLabel',           'Power spectral density');

% Show power spectral density of the BLE signal
spectrumScope(txWaveform); % txWaveform :



%% *Transmitter Processing

% Initialize the parameters required for signal source
txCenterFrequency       = 2.402e9;  % Varies based on channel index value
txFrameLength           = length(txWaveform);
txNumberOfFrames        = 1e4;
txFrontEndSampleRate    = symbolRate*sps;

% The default signal source is 'File'
signalSink = 'File';

if strcmp(signalSink,'File')
    
    sigSink = comm.BasebandFileWriter('CenterFrequency',txCenterFrequency,...
        'Filename','bleCapturesLE125K.bb',...
        'SampleRate',txFrontEndSampleRate);
    info(sigSink);
    sigSink(txWaveform); % Writing to a baseband file 'bleCaptures.bb'
    
elseif strcmp(signalSink,'ADALM-PLUTO')
   
    % First check if the HSP exists
    if isempty(which('plutoradio.internal.getRootDir'))
        error(message('comm_demos:common:NoSupportPackage', ...
                      'Communications Toolbox Support Package for ADALM-PLUTO Radio',...
                      ['<a href="https://www.mathworks.com/hardware-support/' ...
                      'adalm-pluto-radio.html">ADALM-PLUTO Radio Support From Communications Toolbox</a>']));
    end 
    connectedRadios = findPlutoRadio; % Discover ADALM-PLUTO radio(s) connected to your computer
    radioID = connectedRadios(1).RadioID;
    sigSink = sdrtx( 'Pluto',...
        'RadioID',           radioID,...
        'CenterFrequency',   txCenterFrequency,...
        'Gain',              0,...
        'SamplesPerFrame',   txFrameLength,...
        'BasebandSampleRate',txFrontEndSampleRate);
    % The transfer of baseband data to the SDR hardware is enclosed in a
    % try/catch block. This means that if an error occurs during the
    % transmission, the hardware resources used by the SDR System
    % object(TM) are released.
    currentFrame = 1;
    try
        while currentFrame <= txNumberOfFrames
            % Data transmission
            sigSink(txWaveform);
            % Update the counter
            currentFrame = currentFrame + 1;
        end
    catch ME
        release(sigSink);
        rethrow(ME)
    end
else
    error('Invalid signal sink. Valid entries are File and ADALM-PLUTO.');
end

% Release the signal sink
release(sigSink)


% trouver la methode d'ajouter le snr dans le sigal generer,
