%% Check for Support Package Installation

% Check if the 'Communications Toolbox Library for the Bluetooth Protocol'
% support package is installed or not.
commSupportPackageCheck('BLUETOOTH');

%% Initialize the Simulation Parameters
EbNo = -2:2:12;                        % Eb/No range in dB
% EbNo = [EbNo 8.2 8.4 8.6 8.8 9];
sps = 4;                              % Samples per symbol
dataLen = 2080;                       % Data length in bits
simMode = {'LE1M','LE2M','LE500K','LE125K'};

% Max_CFO_tab=[ 10e3 10e4 1.2*10e4 1.4*10e4];
Max_CFO=56*10e2;
Max_CFO_tab=zeros(1,3);
Max_CFO_tab(1)=0;
for k=1:3
  % Max_CFO_tab(k)=unifrnd(10e4,Max_CFO);
   Max_CFO_tab(k)=-56*10e2+(2*Max_CFO)*rand(1);
   
end

Max_CFO_tab(1)=11825;
Max_CFO_tab(2)=11925;
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

maxNumErrors = 1; % Maximum number of bit errors at an Eb/No point
maxNumPackets = 30; % Maximum number of packets at an Eb/No point

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

for i_offset = 1:2%length(Max_CFO_tab)-1
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
        numpaquet=0;
        numPkt = 1; % Index of packet transmitted
        while numPkt < maxNumPackets

            % Generate BLE waveform
            txBits = randi([0 1],dataLen,1,'int8'); % Data bits generation
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
            numErrs = errors(2);
            if(numErrs>0)
              numpaquet=numpaquet+1;
            end
            numPkt = numPkt + 1;
        end
        numErrs 
        numpaquet
        ber(i_offset,iSnr) =numpaquet/maxNumPackets 

    end
end

%% Plot BER vs Eb/No Results
ber(1,7)=0.0001;
ber(2,7)=0.0001;
markers = 'ox*s';
color = 'bmcr';
dataStr = {zeros(length(Max_CFO_tab)-1,1)};
figure;
for iMode = 1:length(Max_CFO_tab)-1
    semilogy(EbNo,ber(iMode,:).',['-' markers(iMode) color(iMode)]);
    hold on;
    Legend='Max CFO de  ';
    dataStr(iMode) = {strcat(Legend,int2str(Max_CFO_tab(iMode)))};
end
grid on;
xlabel('Eb/No (dB)');
ylabel('PER');
legend(dataStr);
title('PER for BLE with AWGN channel');

%% Calcul du TEP




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