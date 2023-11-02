#!/usr/bin/env bash
set -euo pipefail

PROGRAM_NAME="$(basename "${0}")"

BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"
TAB="$(printf "\t")"

PROJ_WGS84='+proj=longlat +datum=WGS84 +no_defs'
PROJ_EPSG3413='+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'

GDAL_SRS='+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs'
GDAL_WMS_TEMPLATE='<GDAL_WMS>
    <Service name="TMS">
        <ServerUrl>https://gibs.earthdata.nasa.gov/wmts/epsg3413/best/%%LAYER%%/default/%%DATE%%/250m/${z}/${y}/${x}.%%EXT%%</ServerUrl>
    </Service>
    <DataWindow>
        <UpperLeftX>-4194304</UpperLeftX>
        <UpperLeftY>4194304</UpperLeftY>
        <LowerRightX>4194304</LowerRightX>
        <LowerRightY>-4194304</LowerRightY>
        <TileLevel>5</TileLevel>
        <TileCountX>2</TileCountX>
        <TileCountY>2</TileCountY>
        <YOrigin>top</YOrigin>
    </DataWindow>
    <Projection>EPSG:3413</Projection>
    <BlockSizeX>512</BlockSizeX>
    <BlockSizeY>512</BlockSizeY>
    <BandsCount>3</BandsCount>
</GDAL_WMS>'

warn() {
  >&2 echo "$@"
}

die() {
  local message="$1"
  local status="${2:-1}"

  warn "${message}"
  exit "${status}"
}

usage() {
  cat <<EOF
${PROGRAM_NAME}: Ice Floe Tracker data fetch utility

${BOLD}USAGE${NORMAL}
  $ ./${PROGRAM_NAME} [OPTIONS]

${BOLD}OPTIONS${NORMAL}
  -b${TAB}${TAB}bounding box of interest in form "x1@y1@x2@y2"
  ${TAB}${TAB}Note: for wgs84 input: x, y = lat, lon
  ${TAB}${TAB}      for epsg3413 input: x, y = easting, northing
  -c${TAB}${TAB}coordinate reference system: epsg3413, wgs84 (default: "wgs84")
  -e${TAB}${TAB}end date in YYY-MM-DD format
  -h${TAB}${TAB}print this help message
  -o${TAB}${TAB}output directory (default: ".")
  -s${TAB}${TAB}start date in YYYY-MM-DD format

${BOLD}EXAMPLES${NORMAL}
  Download data from 2022-05-01 through today using lat/lon
    $ ./${PROGRAM_NAME} -o data -s 2022-05-01 -b "81@-22@79@-12"
EOF
}

convert_to_epsg3413() {
  local input="${1}"
  echo "${input}" | cs2cs ${PROJ_WGS84} +to ${PROJ_EPSG3413} -r | awk '{ print $1 " " $2 }'
}

get_topleft() {
  local bounding_box="${1}"
  local x="$(echo ${bounding_box} | cut -d@ -f1 )"
  local y="$(echo ${bounding_box} | cut -d@ -f2 )"

  echo "${x} ${y}"
}

get_bottomright() {
  local bounding_box="${1}"
  local x="$(echo ${bounding_box} | cut -d@ -f3 )"
  local y="$(echo ${bounding_box} | cut -d@ -f4 )"

  echo "${x} ${y}"
}

sort_xy() {
  local x1="${1}"
  local y1="${2}"
  local x2="${3}"
  local y2="${4}"

  xmin="$(python3 -c "print(min(${x1}, ${x2}))")"
  xmax="$(python3 -c "print(max(${x1}, ${x2}))")"

  ymin="$(python3 -c "print(min(${y1}, ${y2}))")"
  ymax="$(python3 -c "print(max(${y1}, ${y2}))")"

  echo "${xmin} ${ymin} ${xmax} ${ymax}"
}

add_day() {
  local date="${1}"
  local macos='false'

  if [ "$(uname -s)" = 'Darwin' ]; then
    macos='true'
  fi

  if [ "${macos}" = 'true' ] && [ -z "${CYLC_VERSION+x}" ]; then
    date -j -v +1d -f "%Y-%m-%d" "${date}" +%Y-%m-%d
  else
    date -d "${date} 1 days" +%Y-%m-%d
  fi
}

download_landmask() {
  local bounding_box="${1}"
  local date="${2}"
  local output="${3}"
  local xml
  local layer='OSM_Land_Mask'
  local ext='png'

  xml="$(echo "${GDAL_WMS_TEMPLATE}" | sed -e "s/%%LAYER%%/${layer}/" -e "s/%%EXT%%/${ext}/" -e "s/%%DATE%%/${date}/" )" 

  echo 'downloading landmask'
  gdalwarp -overwrite -t_srs "${GDAL_SRS}" -te ${bounding_box} "${xml}" "${output}/landmask.tiff" &> /dev/null
}

