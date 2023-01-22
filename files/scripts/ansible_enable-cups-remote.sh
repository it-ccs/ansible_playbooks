#!/bin/sh

if [ -z "$(cupsctl | grep "_remote_any=1")" ]; then
  cupsctl --remote-any || exit $?
  echo "Remote printing changed to enabled."
else
  echo "Remote printing already enabled."
fi