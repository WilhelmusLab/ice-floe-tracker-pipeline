#!/usr/bin/env python3.11
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests",
#   "numpy",
#   "skyfield"
# ]
# ///

# Code developed by Simon Hatcher (2022)
# Adapted for use in a Cylc pipeline for IceFloeTracker by Timothy Divoll (2023)

# ACTION REQUIRED FROM YOU:
# 1. Update the following parameters in the `flow.cylc` file:

# startdate = YYYY-MM-DD
# enddate = YYYY-MM-DD
#
# centroid-x = DD.DDDD
# centoid-y = DD.DDDD

# Centroid is the approximate point in the middle of your bounding box area of interest
# Your www.space-track.org credentials (https://www.space-track.org/auth/createAccount for free account) need to be set as environment variables in .bash_profile or .zshrc or add to ENV VARS in Windows
# NOTE: PASSWORD FIELD IS NOT SECURE. DO NOT USE USER/PASSWORD DIRECTLY IN CONFIG FILES.

# 2. A stable internet connection is also required.

# Package imports.
import functools
import itertools
import pprint
from typing import Literal
import requests
import json
import datetime
from skyfield.api import wgs84, load, EarthSatellite
import numpy as np
import csv
import math
import argparse
import logging

_logger = logging.getLogger(__name__)

# URLs for space track login.
uriBase = "https://www.space-track.org"
requestLogin = "/ajaxauth/login"


def get_passtimes(start_date, end_date, csvoutpath, lat, lon, SPACEUSER, SPACEPSWD, satellite: Literal["aqua", "terra"]):
    siteCred = {"identity": SPACEUSER, "password": SPACEPSWD}
    print(f"Outpath {csvoutpath}")
    print(f"Timeframe starts on {start_date}, and ends on {end_date}")
    print(f"Coordinates (x, y): ({lat}, {lon})")

    data = get_Data(siteCred, start_date, end_date, satellite)
    _logger.debug(f"{data=}")
    
    # Load in orbital mechanics tool timescale.
    ts = load.timescale()

    # Specify area of interest.
    aoi = wgs84.latlon(lat, lon)


    # Define 2D array of values to be added to results CSV.
    rows = []

    # Loop through each day until the end date of interest is reached.
    for today in itertools.takewhile(lambda d: d <= end_date, date_generator(start_date)):
        # Get UTC time values of the start of today and the start of tomorrow.
        # Passes between these times are considered.
        t0 = to_utc(today)
        t1 = to_utc(today + datetime.timedelta(days=1))
        _logger.debug(f"{t0=}, {t1=}")

        min_diff_index, _ = getclosestepoch(t0, data)
        tleline1, tleline2 = get_tli_lines(data[min_diff_index])
        results = EarthSatellite(tleline1, tleline2, satellite.upper(), ts)

        closest = getclosest(results, aoi, t0, t1, satellite=satellite)

        # Add closest passes of the day to array of passes.
        rows.append([closest])

    csvwrite(rows, csvoutpath)


# Define date range
def date_generator(start: datetime.datetime, step: datetime.timedelta = datetime.timedelta(days=1)):
    d = start
    while True:
        yield d
        d += step


# Write CSV of all pass information.
def csvwrite(rows, outpath):
    
    with open(outpath, "w", newline="") as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerows(rows)


# Returns the date after a given date.
def getNextDay(date):
    month = int(date[0])
    year = int(date[2])
    day = int(date[1])
    monthDays = daysInMonth(month, year)

    nextmonth = month
    nextday = day
    nextyear = year

    if day == monthDays:
        nextday = 1
        nextmonth += 1
    else:
        nextday += 1
    if month == 12 and day == 31:
        nextyear += 1
        nextmonth = 1

    nextyearstr = str(nextyear)

    if nextday < 10:
        nextdaystr = "0" + str(nextday)
    else:
        nextdaystr = str(nextday)
    if nextmonth < 10:
        nextmonthstr = "0" + str(nextmonth)
    else:
        nextmonthstr = str(nextmonth)

    return [nextmonthstr, nextdaystr, nextyearstr]


