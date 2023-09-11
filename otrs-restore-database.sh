#!/bin/bash

# # otrs-restore-database.sh Description
# This script facilitates the restoration of a database backup.
# 1. **Identify Containers**: It first identifies the service and backups containers by name, finding the appropriate container IDs.
# 2. **List Backups**: Displays all available database backups located at the specified backup path.
# 3. **Select Backup**: Prompts the user to copy and paste the desired backup name from the list to restore the database.
# 4. **Stop Service**: Temporarily stops the service to ensure data consistency during restoration.
# 5. **Restore Database**: Executes a sequence of commands to drop the current database, create a new one, and restore it from the selected compressed backup file.
# 6. **Start Service**: Restarts the service after the restoration is completed.
# To make the `otrs-restore-database.shh` script executable, run the following command:
# `chmod +x otrs-restore-database.sh`
# Usage of this script ensures a controlled and guided process to restore the database from an existing backup.

OTRS_CONTAINER=$(docker ps -aqf "name=otrs-otrs")
OTRS_BACKUPS_CONTAINER=$(docker ps -aqf "name=otrs-backups")
OTRS_DB_NAME="otrsdb"
OTRS_DB_USER=$(docker exec $OTRS_BACKUPS_CONTAINER printenv OTRS_DB_USER)
MARIADB_PASSWORD=$(docker exec $OTRS_BACKUPS_CONTAINER printenv OTRS_DB_PASSWORD)
BACKUP_PATH="/srv/otrs-mariadb/backups/"

echo "--> All available database backups:"

for entry in $(docker container exec "$OTRS_BACKUPS_CONTAINER" sh -c "ls $BACKUP_PATH")
do
  echo "$entry"
done

echo "--> Copy and paste the backup name from the list above to restore database and press [ENTER]"
echo "--> Example: otrs-mariadb-backup-YYYY-MM-DD_hh-mm.gz"
echo -n "--> "

read SELECTED_DATABASE_BACKUP

echo "--> $SELECTED_DATABASE_BACKUP was selected"

echo "--> Stopping service..."
docker stop "$OTRS_CONTAINER"

echo "--> Restoring database..."
docker exec "$OTRS_BACKUPS_CONTAINER" sh -c "mysql -h mariadb -u $OTRS_DB_USER --password=$MARIADB_PASSWORD -e 'DROP DATABASE $OTRS_DB_NAME; CREATE DATABASE $OTRS_DB_NAME;' \
&& gunzip -c ${BACKUP_PATH}${SELECTED_DATABASE_BACKUP} | mysql -h mariadb -u $OTRS_DB_USER --password=$MARIADB_PASSWORD $OTRS_DB_NAME"
echo "--> Database recovery completed..."

echo "--> Starting service..."
docker start "$OTRS_CONTAINER"
