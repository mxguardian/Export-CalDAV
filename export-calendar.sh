#!/usr/bin/env bash
# Copyright (C) 2025 MXGuardian LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# --- Environment variables ---
CALDAV_SERVER=${CALDAV_SERVER:-"https://webmail.mxguardian.net"}

export_calendar () {
  local CALDAV_USERNAME=$1
  local CALDAV_PASSWORD=$2

  # Attempt to find a calendar by sending a PROPFIND request to the server.
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
  # and get the <d:href> for that block. Return the first one found.
  CALENDAR_URL=$(echo "$CALENDAR_RESPONSE" | xpath -q -e '(//d:response[d:propstat/d:prop/d:resourcetype/cal:calendar]/d:href/text())[1]')

  if [ -z "$CALENDAR_URL" ]; then
    # No calendars found. Possibly an authentication error.
    # Print the response for debugging.
    echo $CALENDAR_RESPONSE
    exit 1
  fi

  curl -u "$CALDAV_USERNAME:$CALDAV_PASSWORD" "$CALDAV_SERVER$CALENDAR_URL?export"
}

export_calendar $1 $2
