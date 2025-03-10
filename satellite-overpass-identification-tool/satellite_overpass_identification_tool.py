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
import requests
import json
import datetime
from skyfield.api import wgs84, load, EarthSatellite
import numpy as np
import csv
import math
import argparse
import pathlib

# URLs for space track login.
uriBase = "https://www.space-track.org"
requestLogin = "/ajaxauth/login"


# Define error.
class MyError(Exception):
    def __init___(self, args):
        Exception.__init__(
            self, "my exception was raised with arguments {0}".format(args)
        )
        self.args = args


def _parsedate(date):
    return datetime.datetime.strptime(date, "%Y-%m-%d").strftime("%m-%d-%Y").split("-")


def get_passtimes(start_date, end_date, csvoutpath, lat, lon, SPACEUSER, SPACEPSWD):
    siteCred = {"identity": SPACEUSER, "password": SPACEPSWD}
    print(f"Outpath {csvoutpath}")
    print(f"Timeframe starts on {start_date}, and ends on {end_date}")
    print(f"Coordinates (x, y): ({lat}, {lon})")

    end_date = getNextDay(end_date)

    aquaData, terraData = get_Data(siteCred, start_date, end_date)

    # Load in orbital mechanics tool timescale.
    ts = load.timescale()

    # Specify area of interest.
    aoi = wgs84.latlon(lat, lon)

    # Define today and tomorrow.
    today = start_date
    tomorrow = getNextDay(start_date)

    # Define 2D array of values to be added to results CSV.
    rows = []

    # Loop through each day until the end date of interest is reached.
    while not np.array_equiv(today, end_date):
        # Get UTC time values of the start of today and the start of tomorrow.
        # Passes between these times are considered.
        t0 = to_utc(today)
        t1 = to_utc(tomorrow)

        min_diff_index, closest_aqua_epoch_to_t0 = getclosestepoch(t0, aquaData)
        aqua_tleline1, aqua_tleline2 = get_tli_lines(aquaData[min_diff_index])
        aqua = EarthSatellite(aqua_tleline1, aqua_tleline2, "AQUA", ts)

        min_diff_index, closest_terra_epoch_to_t0 = getclosestepoch(t0, terraData)
        terra_tleline1, terra_tleline2 = get_tli_lines(terraData[min_diff_index])
        terra = EarthSatellite(terra_tleline1, terra_tleline2, "TERRA", ts)

        aqua_closest, terra_closest = getclosest(aqua, terra, aoi, t0, t1)

        # Add closest passes of the day to array of passes.
        rows.append(["-".join(today), aqua_closest, terra_closest])

        today = getNextDay(today)
        tomorrow = getNextDay(today)

    fields_, rows_ = convert_fields_mdy_folded_to_iso8601_unfolded(rows)
    csvwrite(start_date, end_date, lat, lon, rows_, csvoutpath, fields=fields_)

def convert_fields_mdy_folded_to_iso8601_unfolded(rows):
    """Convert a row from [MM-DD-YYYY, UTC time (aqua), UTC time (terra)] to [YYYY-MM-DD, Satellite, ISO8601 datetime] format.
    
    Examples:
        >>> convert_fields_mdy_folded_to_iso8601_unfolded([("03-31-2013", "11:50:20", "14:45:05"),])
        ... # doctest: +NORMALIZE_WHITESPACE
        (['date', 'satellite', 'overpass time'],
         [['2013-03-31', 'aqua',  '2013-03-31T11:50:20Z'], 
          ['2013-03-31', 'terra', '2013-03-31T14:45:05Z']])

        >>> convert_fields_mdy_folded_to_iso8601_unfolded([("12-01-2609", "23:59:01", "00:00:00"),])
        ... # doctest: +NORMALIZE_WHITESPACE
        (['date', 'satellite', 'overpass time'],
         [['2609-12-01', 'aqua',  '2609-12-01T23:59:01Z'], 
          ['2609-12-01', 'terra', '2609-12-01T00:00:00Z']])

        
        >>> convert_fields_mdy_folded_to_iso8601_unfolded([
        ...     ("03-31-2013", "11:50:20", "14:45:05"),
        ...     ("04-01-2013", "11:52:20", "14:43:05"),
        ... ])
        ... # doctest: +NORMALIZE_WHITESPACE
        (['date', 'satellite', 'overpass time'],
         [['2013-03-31', 'aqua',  '2013-03-31T11:50:20Z'], 
          ['2013-03-31', 'terra', '2013-03-31T14:45:05Z'], 
          ['2013-04-01', 'aqua',  '2013-04-01T11:52:20Z'], 
          ['2013-04-01', 'terra', '2013-04-01T14:43:05Z']])
        

    """
    new_fields = ["date", "satellite", "overpass time"]
    new_rows = []
    for row in rows:
        date_mm_dd_yyyy, aqua_time, terra_time = row
        m, d, y = map(int, date_mm_dd_yyyy.split("-"))
        date_yyyy_mm_dd = datetime.date(y, m, d)
        
        new_rows.append([f"{date_yyyy_mm_dd}", "aqua", f"{date_yyyy_mm_dd}T{aqua_time}Z"])
        new_rows.append([f"{date_yyyy_mm_dd}", "terra", f"{date_yyyy_mm_dd}T{terra_time}Z"])
    
    return new_fields, new_rows


