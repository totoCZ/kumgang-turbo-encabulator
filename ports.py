#!/usr/bin/env python3

import subprocess
import re
import sys

def get_listening_ports(container_name):
    """
    Retrieves listening TCP and UDP ports (both IPv4 and IPv6) from a 
    specified Docker container.

    Args:
        container_name: The name or ID of the Docker container.

    Returns:
        A list of dictionaries, where each dictionary represents a listening port 
        and contains the following keys:
            - 'protocol': 'tcp' or 'udp'
            - 'local_address': The local IP address (IPv4 or IPv6).
            - 'local_port': The local port number.
    """
    listening_ports = []

    for protocol in ['tcp', 'tcp6', 'udp', 'udp6']:
        try:
            # Execute cat command inside the container
            result = subprocess.run([
                'docker', 'exec', container_name, 'cat', f'/proc/net/{protocol}'
            ], capture_output=True, text=True, check=True)

            # Parse the output
            lines = result.stdout.strip().split('\n')[1:]  # Skip header
            for line in lines:
                parts = line.split()
                local_address_hex = parts[1]
                state_hex = parts[3]

                # Check if it is a listening port (TCP state 0A is LISTEN)
                if protocol.startswith('tcp') and state_hex != '0A':
                    continue

                # Convert local address and port from hexadecimal to decimal
                ip_hex, port_hex = local_address_hex.split(':')
                
                if len(ip_hex) == 8:
                    # IPv4
                    ip_parts = [str(int(ip_hex[i:i+2], 16)) for i in range(6, -1, -2)]
                    local_ip = '.'.join(ip_parts)
                elif len(ip_hex) == 32:
                    # IPv6 - insert : after every 4 characters
                    ip_parts = [ip_hex[i:i+4] for i in range(0, 32, 4)]
                    local_ip = ':'.join(ip_parts)
                    # Remove leading zeros from each part for cleaner output
                    local_ip = ':'.join(part.lstrip('0') for part in local_ip.split(':'))
                    local_ip = re.sub(r":{2,}", "::", local_ip)  # Replace multiple colons with double colons
                    local_ip = local_ip if local_ip else "::" # handle the case where all parts are zero
                else:
                    print(f"Warning: Skipping invalid address format: {ip_hex}")
                    continue

                local_port = int(port_hex, 16)

                listening_ports.append({
                    'protocol': protocol,
                    'local_address': local_ip,
                    'local_port': local_port,
                })

        except subprocess.CalledProcessError as e:
            print(f"Error reading /proc/net/{protocol} in container {container_name}: {e}")

    return listening_ports

# Get container name from user input
#container_name = input("Enter the name or ID of the Docker container: ")
try:
    container_name = sys.argv[1]
except:
    print('lol monky enter name')
    sys.exit(1)
    
ports = get_listening_ports(container_name)

# Print the results
print(f"Listening ports in container '{container_name}':")
print("---------------------------------")
print("Proto Local Address           Port")
for port_info in ports:
    print(
        f"{port_info['protocol']:<5} "
        f"{port_info['local_address']:<21} "
        f"{port_info['local_port']:<6} "
    )
