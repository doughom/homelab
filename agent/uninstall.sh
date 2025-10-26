#!/bin/bash

rm /etc/systemd/system/ansible-agent.service
rm /etc/systemd/system/ansible-agent.timer
systemctl daemon-reload
rm -rf /etc/ansible-agent
rm -rf /usr/local/ansible-agent
