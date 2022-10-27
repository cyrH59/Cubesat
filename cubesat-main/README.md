# The Cubesat Project

![alt text](https://github.com/eliasenseirb/cubesat/blob/main/img/CubeSatlogo.png?raw=true)

## Introduction

A cubesat is a nanosatellite, its dimension is a 10cm-length cube. A cube of this size is also called a 1U. These satellites are located in the Low Earth Orbit (LEO) which is between 200 and 2 000 km above Earth. The main goal of this project is to establish a communication between an IoT device and the Cubesat. There are 2 main interactions: a beacon is sending a signal to the satellite and under precise conditions the satellite will answer with a Bluetooth message that will be broadcasted.

This project is split in several parts:	
-	[Mission 1] is composed with the functions that creates the chirp signal and that uses a Matlab interface that simulates the satellites position
-	[Mission 2] simulates the Bluetooth low energy ([BLE]) physical layer (PHY). The specifications are BLE S8 125K which means a coded version with 8 symbols and a bit rate of 125 kbits/s.
-	[Demonstrator] which is based on the Eddystone TLM code. This section made the part about BLE possible thanks to the advertising mode.

## Mission 1

In this section a specific chirp signal is modulated with [CSS] (Chirp Spread Spectrum) or DCSS (Differential CSS) which is more optimized. In this specific part we also plan to estimate the Doppler shift and the Doppler rate.
Another key feature will be the location program that estimates the position from the chirp sent. The principle is based on the least square method like Argos’ location algorithm.

The interface was made by an elder student and thanks to his work the simulation of any chirp signal at any position is possible and simple to use.

## Mission 2

In the Communications Toolbox of Matlab there are examples program of BLE transceiver and receiver. These programs are the cement of our code. Every part of the PHY is implemented. The signals used in this part comes from a ADALM PLUTO transceiver.
The functionalities planned are a Doppler shift and a time and frequency synchronization at the receiver. There also is a specific part on an alert signal which is sent if the location of the transceiver is in a dangerous place.

## Demonstrator

This consist of a sample program that uses the advertising mode of Bluetooth to broadcast data to IoT devices around the beacon. One specificity of the advertising mode is that the device doesn’t need to be bounded to the beacon to read the data. Thanks to this, everyone can be aware of a potential danger if the data comes to be at certain values. 
The program is based on the [Eddystone TLM] template from google. Instead of sharing the temperature or any information from the beacon, the position of the emitter of the chirp signal is spread.
One key feature to implement would be a notification mode that would be linked to another app like a Telegram bot, but this is still to be made.

## Contributions

Thanks to every member of the group that did a great job and thanks to the elder students that contributed to part 1 with the chirp signal and the interface. Having codes was a great starting point.


   [Mission 1]: <https://github.com/eliasenseirb/cubesat/tree/main/Mission%201>
   [Mission 2]: <https://github.com/eliasenseirb/cubesat/tree/main/Mission%202>
   [Demonstrator]: <https://github.com/eliasenseirb/cubesat/tree/main/Demonstrator>
  [CSS]: <https://en.wikipedia.org/wiki/Chirp_spread_spectrum>
  [BLE]: <https://en.wikipedia.org/wiki/Bluetooth_Low_Energy>
  [Eddystone TLM]: <https://github.com/google/eddystone/tree/master/eddystone-tlm>
