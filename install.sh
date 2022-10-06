#!/bin/sh

# Slowcord installer
# First time I write in bash so it can be catastrophic.
# Color variables just to make it look good lol
# Hope it helps someone.

# Reset
e='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BPurple='\033[1;35m'      # Purple
BYellow='\033[1;33m'      # Yellow

# A necessary dependency 

echo "$Yellow[*]$e Initializing."
sudo apt-get install whiptail -y


# Ask if the user already has Slowcord or not
if (whiptail --title "Welcome to Slowcord Installer" --yes-button "Download" --no-button "I already have Slowcord"  --yesno "Before starting the installation, do you want to download Slowcord (git clone) or you are already in a directory with the project?" 10 110) then
    echo "$Yellow[*]$e Downloading Slowcord."
    git clone https://github.com/MaddyUnderStars/fosscord-server.git
    cd fosscord-server/
else
    echo "[*] The user already has Slowcord."
    clear
fi


# Text taken directly from README.md to make some things clear

if (whiptail --title "Slowcord Install Script" --msgbox "Slowcord is vastly different than standard Fosscord, with many new features, bug fixes and improvements.\n\n Keep in mind : \n\n   • You will not receive support. I am a university student, who works on this in my free time because it's fun. What is not fun is helping people with the same 5 problems. \n\n • Slowcord is configured in a very specific way. There exists parts of the codebase which assume things about your system's configuration which may not be documented here. You will need to edit things here to get them to work. \n\n • There is no voice/video server, and no admin dashboard yet. There do not exist on any Fosscord instance." 22 75 && 
whiptail --title "Slowcord Install Script" --msgbox "Before starting, this script assumes that : \n\n • You're using Ubuntu or any Debian based distros. \n\n • You've got a domain name, and you are NOT using ngrok, cloudflare tunnels, hamachi. \n\n • With said domain name, you've got DNS records pointing it to your server. \n\n By clicking on the OK button the installation script will start." 16 95) then
    echo "[*] Start of the installation procedure"
fi

# Check if node is installed

# A bit useless when I think about it but what an idea also to install slowcord without node uh

if which node > /dev/null
    then
        echo "\n${BGreen}[*]${e} Node is installed, skipping."
    else
       echo "${RED}[*] Node missing, installing ${ENDCOLOR}"

       # Using NVM script to install node latest
       if (whiptail --title "Node js Install" --yesno "It seems that node is not present on this machine, install node automatically ? (latest version)." 8 80) then
       curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
       export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


        echo "==> Installed node version manager (NVM)."

        nvm install node

        echo "==> Installed NodeJS."

        nvm alias default

        echo "==> The latest version of NodeJS is now used."

        nvm use default


       else echo "[*] Please install node before continuing. $?." && exit

fi fi

# Update System

echo "\n[1] ${BGreen} Updating ${e}System"
sudo apt-get -y update > /dev/null 2>&1

# Upgrade System
echo "[2] ${BGreen} Upgrading ${e}System"
sudo apt-get -y upgrade > /dev/null 2>&1

# Install Packages
echo "[3] ${BGreen} Installing ${e}Package\n"

sudo apt install build-essential > /dev/null 2>&1
echo '✓ build-essential'

sudo apt-get install build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev > /dev/null 2>&1
echo '✓ deps for canvas npm package'

echo "[4] ${BGreen}Installing ${e} NPM dependency\n"
npm i

echo "[5] ${BGreen}Building ${e} Slowcord\n"

npm run build

# pretty self explanatory

echo "[6] ${BGreen}Installing ${e}Nginx \n"
sudo apt install nginx certbot python3-certbot-nginx


# -------------------- NGINX ---------------

echo "[7] ${BGreen}Installing ${e}Nginx server block \n"

DOMAIN=$(whiptail --inputbox --nocancel "What is your domaine name ?" 10 100 3>&1 1>&2 2>&3)
whiptail --title "SSL Setup" --msgbox "The installer will now install SSL certificates. \nIf you have installation problems, first remove what is in sites-enabled and sites-availables before restarting the script \nOtherwise install the certificates yourself." 12 60


CONFIG="fosscord"

# This is the same file present in src-slowcord/nginx/fosscord but changing all references to slowcord by DOMAIN
# Here we replace all the 'DOMAIN' values with the one entered at the nginx step

sudo wget https://gist.githubusercontent.com/haydaralqassam/a487202f534b4d63c7e9150826a865f8/raw/ac42090bf31dd018064c21a6bfd4578dcf7de5f8/fosscord -P /etc/nginx/sites-available/ -q --show-progress  
# Replace 'DOMAIN' with the actual $DOMAIN
sudo sed -i "s/DOMAIN/$DOMAIN/" /etc/nginx/sites-available/$CONFIG
sudo ln -s /etc/nginx/sites-available/$CONFIG /etc/nginx/sites-enabled

sudo nginx -t
# Finally restart nginx
sudo systemctl restart nginx

# Certbot
sudo certbot --nginx --domains $DOMAIN

echo "\n${BGreen}[*] ${e} Look like SSL is installed ?"
echo "\n${BGreen}[*] ${e} If there is an error, delete everything in sites-availables and sites-sites-enabled and run the script again. \n Maybe there is already a fosscord file present."


# -------------------- DATABASE --------------------

CHOICE=$(whiptail --separate-output --radiolist --nocancel --title "Select your Database Type" "Choose options" 10 45 5 \
  "mariadb" "MySQL compatible" ON \
  "postgresql" "PostgreSQL Database" OFF \
  "sqlite" "DO NOT USE(Broken)" OFF 3>&1 1>&2 2>&3)

if [ -z "$CHOICE" ]; then
  # Shouldn't be displayed since --nocancel is specified
  echo "Easter egg :blush:"
else
  echo "[*] Selected $CHOICE database"
fi

# Just for fun
# I'm bored

bad="sqlite"

# For some reason bash only want variable
d="mariadb"
f="postgresql"

if [ $CHOICE = $bad ]
        then

        echo "[8] ${BGreen}Selected ${e}Sqlite \n"

                echo "$BRed[*]$e Hm, shouldn't use sqlite since it's ${Red} broken$e, good luck fixing it"
                echo "[*] If you want to switch to an MariaDB/PostgreSQL database simply copy this .env with these "

                echo "[*] Configuring .env file"

                # Just a simple configuration file without the database link, because the user takes sqlite
                # PORT=3001 and PRODUCTION=true

                sudo wget https://gist.githubusercontent.com/haydaralqassam/61f0b9c15c791a1cdf91b1119d4018e5/raw/c7cbbbe1a206dd7e21ba0d1f9cfe84350f7ab546/.env -P $PWD/ -q --show-progress

                echo "[*] Installing Sqlite driver."

                npm install sqlite --save
        else

        echo "[8] ${BGreen}Configuring ${e}your .env file \n"
        
                echo "You're good using $CHOICE"

                USERNAME=$(whiptail --inputbox --nocancel --title "Database Username" "Please enter your database username" 10 100 3>&1 1>&2 2>&3)
                PASSWORD=$(whiptail --passwordbox --nocancel --title "Database password" "Please enter your database password" 10 100 3>&1 1>&2 2>&3)
                IP=$(whiptail --inputbox --nocancel --title "Database IP" "Please enter the DB's IP (putting 'localhost' somehow broke sometimes, put DB IP/domain name )" 10 100 3>&1 1>&2 2>&3)
                PORT=$(whiptail --inputbox --nocancel --title "Database port" "Please enter the database port, Default : 3306/MariaDB 5432/PostgreSQL" 10 100 3>&1 1>&2 2>&3)
                NAME=$(whiptail --inputbox --nocancel --title "Database name" "Please enter the database name" 10 100 3>&1 1>&2 2>&3)

        sudo echo -e "DATABASE=$CHOICE://$USERNAME:$PASSWORD@$IP:$PORT/$NAME\nPORT=3001\nTHREADS=1\nPRODUCTION=true" | tee .env

fi
        # Now Install Drivers
        
    if [ $CHOICE = $d ]
    
                then

                if ! which mariadb > /dev/null
                    then

                        clear

                        if (whiptail --title "Database" --yes-button "Install now" --no-button "I don't care"  --yesno "It seems that $CHOICE is not installed on your machine.\n\nYou want the installer to do it for you?.  " 15 110) 
                            
                            then

                                # Installing MariaDB
                                sudo apt install mariadb-server -y

                                # Imagine having no password
                                sudo mysql_secure_installation

                                # MariaDB
                                sudo systemctl start mariadb && sudo systemctl status mariadb

                                DOMAIN=$(whiptail --msgbox --nocancel --fb "Your Mariadb database is ready for use." 10 100 3>&1 1>&2 2>&3)
                            
                            else

                                echo "$Yellow[*]$e Sight, skipping $CHOICE database install."
                        fi
                fi

                npm install mysql --save
                clear
                else

                npm install $CHOICE --save
                clear
        fi

    if [ $CHOICE = $f ]

                then

                if ! which psql > /dev/null

                    then

                        clear
                        
                        if (whiptail --title "Database" --yes-button "Install now" --no-button "I don't care"  --yesno "It seems that $CHOICE is not installed on your machine.\n\nYou want the installer to do it for you?.  " 15 110)

                            then

                            # Install some required package
                            echo "$Yellow[*]$e Downloading Keyring(s)."
                            curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg

                            echo "$Yellow[*]$e Adding PostegreSQL repos."
                            echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql.list
                   
                            echo "\n[*] ${BGreen} Updating ${e}System"
                            sudo apt-get -y update > /dev/null 2>&1

                            echo "[*] ${BGreen} Upgrading ${e}System"
                            sudo apt-get -y upgrade > /dev/null 2>&1

                            # Installing postegresql
                            sudo apt install postgresql -y

                            sudo systemctl status postgresql
                        
                            DOMAIN=$(whiptail --msgbox --nocancel --fb "Your PostgreSQL database is ready for use." 10 100 3>&1 1>&2 2>&3)

                            else

                            echo "$Yellow[*]$e Sight, skipping $CHOICE database install."
                        fi

                    fi
                    clear

                    sudo systemctl status postgresql

                    echo "\n\n$BGreen[*]$e Installed PosgreSQL"
                fi

echo "\n[10] ${BGreen}Cleaning ${e}up \n"

# Since the login server is broken on slowcord-refractor the script directly deletes the loginRedirect to avoid being stucked
# Unless someone finds out that you have to run slowcord-refractor but with the login server of slowcord lol

sudo rm -r $PWD/assets/preload-plugins/loginRedirect.js

if (whiptail --title "Finished Installation" --yes-button "Run Slowcord Now" --no-button "Later"  --yesno "You have just installed Slowcord and configured, keep in mind that you will not have support for it. \n\nYou can choose at the bottom to run it right away or not.
Once installed go to your database in the table named config and modify the configuration of your instance as you wish. \n\nSome scripts that can be useful are present in the README of Slowcord's github.  " 15 110) then
    npm run start
else
    cd fosscord-server/
    echo "$BRed[*]$e Leaving Installer. You can start Slowcord using ${Green}npm run start $e\n "
    echo "$BGreen Goodbye!"
fi
