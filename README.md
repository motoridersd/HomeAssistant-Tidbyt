# HomeAssistant-Tidbyt

A collection of .star files and scripts to integrate a Tidbyt with Home Assistant.

There is no native way to allow these two to communicate, so I have been using [pixlet](https://github.com/tidbyt/pixlet) in an LXC container in Proxmox to generate and push webp images to my Tidbyt. I just discovered a new development that allows running a local server with the Tidbyt API [Pixbyt](https://github.com/DouweM/pixbyt) that I need to explore to update what I currently do.

I have three applets:

## Home Assistant Now Playing

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/1f3d775e-3bbb-45cf-a0b3-d764b19e183b)

Using the applet built by drudge: [ha_now_playing](https://github.com/motoridersd/Tidbyt-with-HomeAssistant/blob/main/applets/ha_now_playing)

The applet pulls information from Home Assistant and requires the info below:

- Home Assistant Server URL (the full http address of your local HA address)
- Entity ID (the media player you want to use)
- Token (a long lived token to allow using the Home Assistant API)

The code includes logic to display all kinds of info. I currently use it with a Sonos speaker and it pulls the information, including the album art. When I use the line in of the Play:5, it will show Line In.

## Flights Nearby

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/a0c6fcbf-8c91-453e-9117-13c0c635ecaf)

This app exists in the Tidbyt Community Repository, but I've modified mine with different sources as well as adding my own tail images. The community app has a very limited number of tails, and their approval process is lengthy. My version will also show shapes for aircraft that does not have a tail log. I forget where I got this code from, but it was someone that also modified the original community app by eddiechen

## Solar

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/4a8831a5-3558-4234-90b4-9378f662a47c)

