#!/bin/bash
##################################################################
# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

# Check if a password argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <password>"
    exit 1
fi

# Set the provided password
PASSWORD="$1"



################################ installation ##################################


# Update package list
sudo apt-get update


# Add repository
sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu focal main universe"

# Update package list
sudo apt update

# Install the necessary library
sudo apt-get install -y libonig5

# Install Apache2
sudo apt-get install -y apache2

# Install PHP 7.2 and required extensions
sudo apt-get install -y php7.2 libapache2-mod-php7.2 php7.2-gd php7.2-mbstring php7.2-sqlite3 curl

# Install SQLite3
sudo apt-get install -y sqlite3

# Additional steps for configuring PHP (if needed)
# For example, to install PHP on Ubuntu based on the provided link:
 sudo apt-get install -y php7.2

# Restart Apache to apply changes
sudo systemctl restart apache2


update-rc.d apache2 enable



############################################ user creation ################

PASSWORD="mtap@123"

# Create user
sudo useradd -m -s /bin/bash safetrax

# Set password for the user
echo "safetrax:$PASSWORD" | sudo chpasswd

# Add user to the sudo group
sudo usermod -aG sudo safetrax

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
    else
        echo "Invalid IP address format. Please try again."
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



