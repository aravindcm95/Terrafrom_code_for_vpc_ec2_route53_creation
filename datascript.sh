#!/bin/bash

echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
systemctl restart sshd.service