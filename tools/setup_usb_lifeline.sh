#!/bin/sh
# Tab S6 Composite USB Gadget: RNDIS (Ethernet) + ACM (Serial Console)
# Standard Google VID 0x18d1 / PID 0x0106 with Microsoft OS Descriptors
set -e

G=/sys/kernel/config/usb_gadget/g1
UDC=a600000.usb

modprobe libcomposite || true

if [ -d "$G" ]; then
    echo "USB gadget already configured."
    exit 0
fi

CONFIGFS_DIR="/sys/kernel/config"
if ! mountpoint -q "$CONFIGFS_DIR"; then
    mount -t configfs none "$CONFIGFS_DIR" || true
fi

mkdir -p "$G"
cd "$G"

# Identity: Google VID, PID 0x0106
echo 0x18d1 > idVendor
echo 0x0106 > idProduct
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

# Force High-Speed (USB 2.0)
if [ -f max_speed ]; then
    echo "high-speed" > max_speed 2>/dev/null || true
fi

# IAD (composite device: RNDIS + ACM)
echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

mkdir -p strings/0x409
echo "0000deadbeef0000" > strings/0x409/serialnumber
echo "Samsung" > strings/0x409/manufacturer
echo "Galaxy Tab S6 Lifeline" > strings/0x409/product

# Microsoft OS Descriptors (device level)
echo 1 > os_desc/use
echo 0xcd > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

# RNDIS function (network)
mkdir -p functions/rndis.usb0
echo "02:00:00:00:00:0a" > functions/rndis.usb0/dev_addr
echo "02:00:00:00:00:0b" > functions/rndis.usb0/host_addr
echo RNDIS > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

# ACM function (serial console)
mkdir -p functions/acm.GS0

# Configuration
mkdir -p configs/c.1/strings/0x409
echo "RNDIS + ACM Lifeline" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

# Link descriptors and functions to config
ln -s configs/c.1 os_desc/ 2>/dev/null || true
ln -s functions/rndis.usb0 configs/c.1/ 2>/dev/null || true
ln -s functions/acm.GS0 configs/c.1/ 2>/dev/null || true

# Ensure role is set to device before binding
for r in /sys/class/usb_role/*/role; do
    [ -w "$r" ] && echo device > "$r" 2>/dev/null || true
done

# Bind directly to UDC
if [ -d "/sys/class/udc/$UDC" ] || [ -e "/sys/class/udc/$UDC" ]; then
    echo "$UDC" > UDC
    echo "Bound gadget to $UDC"
else
    FOUND_UDC=$(ls /sys/class/udc 2>/dev/null | head -n 1)
    if [ -n "$FOUND_UDC" ]; then
        echo "$FOUND_UDC" > UDC
        echo "Bound gadget to $FOUND_UDC"
    fi
fi

# Configure network interface: Tablet is 192.168.137.2 (PC is 192.168.137.1) + APIPA 169.254.10.2
sleep 1
if /usr/sbin/ip link show usb0 >/dev/null 2>&1 || ip link show usb0 >/dev/null 2>&1; then
    ip link set usb0 up || /usr/sbin/ip link set usb0 up || true
    ip addr flush dev usb0 2>/dev/null || /usr/sbin/ip addr flush dev usb0 2>/dev/null || true
    ip addr add 192.168.137.2/24 dev usb0 || /usr/sbin/ip addr add 192.168.137.2/24 dev usb0 || true
    ip addr add 169.254.10.2/16 dev usb0 || /usr/sbin/ip addr add 169.254.10.2/16 dev usb0 || true
    echo "Configured usb0 with 192.168.137.2/24 and 169.254.10.2/16"
    
    if [ -x /usr/sbin/dnsmasq ] || command -v dnsmasq >/dev/null 2>&1; then
        killall dnsmasq 2>/dev/null || true
        dnsmasq --interface=usb0 --bind-interfaces --dhcp-range=192.168.137.100,192.168.137.200,255.255.255.0,1h --no-daemon &
        echo "Started dnsmasq DHCP on usb0"
    fi
fi

echo "USB Lifeline gadget initialized successfully."
