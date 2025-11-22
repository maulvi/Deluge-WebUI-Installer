# Deluge WebUI Installer script
# UNMAINTAINED!!!

# BETTER INSTALL DELUGED DIRECTLY FROM YOUR DISTRIBUTION AND ENABLE DELUGED SERVICE VIA SYSTEMD

For Debian 7/8 and Ubuntu 12/14/16 Based environment

-tested with 18 but daemon service won't start

This script install the latest version available
```
sudo bash -c "$(wget --no-check-certificate -qO - https://raw.githubusercontent.com/maulvi/Deluge-WebUI-Installer/master/deluge_webui.sh)"
```
```
the default password is: deluge
```
ThinClient/Daemon Configuration Deluge - Daemon/ThinClient Settings

This is one of the neatest features about Deluge, you can use a local GUI client instead of the WebUI to  download torrents remotely onto your VPS.  There are two ways to go about this, one way is to use a VPN or SSH tunnel to connect to your VPS and then connect to the Deluge daemon locally.  

The easier method is to check Allow Remote Connections as shown above. Now you’ll need to install Deluge on your PC.  
Once installed, 
go to Edit >>  Preferences >> Interface  –  You need to uncheck Classic Mode Enable.
Deluge will restart after you have applied this change. Now you need to add an authenticated user, you’ll do this by going to your Deluge user’s home directory.  
If the user you created was deluge-torrent, it would be: cd /home/deluge-torrent/ Add your new user to the auth file like so:

```
echo "username:strongpassword:10" >> ./.config/deluge/auth

## Restart Deluge ##
/etc/init.d/deluge-daemon restart
```
Now go back to your desktop Deluge and setup the connection to your server, Deluge - Desktop Connection Manager

If you’ve done everything correctly, you should see a green dot next to your hostname and you’ll be able to hit Connect.




source: [sonicboxes](https://sonicboxes.com)
