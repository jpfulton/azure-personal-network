#!/usr/bin/env bash

CA_CN="Personal Network OpenVPN CA";

sudo make-cadir /etc/openvpn/easy-rsa;
sudo chmod a+rx /etc/openvpn/easy-rsa;
cd /etc/openvpn/easy-rsa;
sudo ./easyrsa init-pki;
( echo "$CA_CN"; ) | sudo ./easyrsa build-ca nopass;
sudo ./easyrsa gen-dh;
sudo ./easyrsa build-server-full openvpn-server nopass;
sudo cp pki/dh.pem pki/ca.crt pki/issued/openvpn-server.crt pki/private/openvpn-server.key /etc/openvpn/;

cd /etc/openvpn;
sudo openvpn --genkey secret ta.key;

