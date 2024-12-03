#!/bin/bash

echo "*** Samsung Electronics A-DEVICE WSL Environment Setup ***"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Kernel version checking process
# To use usbipd, minimum kernel of wsl should be above 5.15

MIN_KERNEL_VERSION="5.15"
MY_KERNEL_VERSION=$(uname -r | awk -F'-' '{print $1}')

CURRENT_USER=$SUDO_USER
HOME_USER="/home/$CURRENT_USER"

version_compare() {
    IFS='.' read -r -a ver1 <<< "$1"
    IFS='.' read -r -a ver2 <<< "$2"

    for ((i=0; i<3; i++)); do
        ver1_num=${ver1[i]}
        ver2_num=${ver2[i]}

        if [[ -z "$ver1_num" ]]; then
            ver1_num=0
        fi
        if [[ -z "$ver2_num" ]]; then
            ver2_num=0
        fi

        if [ "$ver1_num" -gt "$ver2_num" ]; then
            return 1
        elif [ "$ver1_num" -lt "$ver2_num" ]; then
            return 2
        fi
    done

    return 0
}

version_compare $MY_KERNEL_VERSION $MIN_KERNEL_VERSION
KERNEL_CHECK_RESULT=$?

if [[ $COMPARE_RESULT -eq 2 ]]; then
    echo "Error: Kernel version is $MY_KERNEL_VERSION. Minimum required version is $MIN_KERNEL_VERSION."
    exit 1
else
    echo "Kernel version is $MY_KERNEL_VERSION. Proceeding..."
fi


inject_string_to_file() {
    local file="$1"
    local search_string="$2"

    # create file if not exist
    if [ ! -f "$file" ]; then
        touch "$file"
        echo "File $file created."
    fi

    # search string from file
    if grep -Fxq "$search_string" "$file"; then
        echo "The string is already present in $file"
    else
        echo "$search_string" >> "$file"
        echo "The string has been added to $file"
    fi
}

# # DNS setup
# cd $HOME_USER
# echo "DNS setup"
# WSL_CONF="/etc/wsl.conf"
# inject_string_to_file "$WSL_CONF" "[network]"
# inject_string_to_file "$WSL_CONF" "generateResolvConf = false"

# RESOLV_CONF="/etc/resolv.conf"
# inject_string_to_file "$RESOLV_CONF" "nameserver 12.26.2.228"
# chattr +i /etc/resolv.conf


# # Adding proxy if it is not configured
# cd $HOME_USER
# echo "Adding bash proxy configuration..."
# BASHRC_FILE="/home/$CURRENT_USER/.bashrc"

# inject_string_to_file "$BASHRC_FILE" "export http_proxy=http://12.26.204.100:8080"
# inject_string_to_file "$BASHRC_FILE" "export https_proxy=http://12.26.204.100:8080"
# inject_string_to_file "$BASHRC_FILE" "export no_proxy=127.0.0.1,::1,localhost,samsung.com,samsungds.net,*.samsung.com,*.samsungds.net,12.0.0.0/8,10.0.0.0/8,192.0.0.0/8,172.0.0.0/8"

# export http_proxy=http://12.26.204.100:8080
# export https_proxy=http://12.26.204.100:8080
# export no_proxy=127.0.0.1,::1,localhost,samsung.com,samsungds.net,*.samsung.com,*.samsungds.net,12.0.0.0/8,10.0.0.0/8,192.0.0.0/8,172.0.0.0/8

# cd $HOME_USER
# source .bashrc

# # Install certificate
# echo "Install samsung certificate to system"
# #rm samsungsemi-prx.crt
# wget https://mwebdev.samsungds.net/static/files/samsungsemi-prx.crt --no-check-certificate
# sudo cp -f samsungsemi-prx.crt /usr/local/share/ca-certificates/samsungsemi-prx.crt
# update-ca-certificates

# # Add apt proxy setting
# APT_PROXY_FILE="/etc/apt/apt.conf.d/proxy.conf"
# inject_string_to_file "$APT_PROXY_FILE" "Acquire::http::Proxy \"http://12.26.204.100:8080\";"
# inject_string_to_file "$APT_PROXY_FILE" "Acquire::https::Proxy \"http://12.26.204.100:8080\";"

echo "Install packages from apt. it will take few minutes"
apt update
apt install git make cmake libusb-1.0-0-dev gcc build-essential protobuf-compiler libncurses-dev jq python3-pip unzip libxrender1 libxtst6 libxi6

