#!/usr/bin/env bash

DATETAG=$(date +"%Y%m%d%H%M%S")

if [[ -z "$2" ]]; then
    echo "usage: $(basename $0) SRCDIR DSTDIR"
    exit 1
fi

SRCDIR="$1"
DSTDIR="$2"
PWFILE="/tmp/.password"

if [[ ! -f $PWFILE ]]; then
    echo "ERROR: missing passwordfile '$PWFILE'."
    exit 2
fi

find "$SRCDIR" -type f ! -path "*/@eaDir/*" ! -name .picasa.ini ! -path "*/.comments/*" | while read; do

  SRC="$REPLY"
  DST="$DSTDIR"

  DIRNAME="$(dirname "$SRC")"
  FILENAME="$(basename "$SRC")"
  OUTFILE="$DST/$DIRNAME/$FILENAME.aes256"
  OUTSUM="$SRCDIR/filelist.sha1sum"

  if [[ ! -f "$OUTSUM" ]]; then
    echo "\
# This file created by $(basename $0). A tool to backup files as encrypted.
# This file contains the sha1sum of archived files before encryption 
# so that you can know if original and backup version differs. " > "$OUTSUM"
fi

  if [[ -f "$OUTFILE" ]] && [[ -f "$OUTSUM" ]]; then
    echo -n "$SRC: Destination file present. Checking sha1sum: "
    SHA1TMP="$(mktemp)"
    grep "$SRC" "$OUTSUM" > $SHA1TMP
    sha1sum  --status -c "$SHA1TMP" 
    RC="$?"
    if [[ $RC -eq 0 ]]; then
        echo "OK."
        continue
    fi
    echo "NOT MATCHING."
    #rm $SHA1TMP
  fi
  
  if [[ -f "$SRC" ]]; then
    echo "$SRC -> $OUTFILE"
    mkdir -p "$DST/$DIRNAME"
    /usr/bin/openssl enc -aes256 -salt -pass file:$PWFILE -in "$SRC" -out "$OUTFILE"
    sha1sum "$SRC" >> "$OUTSUM"
  fi

done
\rm /tmp/.password
