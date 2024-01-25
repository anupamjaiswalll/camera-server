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


######################################### remove startup script from bash ########################################
sed -i '/\/home\/safetrax\/setup_safetrax.sh/d' /home/safetrax/.bashrc


############################################################### exit safetrax #########################
exit 
