# cl-audio-file-splitter
### _Wojciech S. Gac <wojciech.s.gac@gmail.com>_

A tiny Common Lisp utility for splitting audio files based on temporal
description

## Usage

This utility grew out of my personal need for splitting larger audio
files into smaller parts (such as music albums into individual
songs). The program expects the user to provide a track length
specification, based on which it is able to calculate offsets for
particular tracks.

The entry point is the function `split-single-file-into-parts`. It
takes the following arguments:

- `file` - path to the input audio file
- `spec` - track specification in the format `'(("<track_1_name>"
  . "<track_1_duration_hh:mm:ss>") ...)`
- `output-directory` - directory in which to store output files
- `prepend-track-to-files` - (*optional*) prepend 0-padded track
  numbers to individual file names

At this point there is one parameter controlling the details of the
recoding process:

- `*id3-backend*` - specifiec which ID3 utility to use to adjust ID3
  tags on output files (allowed values: `:id3ed`, `:mp3info`)

## License

GPLv3

## TODO
  * Add provisions for building a standalone executable with CLI options
  * Check out native FFMPEG encoding to avoid calling out to shell
  * Ditto for ID3 tags
  * Consider additional recoding options (such as format or bitrate change)
