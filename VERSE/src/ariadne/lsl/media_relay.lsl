// media_relay.lsl - Ariadne Media Relay Object for OpenSimulator
//
// Displays media (images, videos, web pages) on parcel media.
// Listens on channel -63342 (gMediaCh) for media URLs from the controller.
//
// Supported media types:
//   - Images (JPG, PNG, GIF, BMP, TGA)
//   - Videos (MP4, WebM, OGG)
//   - Web pages (HTML)
//   - Maps (Google Maps, SL Maps)
//
// Usage:
//   1. Rez a prim in the region
//   2. Add this script to the prim
//   3. Ensure the prim is owned by the parcel owner
//   4. The controller.lsl will send media URLs on channel -63342

integer gMediaCh = -63342;

// Media type constants
string MEDIA_TYPE_IMAGE = "image/jpeg";
string MEDIA_TYPE_HTML = "text/html";
string MEDIA_TYPE_VIDEO = "video/mp4";
string MEDIA_TYPE_PNG = "image/png";

setParcelMedia(string url)
{
    // Determine media type from URL extension
    string mediaType = MEDIA_TYPE_HTML;

    string lowerUrl = llToLower(url);

    if (llSubStringIndex(lowerUrl, ".jpg") != -1 || 
        llSubStringIndex(lowerUrl, ".jpeg") != -1)
    {
        mediaType = MEDIA_TYPE_IMAGE;
    }
    else if (llSubStringIndex(lowerUrl, ".png") != -1)
    {
        mediaType = MEDIA_TYPE_PNG;
    }
    else if (llSubStringIndex(lowerUrl, ".mp4") != -1)
    {
        mediaType = MEDIA_TYPE_VIDEO;
    }
    else if (llSubStringIndex(lowerUrl, ".webm") != -1)
    {
        mediaType = "video/webm";
    }
    else if (llSubStringIndex(lowerUrl, ".ogv") != -1 || 
             llSubStringIndex(lowerUrl, ".ogg") != -1)
    {
        mediaType = "video/ogg";
    }
    else if (llSubStringIndex(lowerUrl, ".gif") != -1)
    {
        mediaType = "image/gif";
    }
    else if (llSubStringIndex(lowerUrl, ".bmp") != -1)
    {
        mediaType = "image/bmp";
    }
    else if (llSubStringIndex(lowerUrl, ".html") != -1 || 
             llSubStringIndex(lowerUrl, ".htm") != -1 ||
             llSubStringIndex(lowerUrl, "http") != -1)
    {
        mediaType = MEDIA_TYPE_HTML;
    }

    // Set parcel media
    llParcelMediaCommandList([
        PARCEL_MEDIA_COMMAND_URL, url,
        PARCEL_MEDIA_COMMAND_TYPE, mediaType,
        PARCEL_MEDIA_COMMAND_SIZE, <512.0, 512.0, 0.0>,
        PARCEL_MEDIA_COMMAND_DESC, "Ariadne Media"
    ]);

    // Also set the media texture on the prim face
    llSetTexture(TEXTURE_MEDIA, ALL_SIDES);

    llOwnerSay("Media set: " + url + " (type: " + mediaType + ")");
}

// Clear media display
clearParcelMedia()
{
    llParcelMediaCommandList([
        PARCEL_MEDIA_COMMAND_URL, "",
        PARCEL_MEDIA_COMMAND_DESC, ""
    ]);
    llSetTexture(TEXTURE_BLANK, ALL_SIDES);
    llOwnerSay("Media cleared");
}

default
{
    state_entry()
    {
        llListen(gMediaCh, "", NULL_KEY, "");
        llSetText("Ariadne Media Relay", <1,1,1>, 1.0);
        llOwnerSay("Media Relay ready on channel " + (string)gMediaCh);
    }

    listen(integer channel, string name, key id, string msg)
    {
        if (channel == gMediaCh)
        {
            setParcelMedia(msg);
        }
    }

    touch_start(integer total_number)
    {
        llSay(0, "Ariadne Media Relay listening on channel " + (string)gMediaCh);
    }
}
