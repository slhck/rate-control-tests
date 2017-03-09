#!/bin/bash

commonInputOpts="-y -loglevel error"
commonOpts="-an -t 30"
outputDir="videos"

mkdir -p "$outputDir"

devNull="/dev/null"

for inputVideo in TearsOfSteel.avi BigBuckBunny.avi; do

  # used 10 for TearsOfSteel, actually
  for inputOffset in 0 120 240; do

    inputVideoBasename="$(basename "${inputVideo}")"
    outputPrefix="${inputVideoBasename%%.avi}${inputOffset}"

    # Bitrate-based
    for bitrate in 750 1500 3000 7500; do

      # ABR
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -b:v "${bitrate}K" $commonOpts "$outputDir"/"${outputPrefix}"-abr-"${bitrate}K".mp4

      # 2-pass VBR
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -pass 1 -passlogfile "${outputPrefix}" -b:v "${bitrate}K" $commonOpts -f mp4 "${devNull}"
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -pass 2 -passlogfile "${outputPrefix}" -b:v "${bitrate}K" $commonOpts "$outputDir"/"${outputPrefix}"-2pass-"${bitrate}K".mp4

      # ABR-VBV
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -b:v "${bitrate}K" -maxrate "${bitrate}K" -bufsize "$(($bitrate*2))K" $commonOpts "$outputDir"/"${outputPrefix}"-abrVbv-"${bitrate}K".mp4

      # 2-pass VBR-VBV
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -pass 1 -passlogfile "${outputPrefix}" -b:v "${bitrate}K" -maxrate "${bitrate}K" -bufsize "$(($bitrate*2))K" $commonOpts -f mp4 "${devNull}"
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -pass 2 -passlogfile "${outputPrefix}" -b:v "${bitrate}K" -maxrate "${bitrate}K" -bufsize "$(($bitrate*2))K" $commonOpts "$outputDir"/"${outputPrefix}"-2passVbv-"${bitrate}K".mp4

    done

    # CRF
    for crf in 17 23 29 35; do

      # CQP
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -qp "$crf" $commonOpts "$outputDir"/"${outputPrefix}"-qp-"$crf".mp4

      # CRF
      ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -crf "$crf" $commonOpts "$outputDir"/"${outputPrefix}"-crf-"$crf".mp4
    done

    for bitrate in 750 1500 3000 7500; do
      for crf in 17 23 29 35; do
        # CRF + VBV
        ffmpeg $commonInputOpts -ss "${inputOffset}" -i "${inputVideo}" -crf "$crf" -b:v "${bitrate}K" -maxrate "${bitrate}K" -bufsize "$(($bitrate*2))K" $commonOpts "$outputDir"/"${outputPrefix}"-crfVbv-"$crf"_"${bitrate}K".mp4
      done
    done

  done

done