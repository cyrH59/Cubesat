%% Bluetooth Low Energy Bit Error Rate Simulation
% This example shows how the Communications Toolbox(TM) Library for the
% Bluetooth(R) Protocol can be used to measure the bit error rate (BER) for
% different modes of Bluetooth Low Energy (BLE) [ <#9 1> ] using an
% end-to-end physical layer simulation.

% Copyright 2018-2019 The MathWorks, Inc.

%% Introduction
% In this example, an end-to-end simulation is used to determine the BER
% performance of BLE [ <#9 1> ] under an additive white gaussian noise
% (AWGN) channel for a range of bit energy to noise density ratio (Eb/No)
% values. At each Eb/No point, multiple BLE packets are transmitted through
% a noisy channel with no other radio front-end (RF) impairments. Assuming
% perfect synchronization, an ideal receiver is used to recover the data
% bits. These recovered data bits are compared with the transmitted data
% bits to determine the BER. BER curves are generated for the four PHY
% transmission throughput modes supported in BLE specification [ <#9 1> ]
% as follows:
%
% * Uncoded PHY with data rate of 1 Mbps (LE1M)
% * Uncoded PHY with data rate of 2 Mbps (LE2M)
% * Coded PHY with data rate of 500 Kbps (LE500K)
% * Coded PHY with data rate of 125 Kbps (LE125K)
%
% The following diagram summarizes the simulation for each packet.
%
% <<../BLEPHY.png>>

%% Check for Support Package Installation

% Check if the 'Communications Toolbox Library for the Bluetooth Protocol'
% support package is installed or not.
commSupportPackageCheck('BLUETOOTH');

%% Initialize the Simulation Parameters
EbNo = -2:2:8;                        % Eb/No range in dB
sps = 4;                              % Samples per symbol
dataLen = 2080;                       % Data length in bits
simMode = {'LE1M','LE2M','LE500K','LE125K'};
% Max_CFO_tab=10e3:2*10e3:10e4;
% Max_CFO_tab=Max_CFO_tab(1:4);%table of Max CFO due to Doppler Effect

Max_CFO_tab=[ 0 10e3 10e4 1.2*10e4 1.4*10e4];
%%
% The number of packets tested at each Eb/No point is controlled by two
% parameters:
%
% # |maxNumErrors| is the maximum number of bit errors simulated at each
% Eb/No point. When the number of bit errors reaches this limit, the
% simulation at this Eb/No point is complete.
% # |maxNumPackets| is the maximum number of packets simulated at each
% Eb/No point and limits the length of the simulation if the bit error
% limit is not reached.
%
% The numbers chosen for |maxNumErrors| and |maxNumPackets| in this example
% will lead to a very short simulation. For statistically meaningful
% results we recommend increasing these numbers.

maxNumErrors = 100; % Maximum number of bit errors at an Eb/No point
maxNumPackets = 10; % Maximum number of packets at an Eb/No point

%% Simulating for Each Eb/No Point
% This example also demonstrates how a <docid:matlab_ref#f71-813245
% parfor> loop can be used instead of the <docid:matlab_ref#buhafgy-1
% for> loop when simulating each Eb/No point to speed up a simulation.
% <docid:matlab_ref#f71-813245 parfor>, as part of the
% <docid:distcomp_doccenter#index Parallel Computing Toolbox>,
% executes processing for each Eb/No point in parallel to reduce the total
% simulation time. To enable the use of parallel computing for
% increased speed, comment out the 'for' statement and uncomment the
% 'parfor' statement below. If Parallel Computing Toolbox(TM) is not
% installed, 'parfor' will default to the normal 'for' statement.

numMode = numel(simMode);          % Number of modes
ber = zeros(length(Max_CFO_tab),length(EbNo)); % Pre-allocate to store BER results

for i_offset = 1:length(Max_CFO_tab)
    iMode=4;
    phyMode = simMode{iMode};
   % bleParam = helperBLEReceiverConfig(phyMode);

    % Set signal to noise ratio (SNR) points based on mode
    % For Coded PHY's (LE500K and LE125K), the code rate factor is included
    % in SNR calculation as 1/2 rate FEC encoder is used.
    if any(strcmp(phyMode,{'LE1M','LE2M'}))
        snrVec = EbNo - 10*log10(sps);
    else
        codeRate = 1/2;
        snrVec = EbNo + 10*log10(codeRate) - 10*log10(sps);
    end
 
%     parfor iSnr = 1:length(snrVec)  % Use 'parfor' to speed up the simulation
    for iSnr = 1:length(snrVec)       % Use 'for' to debug the simulation

        % Set random substream index per iteration to ensure that each
        % iteration uses a repeatable set of random numbers
        stream = RandStream('combRecursive','Seed',0);
        stream.Substream = iSnr;
        RandStream.setGlobalStream(stream);

        % Create an instance of error rate
        errorRate = comm.ErrorRate('Samples','Custom','CustomSamples',1:(dataLen-1));

        % Loop to simulate multiple packets
        numErrs = 0;
        numPkt = 1; % Index of packet transmitted
        while numErrs < maxNumErrors && numPkt < maxNumPackets

            % Generate BLE waveform
            txBits = randi([0 1],dataLen,1,'int8'); % Data bits generation  发送的比特
            chanIndex = randi([0 39],1,1); % Random channel index value for each packet
            if chanIndex <=36
                % Random access address for data channels
                % Ideally, this access address value should meet the requirements specified in
                % Section 2.1.2, Part-B, Vol-6 of Bluetooth specification.
                accessAdd = [1 0 0 0 1 1 1 0 1 1 0 0 1 ...
                          0 0 1 1 0 1 1 1 1 1 0 1 1 0 1 0 1 1 0]';
            else
                % Default access address for periodic advertising channels
                accessAdd = [0 1 1 0 1 0 1 1 0 1 1 1 1 1 0 1 1 0 0 ...
                            1 0 0 0 1 0 1 1 1 0 0 0 1]';
            end
            txWaveform = bleWaveformGenerator(txBits,'Mode',phyMode,...
                                            'SamplesPerSymbol',sps,...
                                            'ChannelIndex',chanIndex,...
                                            'AccessAddress',accessAdd);
            %Loop to decode the captured BLE samples
            SymboleRate=1e6;     %symbole Rate as per standard
            bbSampleRate=sps*SymboleRate;
            Max_CFO = Max_CFO_tab(i_offset); % Max CFO due to Doppler Effect
            txWaveform= txWaveform.*exp(1i*2*pi*Max_CFO*[0:length(txWaveform)-1]/bbSampleRate).';
            
            
            % Pass the transmitted waveform through AWGN channel
            rxWaveform = awgn(txWaveform,snrVec(iSnr));
            
           
           

            % Recover data bits using ideal receiver
            rxBits = bleIdealReceiver(rxWaveform,'Mode',phyMode,...
                                        'SamplesPerSymbol',sps,...
                                        'ChannelIndex',chanIndex);

            % Determine the BER
            errors = errorRate(txBits,rxBits);
            ber(i_offset,iSnr) = errors(1);
            numErrs = errors(2);
            numPkt = numPkt + 1;
        end
%     disp(['Mode ' phyMode ', '...
%         'Simulating for Eb/No = ', num2str(EbNo(iSnr)), ' dB' ', '...
%         'BER:',num2str(ber(iMode,iSnr))])
    end
end

%% Plot BER vs Eb/No Results
markers = 'ox*so';
color = 'bmcry';
dataStr = {zeros(length(Max_CFO_tab),1)};
figure;
for iMode = 1:length(Max_CFO_tab)
    semilogy(EbNo,ber(iMode,:).',['-' markers(iMode) color(iMode)]);
    hold on;
    Legend='Max CFO de  ';
    dataStr(iMode) = {strcat(Legend,int2str(Max_CFO_tab(iMode)))};
end
grid on;
xlabel('Eb/No (dB)');
ylabel('BER');
legend(dataStr);
title('BER for BLE with AWGN channel');



%% Further Exploration
% The number of packets tested at each Eb/No point is controlled by
% |maxNumErrors| and |maxNumPackets| parameters. For statistically
% meaningful results these values should be larger than those presented in
% this example. The figure below was created by running the example for
% longer with |maxNumErrors = 1e3|, |maxNumPackets = 1e4|, for all the four
% modes.
%
% <<../BLEBERExample.png>>

%% Summary
% This example simulates a BLE physical layer link over an AWGN channel. It
% shows how to generate BLE waveforms, demodulate and decode bits using an
% ideal receiver and compute the BER.

%% Selected Bibliography
% # Volume 6 of the Bluetooth Core Specification, Version 5.0 Core System
% Package [Low Energy Controller Volume].