# Returns the number of days in a certain month.
def daysInMonth(month, year):
    if month in {1, 3, 5, 7, 8, 10, 12}:
        return 31
    if month == 2:
        if year % 4 == 0:
            return 29
        return 28
    return 30


def get_epochs(dataset):
    return [timestamp_to_utc(item["EPOCH"]) for item in dataset]


def getclosestepoch(t0, dataset):
    epochs = get_epochs(dataset)
    _logger.debug(f"{dataset=}, {epochs=}")

    # sequentially compute the absolute difference between the epoch and t0
    # keeping track of the index and value of the minimum difference
    min_diff = float("inf")
    min_diff_index = 0
    for i, epoch in enumerate(epochs):
        diff = abs(t0 - epoch)
        _logger.debug(f"{i=}, {epoch=}, {diff=}, {min_diff=}")
        if diff < min_diff:
            min_diff = diff
            min_diff_index = i

    return min_diff_index, epochs[min_diff_index]


def get_tli_lines(tle):
    line1, line2 = tle["TLE_LINE1"], tle["TLE_LINE2"]
    return line1, line2


def timestamp_to_utc(timestamp):
    ts = load.timescale()
    # Split the timestamp into date and time components
    date_part, time_part = timestamp.split("T")

    # Split the date part into year, month, and day
    year, month, day = map(int, date_part.split("-"))

    # Split the time part into hour, minute, and second
    hour, minute, second = map(float, time_part.split(":"))

    # Pass the parsed components to ts.utc
    return ts.utc(year, month, day, hour, minute, second)


def to_utc(t):
    ts = load.timescale()
    return ts.utc(t)


def get_Data(credentials: dict, start_date, end_date, satellite: Literal["aqua", "terra"]):
    # URLs for space track login.
    uriBase = "https://www.space-track.org"
    requestLogin = "/ajaxauth/login"

    # Get TLEs from space track.
    with requests.Session() as session:
        # Log in with username and password.
        resp = session.post(uriBase + requestLogin, data=credentials)
        if resp.status_code != 200:
            _logger.debug(resp)
            message = "POST fail on login. Your username/password may be incorrect. {0}".format(resp)
            raise IOError(message)

        cat_id_mapping = {
            "aqua": "27424",
            "terra": "25994"
            }
        cat_id = cat_id_mapping[satellite]

        # Retrieve Aqua TLEs from space track.
        url = f"https://www.space-track.org/basicspacedata/query/class/gp_history/NORAD_CAT_ID/{cat_id}/orderby/TLE_LINE1%20ASC/EPOCH/{start_date}--{end_date}/format/json"
        _logger.debug(f"{url=}")
        resp = session.get(url)
        if resp.status_code != 200:
            _logger.debug(resp)
            message = "GET fail on request. {0}.format(resp)"
            raise IOError(message)

        # Turn JSON into Python dict.
        data = json.loads(resp.text)

        _logger.debug("\n"+pprint.pformat(data))

        # No more requests.
        session.close()
    return data