download_truecolor() {
  local bounding_box="${1}"
  local date="${2}"
  local enddate="${3}"
  local output="${4}"
  local layer filename xml
  local ext="jpeg"


  echo "downloading true color images"
  while [ "${date}" != "${enddate}" ]; do
    for sat in Aqua Terra; do
      layer="MODIS_${sat}_CorrectedReflectance_TrueColor"
      filename="$(echo "${date}" | sed -e 's/-//g').$(echo "${sat}" | tr '[:upper:]' '[:lower:]').truecolor.250m.tiff"
      xml="$(echo "${GDAL_WMS_TEMPLATE}" | sed -e "s/%%LAYER%%/${layer}/" -e "s/%%EXT%%/${ext}/" -e "s/%%DATE%%/${date}/" )" 

      gdalwarp -overwrite -t_srs "${GDAL_SRS}" -te ${bounding_box} "${xml}" "${output}/${filename}" &> /dev/null
    done

    date="$(add_day "${date}")"
    printf '.'
  done

  printf '\n'
}

download_reflectance() {
  local bounding_box="${1}"
  local date="${2}"
  local enddate="${3}"
  local output="${4}"

  local layer filename xml
  local ext="jpeg"


  echo "downloading reflectance color images"
  while [ "${date}" != "${enddate}" ]; do
    
    for sat in Aqua Terra; do
      layer="MODIS_${sat}_CorrectedReflectance_Bands721"
      filename="$(echo "${date}" | sed -e 's/-//g').$(echo "${sat}" | tr '[:upper:]' '[:lower:]').reflectance.250m.tiff"

      xml="$(echo "${GDAL_WMS_TEMPLATE}" | sed -e "s/%%LAYER%%/${layer}/" -e "s/%%EXT%%/${ext}/" -e "s/%%DATE%%/${date}/" )" 
      gdalwarp -overwrite -t_srs "${GDAL_SRS}" -te ${bounding_box} "${xml}" "${output}/${filename}" &> /dev/null
    done

    date="$(add_day "${date}")"
    printf '.'
  done

  printf '\n'
}

main() {
  local crs='wgs84'
  local startdate="$(date "+%Y-%m-%d")"
  local enddate="$(date "+%Y-%m-%d")"
  local output='.'
  local raw_bounding_box=''

  local opt
  while getopts ":b:c:e:ho:s:" opt; do
    case $opt in
      b)
        raw_bounding_box="${OPTARG}"
        ;;
      c)
        crs="${OPTARG}"
        ;;
      e)
        enddate="${OPTARG}"
        ;;
      h)
        usage; exit
        ;;
      o)
        output="${OPTARG}"
        ;;
      s)
        startdate="${OPTARG}"
        ;;
      :)
        die "option expected for \"-${OPTARG}\""
        ;;
      ?)
        die "invalid option: \"${OPTARG}\""
        ;;
    esac
  done

  if [ "${crs}" != "wgs84" ] && [ "${crs}" != "epsg3413" ]; then
    die "unknown coordinate reference system: \"${crs}\""
  fi

  if [ "x${raw_bounding_box}" = 'x' ]; then
    die "undefined bounding box"
  fi

  # split raw bounding box into top left and bottom right sets
  local topleft="$(get_topleft "${raw_bounding_box}")"
  local bottomright="$(get_bottomright "${raw_bounding_box}")"
  local x1 y1 x2 y2

  # convert lat/lon to polar stereographic
  if [ "${crs}" == "wgs84" ]; then
    topleft="$(convert_to_epsg3413 "${topleft}")"
    bottomright="$(convert_to_epsg3413 "${bottomright}")"
  fi

  # assign x and y from top left and bottom right coordinate sets
  x1="$(echo "${topleft}" | awk '{ print $1 }')"
  y1="$(echo "${topleft}" | awk '{ print $2 }')"
  x2="$(echo "${bottomright}" | awk '{ print $1 }')"
  y2="$(echo "${bottomright}" | awk '{ print $2 }')"

  local bounding_box
  
  bounding_box="$(sort_xy $x1 $y1 $x2 $y2)"

  # make standard output dirs
  mkdir -p "${output}"
  mkdir -p "${output}/reflectance"
  mkdir -p "${output}/truecolor"

  # download the images
  download_landmask "${bounding_box}" "${startdate}" "${output}"
  download_truecolor "${bounding_box}" "${startdate}" "${enddate}" "${output}/truecolor"
  download_reflectance "${bounding_box}" "${startdate}" "${enddate}" "${output}/reflectance"
}

main "$@"
