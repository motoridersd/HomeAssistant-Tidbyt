"""
Applet: HA Now Playing
Summary: Now Playing for HA
Description: Now Playing for Home Assistant Media Players.
Author: Nick Penree
"""

load("render.star", "render")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("http.star", "http")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_IMAGE = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAMAAAAMs7fIAAAAGFBMVEVHcEz/////////////////////
//////8dS1W+AAAAB3RSTlMAAQMCBvYFRZBFoAAAAElJREFUGJWNj0sSwCAIQxNtm/vf2LGOQ0QXZgPz
+ASAS2kKKANEKYL0GRKIf8LI2PRsRAxSMK1ST80ENlVPXi97SjtxzWh/3akBR3MCH53fHWkAAAAASUVO
RK5CYII=
""")

def get_entity_status(ha_server, entity_id, token):
    if ha_server == None:
        fail("Home Assistant server not configured")

    if entity_id == None:
        fail("Entity ID not configured")

    if token == None:
        fail("Bearer token not configured")

    state_res = None
    cache_key = "%s.%s" % (ha_server, entity_id)
    cached_res = cache.get(cache_key)
    if cached_res != None:
        state_res = json.decode(cached_res)
    else:
        rep = http.get("%s/api/states/%s" % (ha_server, entity_id), headers = {
            "Authorization": "Bearer %s" % token
        })
        if rep.status_code != 200:
            print("HTTP request failed with status %d", rep.status_code)
            return None

        state_res = rep.json()
        cache.set(cache_key, rep.body(), ttl_seconds = 10)
    return state_res

def render_media_title(title, app_name):
    return render.Padding(
        pad = (2, 0, 0, 0),
        child = render.Marquee(
            width = 60,
            child = render.Padding(
                pad = (0, 2, 0, 0),
                child = render.Text(
                    content = title,
                    color = get_title_color(app_name)
                ),
            ),
        ),
    )

def render_detail_text(name, color = "#ffffff", font = "tb-8"):
    return render.Marquee(
        width = 41,
        child = render.Text(
            content = name.upper() if name != None else "",
            color = color,
            font = font
        ),
    )

def skip_execution():
    print("skip_execution")
    return []

def get_title_color(app_name):
    color = "#009cc4"
    color = "#e74e5a" if (app_name == "Music" or app_name == "TVMusic") else color
    color = "#fc7e0f" if app_name == "Overcast" else color
    color = "#1db954" if app_name == "Spotify" else color
    color = "#f00000" if app_name == "YouTube" else color
    color = "#e50914" if app_name == "Netflix" else color
    color = "#e5a00d" if app_name == "Plex" else color
    color = "#b535f6" if app_name == "HBO" else color
    color = "#bf94ff" if (app_name == "Twitch" or app_name == "Podcasts") else color
    color = "#5ea8b8" if app_name == "Movies" else color
    return color

def get_app_name(app_name, app_id, friendly_name):
    out_name = app_name
    if out_name == None:
        if app_id != None:
            out_name = app_id.split(".")[-1]
            out_name = "Apple TV" if out_name == "TVWatchList" else out_name
            out_name = "Movies" if out_name == "TVMovies" else out_name
            out_name = "Prime Video" if out_name == "AIVApp" else out_name
            out_name = "Spectrum TV" if app_id == "com.timewarnercable.simulcast" else out_name
            out_name = "Plex" if app_id == "com.plexapp.plex" else out_name
            out_name = "YouTube" if app_id == "com.google.ios.youtube" else out_name
            out_name = "HBO" if app_id == "com.hbo.hbonow" else out_name
        else:
            out_name = friendly_name
    return out_name

def main(config):
    ha_server = config.get("homeassistant_server")
    entity_id = config.get("entity_id")
    token = config.get("auth")
    entity_status = get_entity_status(ha_server, entity_id, token)
    # print(entity_status)
    if entity_status == None:
        return skip_execution()

    status = entity_status["state"]
    attributes = entity_status["attributes"] if "attributes" in entity_status else dict()

    # print("entity_id: %s" % entity_id)
    # print("status: %s" % status)

    if status != "playing":
        return skip_execution()

    media_title = attributes["media_title"] if "media_title" in attributes else None
    media_image = None

    if "entity_picture" in attributes:
        media_image = cache.get(attributes["entity_picture"])
    else:
        media_image = DEFAULT_IMAGE

    if media_image == None:
        res = http.get("%s%s" % (ha_server, attributes["entity_picture"]))
        if res.status_code != 200:
            fail("HTTP request failed with status %d" % res.status_code)
        media_image = res.body()
        cache.set(attributes["entity_picture"], media_image, ttl_seconds=600)

    media_content_type = attributes["media_content_type"] if "media_content_type" in attributes else None
    media_artist = attributes["media_artist"] if "media_artist" in attributes else None
    media_album_name = attributes["media_album_name"]  if "media_album_name" in attributes else ''
    app_name = attributes["app_name"] if "app_name" in attributes else None
    app_id = attributes["app_id"] if "app_id" in attributes else None
    friendly_name = attributes["friendly_name"] if "friendly_name" in attributes else ''
    app_name = get_app_name(app_name, app_id, friendly_name) if app_name == None else app_name
    has_title = not (media_title == None or len(media_title) == 0)
    has_album = not (media_album_name == None or len(media_album_name) == 0)
    media_artist = friendly_name if media_artist == None else media_artist
    media_title = app_name if not has_title else media_title

    if not has_album:
        if app_id == "com.apple.TVAirPlay":
            media_album_name = "AirPlay"
        else:
            media_album_name = app_name

    # print("media_content_type: %s" % media_content_type)
    # print("media_title: %s" % media_title)
    # print("media_artist: %s" % media_artist)
    # print("media_album_name: %s" % media_album_name)
    # print("app_id: %s" % app_id)
    # print("app_name: %s" % app_name)

    line2 = media_album_name if app_name == media_title else media_album_name
    line1 = media_artist if line2 != media_artist else ""

    if media_content_type == "video" or app_name == "Overcast" or app_name == "Podcasts":
        line1 = line2
        line2 = media_artist

    if line2 == friendly_name:
        line2 = "→ %s" % line2
    media_info = [
        render_detail_text(line1),
        render_detail_text(line2, color = "#cccccc"),
    ]

    return render.Root(
        child = render.Column(
            children = [
                render_media_title(media_title.upper(), app_name),
                render.Padding(
                    pad = (2, 2, 0, 0),
                    child = render.Row(
                        children = [
                            render.Image(src = media_image, height = 17, width = 17),
                            render.Padding(
                                pad = (2, 0, 0, 0),
                                child = render.Column(children = media_info)
                            )
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "homeassistant_server",
                name = "Home Assistant Server",
                desc = "URL of Home Assistant server",
                icon = "server"
            ),
            schema.Text(
                id = "entity_id",
                name = "Entity ID",
                icon = "play",
                desc = "Entity ID of the media player entity in Home Assistant",
            ),
            schema.Text(
                id = "auth",
                name = "Bearer Token",
                icon = "key",
                desc = "Long-lived access token for Home Assistant",
            ),
        ],
    )
