#!/bin/sh
set -e

cp -r /app/output/* /export/

exec /bin/bcsh
