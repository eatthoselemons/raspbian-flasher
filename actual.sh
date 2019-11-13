#!/bin/bash
let flash=1 #true
let balena=0 #false
let wifi=0 #false


OStype=$(uname -s)
case $OStype in
  (Linux) OS="linux";;
  (Mac)   OS="mac";;
  (Windows) OS="windows";;
  (*)     OS="unknown";;
esac

echo "You are running $OS"

if [ $OS = "windows" ];
  then
    echo Windows is not supported
    exit 1
fi 

if [ $OS = "unknown" ];
  then
    echo "Don't know what OS this is"
    exit 1
fi 

echo "Does the card need flashing? Y/n"
read flashAnswer

echo $flashAnswer
if [[ "$flashAnswer" =~ ^([nN][oO]|[nN])+.*$ ]]
then
  let flash=0
  echo "no"
  echo $flash
else
  let flash=1
  echo "yes"
  echo $flash
fi

echo "Do you need wifi? Y/n"
read wifiAnswer

if [[ "$wifiAnswer" =~ ^([nN][oO]|[nN])+.*$ ]]
then
  let wifi=0
  echo "adding no wifi"
else
  let wifi=1
  echo "password?"
  read -s password
  echo "wifi name/ssid?"
  read wifiName
fi


echo "country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
ssid="$wifiName"
psk="$password"
}" > ~/raspbian-script/wifi

if [[ -f ~/raspbian-script/raspbian-latest.zip ]];
then
  echo "Raspbian is already downloaded"
else
  if [[ -d ~/raspbian-script ]];
  then
    echo "Rasbian directory already exists"
  else
    mkdir ~/raspbian-script
  fi
  echo "Downloading Raspbian"
  cd ~/raspbian-script
  wget --output-file=raspbian-latest.zip 'https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-09-30/2019-09-26-raspbian-buster-lite.zip' 
fi

if command -v balena >> /dev/null;
then
  echo "balena etcher is installed"
  balena=1
else
  echo "downloading balena etcher"
  cd ~/raspbian-script
  wget --output-file=balena-cli.zip 'https://github.com/balena-io/balena-cli/releases/download/v11.17.3/balena-cli-v11.17.3-linux-x64-standalone.zip' > /dev/stdout
  unzip balena-cli.zip
  balena=0
fi

if [[ $flash = 1 ]];
then
  echo "==========================================="
  echo "balena installed "$balena

  if [[ $OS = "linux" ]];
  then
    if sudo fdisk -l >> /dev/null;
    then
      sudo fdisk -l
      echo "Which disk to use? input format 'sd'letter or sd[a-z]"
      read disk
    else
      echo "fdisk not supported on this version of linux"
    fi
  fi


  if [[ $OS = "mac" ]];
  then
    if diskpart list;
    then
      diskpart list
      echo "Which disk to use? Input format 'disk'number or 'disk[0-9]'"
      read disk
    else
      echo "diskpart not supported on this version of macOS"
    fi
  fi

  echo "==========================================="

  echo "flashing disk: $disk"

  if [[ $balena = 1 ]]
  then
    sudo balena local flash ~/raspbian-script/raspbian_latest.zip --drive /dev/$disk > /dev/stdout
  else
    sudo ~/raspbian-script/balena-cli/balena local flash ~/raspbian-script/raspbian-latest.zip --drive /dev/$disk > /dev/stdout
  fi
  tput setaf 2; echo :fox: "SD Card flashed and verified succesfully."
fi


if [[ $OS = "linux" ]];
then
  sudo fdisk -l
  echo "select formatted disk"
  read disk
  clear
  sudo fdisk -l /dev/$disk
  echo "Select disk boot partition (probably smaller one) example: 'sd[a-z][0-9]'"
  read diskBootPartition
  echo "Select disk user partition (probably larger one) example: 'sd[a-z][0-9]'"
  read diskUserPartition
  if [[ ! -d /mnt/raspbian ]];
  then
    sudo mkdir /mnt/raspbian
  fi
  sudo mount /dev/$diskBootPartition /mnt/raspbian
  echo "adding ssh"
  sudo touch /mnt/raspbian/ssh
  sudo umount /mnt/raspbian
  sudo mount /dev/$diskUserPartition /mnt/raspbian
  if [[ wifi = 1 ]]
  then
    echo "adding wifi"
    sudo cp ~/raspbian-script/wifi /mnt/raspbian/etc/wpa_supplicant/wpa_supplicant.conf
    sudo umount /mnt/raspbian
  fi
fi

if [[ $OS = "mac" ]];
then
  echo "select formatted disk"
  diskutil list
  read disk
  diskutil list $disk
  echo "Select disk boot partition (probably smaller one) example: 'disk2s1'"
  read diskBootPartition
  echo "Select disk user partition (probably larger one) example: 'disk2s1'"
  read diskUserPartition
  sudo touch /dev/diskBootPartition/ssh
  if [[ wifi = 1 ]]
  then
    sudo cp ~/raspbian-script/wifi /dev/diskUserParition/etc/wpa_supplicant/wpa_supplicant.conf
  fi
fi

rm ~/raspbian-script/wifi

echo "finished"