echo "Install compiler from ARM."
cd $HOME_USER
wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2
tar xjf gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 -C /usr/share/
ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-gcc /usr/bin/arm-none-eabi-gcc 
ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-g++ /usr/bin/arm-none-eabi-g++
ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-gdb /usr/bin/arm-none-eabi-gdb
ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-size /usr/bin/arm-none-eabi-size
ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-objcopy /usr/bin/arm-none-eabi-objcopy
ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-objdump /usr/bin/arm-none-eabi-objdump
ln -s /usr/share/gcc-arm-none-eabi-10.3-2021.10/bin/arm-none-eabi-nm /usr/bin/arm-none-eabi-nm
ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5
rm gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2

echo "Install openocd to user space"
cd $HOME_USER
wget https://github.com/xpack-dev-tools/openocd-xpack/releases/download/v0.12.0-3/xpack-openocd-0.12.0-3-linux-x64.tar.gz
tar -xzvf xpack-openocd-0.12.0-3-linux-x64.tar.gz 
chown -R $CURRENT_USER:$CURRENT_USER xpack-openocd-0.12.0-3 
rm xpack-openocd-0.12.0-3-linux-x64.tar.gz 

echo "Grant all usb device permission for user"

RULES_FILE="/etc/udev/rules.d/99-usb-permissions.rules"

create_udev_rules() {
    local username="$1"
    local rules_file="$2"

    echo "Creating udev rules file at $rules_file..."

    bash -c "cat > $rules_file <<EOF
# Set permissions for all USB devices
SUBSYSTEM==\"usb\", ATTR{idVendor}==\"*\", ATTR{idProduct}==\"*\", MODE=\"0666\", OWNER=\"$username\", GROUP=\"plugdev\"
EOF"
}

service udev restart

# Function to reload udev rules
reload_udev_rules() {
    echo "Reloading udev rules and triggering..."
    udevadm control --reload-rules
    udevadm trigger
}

# Function to add the user to the plugdev group
add_user_to_plugdev() {
    local username="$1"
    echo "Adding user $username to plugdev group..."
    usermod -aG plugdev "$username"
}

create_udev_rules "$CURRENT_USER" "$RULES_FILE"
reload_udev_rules
add_user_to_plugdev "$CURRENT_USER"
echo "Done. $CURRENT_USER can now access all USB devices."

# 설정 파일 경로 정의
SETTINGS_DIR="/home/$CURRENT_USER/.vscode-server/data/Machine"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# 설정 파일이 있는지 확인하고, 없으면 폴더와 파일 생성
if [ ! -d "$SETTINGS_DIR" ]; then
    echo "Directory $SETTINGS_DIR does not exist. Creating..."
    mkdir -p "$SETTINGS_DIR"
fi

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "File $SETTINGS_FILE does not exist. Creating..."
    echo "{}" > "$SETTINGS_FILE"
fi

# 설정 파일 수정 (cortex-debug.openocdPath 설정 추가)
jq '.["cortex-debug.openocdPath"] = "${env:HOME}/xpack-openocd-0.12.0-3/bin/openocd"' "$SETTINGS_FILE" > "$SETTINGS_DIR/settings.tmp" && mv "$SETTINGS_DIR/settings.tmp" "$SETTINGS_FILE"

chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/.vscode-server

echo "Settings updated successfully."


# echo "Python package manager proxy setup"
# cd $HOME_USER
# mkdir .pip
# PIP_CONF="/home/$CURRENT_USER/.pip/pip.conf"

# inject_string_to_file "$PIP_CONF" "[global]"
# inject_string_to_file "$PIP_CONF" "index-url = http://repo.samsungds.net/artifactory/api/pypi/pypi-remote/simple"
# inject_string_to_file "$PIP_CONF" "trusted-host = repo.samsungds.net"
# inject_string_to_file "$PIP_CONF" "proxy ="

# pip install protobuf==4.25.3

# cd $HOME_USER
# mkdir Workspace
# cd Workspace
# git clone -c http.sslVerify=false --recursive https://github.samsungds.net/A-Project/A-DEVICE a-device

# chown -R $CURRENT_USER:$CURRENT_USER /home/$CURRENT_USER/Workspace

# read -p "Default setting had done. Do you want to install STM32CubeMX on linux? [Y/n] " input

# input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')

# # 입력값 검사
# if [[ "$input_lower" == "y" || "$input_lower" == "yes" ]]; then
#     cd $HOME_USER/Workspace/a-device/Scripts
#     chmod +x ubuntu_cubemx.sh
#     ./ubuntu_cubemx.sh
# else
#     echo "Skip STM32CubeMX installation"
# fi
