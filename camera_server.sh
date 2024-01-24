#!/bin/bash

##################################################################
# Check if the script is run with sudo or as a root user
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi



################################ installation ##################################

sudo su

# Update package list
apt-get update


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
echo "safetrax:$PASSWORD" | sudo chpasswd

# Add user to the sudo group
usermod -aG sudo safetrax

echo "User safetrax created with password $PASSWORD and sudo access."



####################################################### login as safetrax ########################################
su - safetrax



################################################### downloading compressed file #########################################

curl -OJL https://github.com/anupamjaiswalll/camera-server/raw/main/deployment.tgz

curl -OJL https://github.com/anupamjaiswalll/camera-server/raw/main/gpsvideogallery.tgz


mkdir /home/safetrax/Safetrax
tar -xvzf deployment.tgz
tar -xvzf gpsvideogallery.tgz

mv deployment/* /home/safetrax/Safetrax
chown -R safetrax. Safetrax

chown -R safetrax. gpsvideogallery/videos
mv gpsvideogallery /var/www/html

cd /home/safetrax/Safetrax
bash assign_permission


######################################## ip entries cameras.txt #######################

# Function to validate the IP address format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to take user input
get_camera_info() {
    read -p "Enter camera IP and cab number (e.g., 192.168.1.19,cab025): " input

    # Extracting IP and cab number using comma as delimiter
    IFS=',' read -ra parts <<< "$input"
    local ip=${parts[0]}
    local cab=${parts[1]}

    # Validating IP address
    if validate_ip "$ip"; then
        echo "$ip,$cab" >> cameras.txt
        echo "Camera information added to cameras.txt"
    fi
}

# Main script
while true; do
    get_camera_info

    read -p "Do you want to add another camera? (y/n): " answer
    if [[ $answer != "y" ]]; then
        break
    fi
done


########################################################## prepare cameras ####################################################
bash prepare_cameras

################################# front end ###########################################
cd /home/safetrax/Safetrax
ln -s /var/www/html/gpsvideogallery/videos videos


##################################### Adding cron jobs for safetrax user ###############################
(crontab -l ; echo "*/5 * * * * /home/safetrax/Safetrax/startup/cameraserver start") | crontab -
(crontab -l ; echo "* * * * * /home/safetrax/Safetrax/startup/camerastats start") | crontab -
(crontab -l ; echo "15 1 * * * /home/safetrax/Safetrax/remove_old_videos 1>>/home/safetrax/Safetrax/remove.log 2>&1") | crontab -
(crontab -l ; echo "*/30 * * * * /home/safetrax/Safetrax/offline_stats 1>>/home/safetrax/Safetrax/offline_stats.log 2>&1") | crontab -

############################################################### exit safetrax #########################
exit 


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