# Write CSV of all pass information.
def csvwrite(startdate, enddate, lat, lon, rows, outpath, fields=["Date", "Aqua pass time", "Terra pass time"]):
    
    outpath_ = pathlib.Path(outpath)
    
    if outpath_.is_dir():
        csv_name = f"passtimes_lat{lat}_lon{lon}_{''.join(startdate)}_{''.join(enddate)}.csv"
        filename = outpath_ / pathlib.Path(csv_name)
    elif outpath_.suffix == ".csv":
        filename = outpath_
    else:
        msg = "Output path neither a directory nor a .csv file: %s" % outpath
        raise IOError(msg)

    with open(filename, "w", newline="") as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(fields)
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

    # sequentially compute the absolute difference between the epoch and t0
    # keeping track of the index and value of the minimum difference
    min_diff = float("inf")
    min_diff_index = 0
    for i, epoch in enumerate(epochs):
        diff = abs(t0 - epoch)
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
    return ts.utc(int(t[2]), int(t[0]), int(t[1]))


def get_Data(credentials: dict, start_date, end_date):
    # URLs for space track login.
    uriBase = "https://www.space-track.org"
    requestLogin = "/ajaxauth/login"

    # Get TLEs from space track.
    with requests.Session() as session:
        # Log in with username and password.
        resp = session.post(uriBase + requestLogin, data=credentials)
        if resp.status_code != 200:
            raise MyError(
                resp, "POST fail on login. Your username/password may be incorrect."
            )

        # Retrieve Aqua TLEs from space track.
        resp = session.get(
            f"https://www.space-track.org/basicspacedata/query/class/gp_history/NORAD_CAT_ID/27424/orderby/TLE_LINE1%20ASC/EPOCH/{start_date[2]}-{start_date[0]}-{start_date[1]}--{end_date[2]}-{end_date[0]}-{end_date[1]}/format/json"
        )
        if resp.status_code != 200:
            print(resp)
            raise MyError(resp, "GET fail on request")

        # Turn JSON into Python dict.
        aquaData = json.loads(resp.text)

        # Retrieve Terra TLEs from space track.
        resp = session.get(
            f"https://www.space-track.org/basicspacedata/query/class/gp_history/NORAD_CAT_ID/25994/orderby/TLE_LINE1%20ASC/EPOCH/{start_date[2]}-{start_date[0]}-{start_date[1]}--{end_date[2]}-{end_date[0]}-{end_date[1]}/format/json"
        )
        if resp.status_code != 200:
            print(resp)
            raise MyError(resp, "GET fail on request")

        # Turn JSON into Python dict.
        terraData = json.loads(resp.text)

        # No more requests.
        session.close()
    return aquaData, terraData


def getclosest(aqua, terra, aoi, t0, t1, altitude_degrees=30):
    def process_passes(satellite, events, times):
        passes = []
        pass_dict = {}

        for i, (event, ti) in enumerate(zip(events, times)):
            geocentric = satellite.at(ti)
            difference = satellite - aoi
            topocentric = difference.at(ti)

            if event == 0:  # Rise
                pass_dict = {}
                riselat, riselon = wgs84.latlon_of(geocentric)
                pass_dict["rise_lat"] = riselat.degrees
                pass_dict["rise_lon"] = riselon.degrees

            elif event == 1:  # Overpass
                alt, az, distance = topocentric.altaz()
                pass_dict["distance"] = distance.km
                pass_dict["time"] = ti.utc_strftime("%Y %b %d %H:%M:%S")
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

        return closest_time.split(" ")[3] if closest_time else ""

    aqua_t, aqua_events = aqua.find_events(
        aoi, t0, t1, altitude_degrees=altitude_degrees
    )
    terra_t, terra_events = terra.find_events(
        aoi, t0, t1, altitude_degrees=altitude_degrees
    )

    aqua_passes = process_passes(aqua, aqua_events, aqua_t)
    terra_passes = process_passes(terra, terra_events, terra_t)

    aqua_closest, terra_closest = [
        find_closest_pass(passes, ascending=ascending)
        for passes, ascending in zip([aqua_passes, terra_passes], [True, False])
    ]

    return aqua_closest, terra_closest


def main():
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
        type=_parsedate,
        dest="start_date",
        help="Start date in format YYYY-MM-DD",
    )
    parser.add_argument(
        "--enddate",
        type=_parsedate,
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
        help="Path to output CSV file, or a directory, where the output should be written",
    )

    args = parser.parse_args()

    get_passtimes(**vars(args))


if __name__ == "__main__":
    main()
