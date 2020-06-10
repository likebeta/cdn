#!/usr/bin/env bash
# -*- coding=utf-8 -*-

mv /etc/apt/sources.list /etc/apt/sources.list.bak
wget -O /etc/apt/sources.list https://cdn.jsdelivr.net/gh/likebeta/cdn@master/script/ubuntu-20.04.list
apt update