I used the Solar Manager applet (https://github.com/tidbyt/community/tree/main/apps/solarmanagerch) as a source, mainly because I liked the screens implemented in there. I modified it to pull the data from Home Assistant instead of a portal. This allows us to get Home Assistant connected to whatever provider you have (Enphase Envoy in my case, and this data is pulled locally).

## LXC Container running Pixlet

I have a simple Debian container in my Proxmox host where I installed pixlet and authenticated with my account. I have the .star files here and use scripts and services to run the apps and push them to the Tidbyt. This container runs everything as root by default, so if you are using a different user, don't forget to sudo.

The Solar and Flights Nearby apps are run in a bash script that cycles every 4 minutes:

```#!/bin/sh  
while true  
do  
  /usr/local/bin/pixlet render applet.star -o applet.webp
  /usr/local/bin/pixlet push YOURTIDBYTID applet.webp -i AppName
  sleep 240  
done
```
The -i option allows you to install the webp image as an "app" on the Tidbyt so that it stays in rotation. If you don't use the -i switch, the screen will show up once and then disappear. The name of the app is useful for removing it later, using pixlet.

To remove an installed app, you only need to run ```pixlet delete YOURTIDBYTID Appname```

I created a systemd service that runs the scripts so that I can turn them on or off from Home Assistant. Creating a systemd service is pretty easy.

```
[Unit]
Description=Tidbyt Flights Nearby Service
After=network-online.target

[Service]
User=root
ExecStart=/bin/bash /root/flights_nearby.sh
ExecStop=/usr/local/bin/pixlet delete YOURTIDBYTID AppName

[Install]
WantedBy=multi-user.target
```
Notice that the ExecStop action deletes the app from the Tidbyt, so this means that when the service is stopped, the app is removed.

Make sure you run ```systemctl daemon-reload``` and ```systemctl enable service.name```. Start your service with ```systemctl start service.name```

## Use Home Assistant Automations to control your Tidbyt Applets

Since I have my apps running on a Debian container that is on my network, I use the command line switch integration to execute commands on the container via SSH. There might be better ways to do it, but this is simple enough.

You need to generate a set of SSH keys on the host running pixlet. This can be done with the ```ssh-keygen``` command on any Linux distro. Extract the contents of id_rsa (the private key) and put it in Home Assistant. I have it saved as ```config/ssh_keys/ha_key```.

In ```configuration.yaml```, add the command_line entries:

```command_line:
  - switch:
      name: tidbyt_flights_switch
      command_on: "ssh -i /config/ssh_keys/hakey -o 'StrictHostKeyChecking=no' user@host systemctl start flights_nearby.service" 
      command_off: "ssh -i /config/ssh_keys/hakey -o 'StrictHostKeyChecking=no' user@host systemctl stop flights_nearby.service" 
      unique_id: JtF5peKWYHzzwCxZ
    
  - switch:
      name: tidbyt_ha_now_playing_switch
      command_on: "ssh -i /config/ssh_keys/hakey -o 'StrictHostKeyChecking=no' user@host bash /root/ha_now_playing_local.sh"
      command_off: "ssh -i /config/ssh_keys/hakey -o 'StrictHostKeyChecking=no' user@host bash /root/delete_now_playing_app.sh"
      unique_id: kAznHGGwGC3MR8xC
```

The unique_ids are random strings added so that Home Assistant doesn't complain.

I have a paid FlightRadar API that is limited to 10,000 hits. To avoid going over and incurring overages, I enable/disable the applet using a Home Assistant presence sensor. When I'm in my Office, the service is turned on. When I leave, it is turned off. 

The Now Playing App does not run as a service, instead I have a Home Assistant Automations that will turn the switch on when my speaker starts playing, or when the song changes. Use the media_player entity you are interested in tracking.

```
alias: >-
  Trigger New Now Playing Screen on Tidbyt when track changes or music starts
  playing
description: ""
trigger:
  - platform: state
    entity_id:
      - media_player.office_2
    attribute: media_title
  - platform: state
    entity_id:
      - media_player.office_2
    to: playing
condition: []
action:
  - service: switch.turn_off
    data: {}
    target:
      entity_id: switch.tidbyt_ha_now_playing_switch
  - delay:
      hours: 0
      minutes: 0
      seconds: 5
      milliseconds: 0
  - service: switch.turn_on
    data: {}
    target:
      entity_id: switch.tidbyt_ha_now_playing_switch
  - repeat:
      while:
        - condition: state
          entity_id: switch.tidbyt_ha_now_playing_switch
          state: "off"
      sequence:
        - service: switch.turn_on
          data: {}
          target:
            entity_id: switch.tidbyt_ha_now_playing_switch
    enabled: false
mode: single
```

A different automation turns the switch off when playback stops

```alias: Tidby Now Playing Off when speaker stops playing
description: ""
trigger:
  - platform: state
    entity_id:
      - media_player.office_2
    from: playing
condition: []
action:
  - service: switch.turn_off
    data: {}
    target:
      entity_id: switch.tidbyt_ha_now_playing_switch
mode: single
```

The Flights Nearby presence automations. My airport doesn't allow flights between midnight and 6 am, so I added a time/date check. I used 10 PM because I usually am not in my office after that time, but I often walk in before 6 AM. Considering it's based on presence, it's really not necessary and might take it out later.

```
alias: Turn Tidbyt Flight Tracker On
description: ""
trigger:
  - platform: state
    entity_id:
      - binary_sensor.signify_netherlands_b_v_sml003_occupancy
    from: "off"
    to: "on"
condition:
  - condition: time
    after: "06:00:00"
    before: "22:00:00"
    weekday:
      - sun
      - mon
      - tue
      - wed
      - thu
      - fri
      - sat
  - condition: and
    conditions:
      - condition: state
        entity_id: switch.tidbyt_flights_switch
        state: "off"
action:
  - service: switch.turn_on
    data: {}
    target:
      entity_id: switch.tidbyt_flights_switch
mode: single
```

```
alias: Turn Tidbyt Flight Tracker off
description: ""
trigger:
  - platform: state
    entity_id:
      - binary_sensor.signify_netherlands_b_v_sml003_occupancy
    from: "on"
    to: "off"
    for:
      hours: 0
      minutes: 15
      seconds: 0
condition:
  - condition: and
    conditions:
      - condition: state
        entity_id: switch.tidbyt_flights_switch
        state: "on"
action:
  - service: switch.turn_off
    data: {}
    target:
      entity_id: switch.tidbyt_flights_switch
mode: single
```







