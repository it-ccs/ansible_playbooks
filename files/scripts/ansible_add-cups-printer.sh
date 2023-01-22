#!/bin/sh

printerName="$1"
printerUri="$2"
printerDriver="$3"

## append trailing / if there is non
printerUri=`echo "$printerUri" | sed -r 's/([^\/])$/\1\//'`

if [ -n "`lpstat -v | grep \"$printerName\"`" ]; then
  currentUri=`lpstat -v | awk "\\$3==\\"$printerName:\\" {print \\$4}"`
  if [ -z "`echo "$currentUri" | grep "$printerUri"`" ]; then
    ## printer URI didn't match, so change it
    lpadmin -p "$printerName" -v "$printerUri" || exit $?
    ## make sure printer is shared
    lpadmin -p "$printerName" -o printer-is-shared=true || exit $?
    echo "Updated printer URI to '$printerUri' from '$currentUri'."
    exit
  else
    ## make sure printer sharing is enabled
    lpadmin -p "$printerName" -o printer-is-shared=true
    echo "Printer already exists (ensured sharing is enabled).";
    exit
  fi
fi

lpadmin -p "$printerName" -o printer-is-shared=true -v "$printerUri" -m "$printerDriver" && echo "Added printer '$printerName'" || exit $?