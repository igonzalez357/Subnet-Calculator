#!/bin/bash

#########################
### 1. Error function ###
#########################

function error_function(){
    echo -e "\n[-] Error: $1"
    echo -e "\n\tUsage: $0 <IP_ADDRESS/SUBNET_MASK>"
    echo -e "\tExample: $0 192.168.1.0/24\n"
    exit 1
}

####################################
### 2. Validate syntax and parse ###
####################################

if [[ -z $1 ]]; then 
	error_function "No input provided."
fi

ip_address=$(echo "$1" | cut -d/ -f1)
subnet_range=$(echo "$1" | cut -d/ -f2)
oct_count=$(awk -F. '{print NF}' <<< "$ip_address")

if [[ -z $ip_address || -z $subnet_range || "$ip_address" == "$subnet_range" ]]; then
    error_function "IP address or subnet range not provided."

elif ! [[ $subnet_range =~ ^[0-9]{1,2}$ ]] || (( subnet_range > 32 || subnet_range < 0 )); then
    error_function "Subnet mask must be a number between 0 and 32."

elif ((oct_count != 4 )); then
    error_function "IP must have exactly 4 octets."
fi

IFS='.' read -r oct1 oct2 oct3 oct4 <<< "$ip_address"

# Octets' validation
for oct in "$oct1" "$oct2" "$oct3" "$oct4"; do
    if ! [[ $oct =~ ^[0-9]+$ ]] || (( oct < 0 || oct > 255 )); then
        error_function "Octets must be numeric and between 0-255."
    fi
done

if (( oct1 < 1 )); then
	error_function "First octet must be between 1 and 255.";
fi

##########################################
### 3. Calculate subnet data and print ###
##########################################

RED=$'\e[0;31m'
NC=$'\e[0m'

binary_representation=$(printf '%08d' $(echo "obase=2; $oct1" | bc) $(echo "obase=2; $oct2" | bc) $(echo "obase=2; $oct3" | bc) $(echo "obase=2; $oct4" | bc))

# Coloured printed mask
colored_bin_dotted=""
for (( i=0; i<32; i++ )); do
    if [[ $i -gt 0 && $((i%8)) -eq 0 ]]; then
    	colored_bin_dotted+="."
    fi
    if [[ $i -eq "$subnet_range" ]]; then
    	colored_bin_dotted+="${RED}"
    fi
    colored_bin_dotted+="${binary_representation:$i:1}"
done
colored_bin_dotted+="${NC}"

printf "\n\t%-25s %s\n" "IP address to parse:" "$ip_address/$subnet_range"
printf "\t%-25s %b\n" "Binary representation:" "$colored_bin_dotted"

# Net Mask y Wildcard Mask
m_octs=()
w_octs=()
temp_mask=$subnet_range

for i in {1..4}; do
    if (( temp_mask >= 8 )); then
        m_octs+=("255")
        temp_mask=$(( temp_mask - 8 ))
    elif (( temp_mask > 0 )); then
        # Octet value is 256 - 2^(host bits)
        m_octs+=( $(( 256 - 2**(8 - temp_mask) )) )
        temp_mask=0
    else
        m_octs+=("0")
    fi
    # Wildcard value is 255 - mask value
    w_octs+=( $(( 255 - ${m_octs[$i-1]} )) )
done

net_mask="${m_octs[0]}.${m_octs[1]}.${m_octs[2]}.${m_octs[3]}"
wildcard_mask="${w_octs[0]}.${w_octs[1]}.${w_octs[2]}.${w_octs[3]}"

printf "\n\t\t%-17s %s\n" "Net mask:" "$net_mask"
printf "\t\t%-17s %s\n" "Wildcard Mask:" "$wildcard_mask"

# Cálculo de Network ID
network_bits="${binary_representation:0:$subnet_range}"
host_bits_count=$((32 - subnet_range))

printf -v zeros '%0*d' "$host_bits_count" 0
net_id_bin="${network_bits}${zeros}"

n_oct1=$((2#${net_id_bin:0:8}))
n_oct2=$((2#${net_id_bin:8:8}))
n_oct3=$((2#${net_id_bin:16:8}))
n_oct4=$((2#${net_id_bin:24:8}))

printf "\t\t%-17s %d.%d.%d.%d\n" "Network ID:" "$n_oct1" "$n_oct2" "$n_oct3" "$n_oct4"

# Cálculo de Broadcast ID
broad_id_bin="${net_id_bin//0/1}"
ones="${zeros//0/1}"
broad_id_bin="${network_bits}${ones}"

b_oct1=$((2#${broad_id_bin:0:8}))
b_oct2=$((2#${broad_id_bin:8:8}))
b_oct3=$((2#${broad_id_bin:16:8}))
b_oct4=$((2#${broad_id_bin:24:8}))

printf "\t\t%-17s %d.%d.%d.%d\n" "Broadcast ID:" "$b_oct1" "$b_oct2" "$b_oct3" "$b_oct4"

# Total and Usable Hosts
total_hosts=$(( 1 << host_bits_count ))
usable_hosts=$(( total_hosts > 2 ? total_hosts - 2 : 0 ))

printf "\t\t%-17s %s\n" "Total Hosts:" "$total_hosts"
printf "\t\t%-17s %s\n" "Usable Hosts:" "$usable_hosts"

# Host range calculation
if [[ $subnet_range -le 30 ]]; then
    first_host="$n_oct1.$n_oct2.$n_oct3.$((n_oct4 + 1))"
    last_host="$b_oct1.$b_oct2.$b_oct3.$((b_oct4 - 1))"
    host_range="$first_host - $last_host"
elif [[ $subnet_range -eq 31 ]]; then
    host_range="Point-to-Point link"
else
    host_range="None (Single Host)"
fi

printf "\t\t%-17s %s\n" "Host Range:" "$host_range"

# Private or Public clasification
type_ip="Public"
if [[ $oct1 -eq 10 ]]; then
    type_ip="Private (Class A)"
elif [[ $oct1 -eq 172 && $oct2 -ge 16 && $oct2 -le 31 ]]; then
    type_ip="Private (Class B)"
elif [[ $oct1 -eq 192 && $oct2 -eq 168 ]]; then
    type_ip="Private (Class C)"
elif [[ $oct1 -eq 127 ]]; then
    type_ip="Loopback"
fi

printf "\t\t%-17s %s\n" "IP Type:" "$type_ip"

# Hex representation of IP
ip_hex=$(printf '%02X.%02X.%02X.%02X' "$oct1" "$oct2" "$oct3" "$oct4")

printf "\t\t%-17s %s\n" "IP Hex:" "$ip_hex"
echo ""
