#!/bin/bash

echo checking if this is running on a Raspberry Pi

model="$( cat /proc/device-tree/model )" 2>> $HOME/error.log
onpi="no"
if [[ "$model" == *"Raspberry Pi"* ]]; then
    echo "This is actually a Raspberry Pi!"
    onpi="yes"
fi

# If nothing in /proc/device-tree/model:
if [[ "$model" == "" ]]; then
    echo "I have no idea what this machine is!"
    model="computer of some sort"
fi

# Check if on RPi before doing stuff specific to Pi
if [[ $onpi == "yes" ]]; then
    # Update:
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
    sudo apt install vim -y
    
    # TODO check if already done before sedding
    # Turn off camera autodetect
    sudo sed -i 's/camera_auto_detect=0/camera_auto_detect=1/g' /boot/firmware/config.txt
    
    # set camera type to imx477
    sudo sed -i 's/\[all\]/\[all\]\ndtoverlay=imx477/' /boot/firmware/config.txt

    # make timelapse directory
    mkdir -p $HOME/timelapse

    # make timelapse shell script
    cat <<EOF > $HOME/timelapser.sh
#!/bin/bash
sleep 180
rpicam-still --timeout 3000000 --timelapse 2000 -o timelapse/image%04d.jpg
EOF

    # make timelapser service
    cat <<EOF | sudo tee /etc/systemd/system/timelapser.service
[Unit]
Description=imx477 intervalometer setup
After=network.target

[Service]
ExecStart=$HOME/timelapser.sh
WorkingDirectory=$HOME
StandardOutput=inherit
StandardError=inherit
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl start timelapser.service
    sudo systemctl enable timelapser.service
    
    echo Configuration complete. Please reboot to start timelapse.

fi
