#!/bin/sh

# Define paths and credentials
FOLDER_PATH="/var/www/html"
BACKUP_PATH="/mnt/disks/bkp/wordpress"

echo "####################################"
echo "###### BACKUP WORDPRESS SITES ######"
echo "####################################"

cd $FOLDER_PATH
# Create a backup of each folder and database
for folder in "$FOLDER_PATH"/*; do
    if [ -d "$folder" ]; then
        folder_name=$(basename "$folder")
        echo "\n- Backing up $folder_name... "
        BACKUP_FILENAME="$BACKUP_PATH/${folder_name}_$(date +%Y-%m-%d).tar.gz"
        if [ -f $BACKUP_FILENAME ]; then
            echo "-- backup $BACKUP_FILENAME already exists"
        else
            tar -czf $BACKUP_FILENAME -C "$folder" .
            echo "-- $folder_name compressed"
        fi

        if [ -f "$folder_name/wp-config.php" ]; then

            echo "-- $folder_name is a wordpress"
            # Backup MySQL database
            MYSQL_USER=$( sed -n "s/.*DB_USER',\s*'\(.*\)'.*/\1/p" $folder_name/wp-config.php )
            MYSQL_PASS=$( sed -n "s/.*DB_PASSWORD',\s*'\(.*\)'.*/\1/p" $folder_name/wp-config.php )
            MYSQL_HOST=$( sed -n "s/.*DB_HOST',\s*'\(.*\)'.*/\1/p" $folder_name/wp-config.php )
            MYSQL_DB=$( sed -n "s/.*DB_NAME',\s*'\(.*\)'.*/\1/p" $folder_name/wp-config.php )

            echo "-- dumping database $MYSQL_DB"
            BACKUP_DB_FILENAME="$BACKUP_PATH/${folder_name}_db_$(date +%Y-%m-%d).gz"
            if [ -f $BACKUP_DB_FILENAME ]; then
                echo "-- database backup already exists"
            else
                mysqldump -u $MYSQL_USER -p$MYSQL_PASS -h $MYSQL_HOST --databases $MYSQL_DB --single-transaction | gzip -c > $BACKUP_DB_FILENAME
                echo "-- database $MYSQL_DB compressed\n"
            fi
        fi
    fi
done

# Delete backups older than 7 days
echo "\n- Cleaning up older backups... "
find "$BACKUP_PATH" -type f -name '*.gz' -mtime +7 -exec rm {} +
