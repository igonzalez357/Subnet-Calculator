# SubnetCalc Bash

A professional IPv4 subnet calculator written in **Bash**. Designed for network administrators and IT students who need precise, fast, and visual information about IP addressing and subnetting.

## Features

- **Dynamic Binary Visualization:** Binary representation with the host portion highlighted in **red** based on the CIDR prefix.
- **Comprehensive Calculations:**
  - Subnet Mask & Wildcard Mask.
  - Network ID & Broadcast Address.
  - Usable Host Range.
  - Total and Usable host counters.
- **Extended Context:**
  - IP Classification (Public, Private, Loopback).
  - Legacy Networking Classes (A, B, C).
  - Hexadecimal representation.

## Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/igonzalez357/subnetting-calculator.git](https://github.com/igonzalez357/subnetting-calculator.git)
   cd subnetting-calculator
   ```
2. Grant execution permissions:
   ```bash
   chmod +x subnetCalc.sh
   ```
## Usage
Run the script by passing an IP address in CIDR notations as an argument
   ```bash
   ./subnetCalc.sh 192.168.1.0/24
   ```
## Sample Output
   ```
   IP address to parse:      192.168.1.0/24
	Binary IP:                11000000.10101000.00000001.00000000

		Net mask:         255.255.255.0
		Wildcard Mask:    0.0.0.255
		Network ID:       192.168.1.0
		Broadcast ID:     192.168.1.255
		Total Hosts:      256
		Usable Hosts:     254
		Host Range:       192.168.1.1 - 192.168.1.254
		IP Type:          Private (Class C)
		IP Hex:           C0.A8.01.00
   ```
   
