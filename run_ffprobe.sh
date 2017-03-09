#!/bin/bash

outputDir="csv"

mkdir -p "$outputDir"

outputBitratesCsv="bitrates.csv"

echo "format,filename,bitrate,major_brand,minor_version,compatible_brands,encoder" > "${outputBitratesCsv}"

for f in videos/*.mp4; do
  echo "$f"

  fBasename="$(basename "${f}")"
  outputCsv="$outputDir"/"${fBasename%%.mp4}.csv"

  echo "frame,pts_time,size,type" > "${outputCsv}"
  ffprobe -loglevel error "${f}" -of csv\
  -select_streams v -show_frames -show_entries frame=pict_type,pkt_size,pkt_pts_time \
  >> "${outputCsv}"

  # format,output0-2pass-300K.mp4,307305,isom,512,isomiso2avc1mp41,Lavf57.56.101
  ffprobe -loglevel error "${f}" -of csv \
  -select_streams v -show_format -show_entries format=filename,bit_rate \
  >> "${outputBitratesCsv}"

done