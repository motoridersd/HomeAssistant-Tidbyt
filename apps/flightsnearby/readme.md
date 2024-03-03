# Flights Nearby using Home Assistant and the FlightRadar24 Integration

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/ebe45d5d-7d0d-4974-b46a-772dcaaa796a)

This app requires a functioning Home Assistant instance with the FlightRadar24 Integration configured and running. This app can be run locally on a server/container with pixlet, or it will require your Home Assistant to be reachable from the internet.

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/beae69ce-cebf-414a-985a-83eabf37b29f)

The information can be hardcoded if running locally.

This app will pull tail logos from Airhex using the three letter ICAO code. The filtering of what aircraft to display is done in Home Assistant through the FlightRadar24 integration. The direction of the tail logo can be changed by the user

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/5e502229-1701-466f-a03f-ceecb78afb21)

# Configuring the Home Assistant FlightRadar24 integration

It is available on HACS, follow instructions here: https://github.com/AlexandrErohin/home-assistant-flightradar24

The integration asks for a radius in meters, coordinates, a scan interval in seconds, and an altitude range (minimum and maximum). Multiple entities can be added so one can track as many areas as desired and display the flight info from multiple areas by creating multiple copies of the flightsnearby app.

When running locally, I have a script running on an LXC container where pixlet resides that will run the applet with pixlet every time the flight entity changes. This can be run on a timed loop. When there are no flights detected, Home Assistant removes the app.
