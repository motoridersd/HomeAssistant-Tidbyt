## Home Assistant Now Playing

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/ebb3e5ce-b20a-4c2c-8ba5-f4ea19769c31)

Using the applet built by drudge: [ha_now_playing](https://github.com/drudge/smart-matrix-server/tree/main/applets/ha_now_playing)

The applet pulls information from Home Assistant and requires the info below:

    Home Assistant Server URL (the full http address of your local HA address)
    Entity ID (the media player you want to use)
    Token (a long lived token to allow using the Home Assistant API)

The code includes logic to display all kinds of info. I currently use it with a Sonos speaker and it pulls the information, including the album art. When I use the line in of the Play:5, it will show Line In.
