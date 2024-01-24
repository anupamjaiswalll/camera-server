#!/bin/bash

##################################################################
# Check if the script is run with sudo or as a root user
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi



################################ installation ##################################
# Update package list
apt-get update

apt-get install -y software-properties-common

# Add repository
add-apt-repository "deb http://archive.ubuntu.com/ubuntu focal main universe"
add-apt-repository ppa:ondrej/php

# Update package list
apt update

# Install the necessary library
apt-get install -y libonig5

# Install Apache2
apt-get install -y apache2

# Install PHP 7.2 and required extensions
apt-get install -y php7.2 libapache2-mod-php7.2 php7.2-gd php7.2-mbstring php7.2-sqlite3 curl

# Install SQLite3
apt-get install -y sqlite3

# Additional steps for configuring PHP (if needed)
# For example, to install PHP on Ubuntu based on the provided link:
apt-get install -y php7.2

# Restart Apache to apply changes
systemctl restart apache2


update-rc.d apache2 enable



############################################ user creation ################

PASSWORD="mtap@123"

# Create user
useradd -m -s /bin/bash safetrax

# Set password for the user
echo "safetrax:$PASSWORD" | chpasswd

# Add user to the sudo group
usermod -aG sudo safetrax

echo "User safetrax created with password $PASSWORD and sudo access."



curl -OJL https://github.com/anupamjaiswalll/camera-server/raw/main/setup_safetrax.sh
chmod 777 setup_safetrax.sh
mv setup_safetrax.sh /home/safetrax/

###To run this script automatically after logging in, you can add it to the .bashrc file for the safetrax user:
echo "/path/to/setup_safetrax.sh" >> /home/safetrax/.bashrc

####################################################### login as safetrax ########################################
su - safetrax





######################################## now you are sudo user #############################

######################################## cron job for root user #######################
(crontab -l ; echo "* * * * * cp /home/safetrax/Safetrax/db/camera.db /var/www/html/gpsvideogallery/db/camera.db") | crontab -
(crontab -l ; echo "* * * * * cp /home/safetrax/Safetrax/db/camera_videos.db /var/www/html/gpsvideogallery/db/camera_videos.db") | crontab -


############################## editing apache file ##################################
# Configuration to add
CONFIGURATION="
DocumentRoot /var/www/html/gpsvideogallery
<Directory /var/www/html/gpsvideogallery>
    Options Indexes FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
    DirectoryIndex index.php
</Directory>
"

# Add configuration to the 000-default.conf file
echo "$CONFIGURATION" | sudo tee -a /etc/apache2/sites-enabled/000-default.conf > /dev/null



###################################### add log rotate #################################
mv safetrax /etc/logrotate.d/


####################################### Restart apache #############################
service apache2 restart


####################################### to remove unnecessary files
./finish
