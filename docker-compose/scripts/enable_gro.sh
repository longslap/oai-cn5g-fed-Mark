#!/bin/bash

# Parse veth interfaces from the output of `ip a | grep demo-n`
interfaces=$(ip a | grep demo-n | grep -oP 'veth[^@]+')

for interface in $interfaces; do
    # Skip the interface with "ran0"
    if [[ "$interface" == "vethran0" ]]; then
        echo "Skipping interface: $interface"
        continue
    fi

    # Enable GRO on the interface
    echo "Enabling GRO on interface: $interface"
    sudo ethtool -K "$interface" gro on

    # Check the result
    if [[ $? -eq 0 ]]; then
        echo "GRO enabled successfully on $interface"
    else
        echo "Failed to enable GRO on $interface"
    fi
done
