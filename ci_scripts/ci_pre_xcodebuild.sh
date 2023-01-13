#!/bin/sh

cd ../IceCubesApp/
plutil -replace OPENAI_SECRET -string $OPENAI_SECRET Secret.plist
plutil -p Secret.plist
exit 0
