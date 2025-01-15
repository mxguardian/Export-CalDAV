#!/usr/bin/env bash
#
# Discover CalDAV calendar URLs from a SabreDAV server.
# Requires curl and xpath.

# --- Environment variables ---
CALDAV_SERVER=${CALDAV_SERVER:-"https://webmail.mxguardian.net"}

export_calendar () {
  local CALDAV_USERNAME=$1
  local CALDAV_PASSWORD=$2

  CALENDAR_RESPONSE=$(curl -s -X PROPFIND \
    -u "$CALDAV_USERNAME:$CALDAV_PASSWORD" \
    -H "Depth: 1" \
    -H "Content-Type: application/xml; charset=utf-8" \
    --data '<?xml version="1.0" encoding="UTF-8"?>
  <d:propfind xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
    <d:prop>
      <d:displayname/>
      <d:resourcetype/>
      <cal:supported-calendar-component-set/>
    </d:prop>
  </d:propfind>' \
    "$CALDAV_SERVER/dav.php/calendars/")

  # Find each <d:response> that includes <cal:calendar/> in its resourcetype
  # and print out the <d:href> for that block.
  CALENDAR_URL=$(echo "$CALENDAR_RESPONSE" | xpath -q -e '//d:response[d:propstat/d:prop/d:resourcetype/cal:calendar]/d:href/text()')

  curl -u "$CALDAV_USERNAME:$CALDAV_PASSWORD" "https://webmail.mxguardian.net$CALENDAR_URL?export"
}

export_calendar $1 $2
