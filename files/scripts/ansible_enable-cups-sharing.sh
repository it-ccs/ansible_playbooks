#!/bin/sh

if [ -z "$(cupsctl | grep "_share_printers=1")" ]; then
  cupsctl --share-printers || exit $?
  echo "Sharing changed to enabled."
else
  echo "Sharing already enabled."
fi