def process_passes(satellite, events, times, aoi):
    passes = []
    pass_dict = {}

    for i, (event, ti) in enumerate(zip(events, times)):
        geocentric = satellite.at(ti)
        difference = satellite - aoi
        topocentric = difference.at(ti)

        if event == 0:  # Rise
            _logger.debug(f"Rise: {ti=}")
            pass_dict = {}
            riselat, riselon = wgs84.latlon_of(geocentric)
            pass_dict["rise_lat"] = riselat.degrees
            pass_dict["rise_lon"] = riselon.degrees

        elif event == 1:  # Overpass
            _logger.debug(f"Overpass: {ti=}")
            _logger.debug(f"ti type: {type(ti)}")
            alt, az, distance = topocentric.altaz()
            pass_dict["distance"] = distance.km
            pass_dict["time"] = ti.utc_iso()
            overlat, overlon = wgs84.latlon_of(geocentric)
            pass_dict["over_lat"] = overlat.degrees
            pass_dict["over_lon"] = overlon.degrees

            # Handle edge case for first overpass without prior rise
            if i == 0:
                pass_dict["rise_lat"] = float("nan")
                pass_dict["rise_lon"] = float("nan")
            # Handle edge case for last overpass without subsequent set
            if i == len(events) - 1:
                pass_dict["set_lat"] = float("nan")
                pass_dict["set_lon"] = float("nan")
                passes.append(pass_dict)

        else:  # Set
            _logger.debug(f"Set: {ti=}")
            setlat, setlon = wgs84.latlon_of(geocentric)
            pass_dict["set_lat"] = setlat.degrees
            pass_dict["set_lon"] = setlon.degrees
            passes.append(pass_dict)

    return passes

def find_closest_pass(passes, ascending=True):
    least_distance = math.inf
    closest_time = ""

    for pass_dict in passes:
        if not np.isnan(pass_dict["rise_lat"]):
            is_ascending = (
                (pass_dict["rise_lat"] < pass_dict["over_lat"])
                if ascending
                else (pass_dict["rise_lat"] > pass_dict["over_lat"])
            )
            if is_ascending and pass_dict["distance"] < least_distance:
                least_distance = pass_dict["distance"]
                closest_time = pass_dict["time"]
        else:
            is_ascending = (
                (pass_dict["set_lat"] > pass_dict["over_lat"])
                if ascending
                else (pass_dict["set_lat"] < pass_dict["over_lat"])
            )
            if is_ascending and pass_dict["distance"] < least_distance:
                least_distance = pass_dict["distance"]
                closest_time = pass_dict["time"]

    return closest_time

def getclosest(data, aoi, t0, t1, satellite: Literal["aqua", "terra"], altitude_degrees=30):

    data_t, data_events = data.find_events(
        aoi, t0, t1, altitude_degrees=altitude_degrees
    )
    _logger.debug(f"data_t: {[t for t in data_t]}")
    _logger.debug(f"{data_events=}")
    
    passes = process_passes(data, data_events, data_t, aoi)
    _logger.debug(f"{passes=}")

    closest = find_closest_pass(passes, ascending={"aqua": True, "terra": False}[satellite])
    _logger.debug(f"{closest=}")

    return closest


def main():
    logging.basicConfig(level=logging.DEBUG)

    parser = argparse.ArgumentParser(
        description="Aqua and Terra Satellite Overpass time tool"
    )
    parser.add_argument(
        "--SPACEUSER",
        "-u",
        type=str,
        help="space-track.org username",
    )
    parser.add_argument(
        "--SPACEPSWD",
        "-p",
        type=str,
        help="space-track.org password",
    )
    parser.add_argument(
        "--startdate",
        type=datetime.date.fromisoformat,
        dest="start_date",
        help="Start date in format YYYY-MM-DD",
    )
    parser.add_argument(
        "--enddate",
        type=datetime.date.fromisoformat,
        dest="end_date",
        help="End date in format YYYY-MM-DD",
    )
    parser.add_argument(
        "--centroid-lat",
        "--lat",
        metavar="lat",
        dest="lat",
        type=float,
        help="latitude of bounding box centroid",
    )
    parser.add_argument(
        "--centroid-lon",
        "--lon",
        metavar="lon",
        dest="lon",
        type=float,
        help="longitude of bounding box centroid",
    )
    parser.add_argument(
        "--csvoutpath",
        type=str,
        help="Path to output CSV file",
    )
    parser.add_argument(
        "--satellite",
        choices=["aqua", "terra"],
        type=str,
        help="Which satellite to get data for",
    )

    args = parser.parse_args()

    get_passtimes(**vars(args))


if __name__ == "__main__":
    main()
