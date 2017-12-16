#!/bin/bash


#                                                 
#              .                               .  
#              |     o                         |  
# .--. .-.  .-.| .-. ..--. ____ .,-.  .-.  .-. |  
# |  |(   )(   |(.-' |`--.      |   )(   )(   )|  
# '  `-`-'  `-'`-`--'|`--'      |`-'  `-'  `-' `- 
#                    ;          |                 
#                 `-'           '                
#                                                 

# the version we're looking for
readonly UBUNTU_MANDATORY="Ubuntu 16.04"
readonly MONEROD_MANDATORY="v0.11.1.0"
readonly NODE_MANDATORY="v6.9.2"
readonly NPM_MANDATORY="v0.11.1.0"

clear

printf "\n"
printf  "#=---------------------------------------------------------------=#\n"
printf  "#--------------- nodejs-pool install: requirements --------------=#\n" 
printf  "#=---------------------------------------------------------------=#\n\n"
printf "This version of nodejs-pool has several requirements:\n"
printf "  1.  That you are doing a green-field install.\n"
printf "  2.  The Linux distribution installed is $UBUNTU_MANDATORY.  We'll confirm that later if you're unsure. \n"
printf "  3.  Your CPU has full support for AES-NI extensions.  We'll confirm this too.\n"
printf "  4.  That you are not running as the "root" user, but can sudo without a password.  \n"
printf "  5.  A minimun of 60G of fast disk space and you'll be happy with the extra space. \n"
printf "\n"; printf "\n"

printf "Do you want to continue?  (Y/n):\n"
read CONT
if [ $CONT == "n" ] || [ $CONT == 'N' ]; then
  printf "\n"
  printf "Good choice, best if you do not install unless you meet the above requirements.\n"
  printf "But, I know you don't give up that easy, so you'll be back.\n"
  printf "\n"; printf "\n"
  exit 99
fi

printf "\n"
printf  "#=---------------------------------------------------------------=#\n"
printf  "#--------------- nodejs-pool install: packages ------------------=#\n" 
printf  "#=---------------------------------------------------------------=#\n\n"
printf "This version of nodejs-pool will install the following:\n"
printf "  1.  The latest updates and upgrades to all packages.\n"
printf "  2.  Current version of MySQl in the $UBUNTU_MANDATORY repositories.\n";
printf "  3.  Plus the essential build environment.\n"
printf "  4.  Many packages; git, python-virtualenv, curl ntp, libboost-all, libevent, libminiupnpc, and more\n"
printf "  5.  Will change the timezone to Etc/UTC. \n"
printf "  6.  Build and install Monerod $MONEROD_MANDATORY, Monero wallet-cli and wallet-rpc.  \n"
printf "  7.  Build and install Node 6.9.2, and pm2 control. \n"
printf "  8.  nodeadmin - MySQL admin web interface, plus express and express-generator. \n"
printf "\n"
printf "\n"


printf "Do you want to continue?  (Y/n):\n"
read CONT
if [ $CONT == "n" ] || [ $CONT == 'N' ]; then
  printf "Good choice, you may be over your head.  Pools require hard work.\n"
  printf "Bye, but hope to see you again soon.\n"
  printf "\n"; printf "\n"
  exit 99
fi

#printf "\Here we go....\n"

if [ ! -r /etc/os-release ]
then
  printf "\nCannot read [/etc/os-release] so it appears that you are not running distribution \n[$UBUNTU_MANDATORY].\n"
  printf "Do hou want to continue? (Y/n): "
  read CONT
  if [ $CONT == "n" ] || [ $CONT == 'N' ]; then
    printf "\nBecause we can't read /etc/os-release we are exiting the installation.\n" 
    exit 98
  fi
fi


# /etc/os-release is in good shape, lets check it out.  We check out only the major and
# minor versions, not the point release.
readonly UBUNTU_VERSION=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | grep "$UBUNTU_MANDATORY" 2>/dev/null)
readonly UBUNTU_DISPLAY=$(echo $UBUNTU_VERSION | cut -f2 -d'=' 2>/dev/null)

if [ "$UBUNTU_VERSION" ==  "" ] 
then
  printf "Appears that you are running distribution [$UBUNTU_VERSION] which is not [$UBUNTU_MANDATORY]. \nDo you want to continue? (Y/n):"
  read CONT
  if [ $CONT == "n" ]; then 
    printf "Good choice, best not install unless you are running Linux distribution [$UBUNTU_MANDATORY].\n";
    exit 97
  fi
else
  printf "Good news, you are running Linux distribution [$UBUNTU_MANDATORY], specifically [$UBUNTU_DISPLAY]. \n"
  printf "This is good, so continuning the installation in 3 seconds...\n"
  sleep 8
fi

printf  "We highly recommend that you do not run this deployment as \"root\", so we'll verify.\n"
if [[ `whoami` == "root" ]]; then
    printf "We are not kidding, you cannot run this as the \"root\" user, so add the following to \n"
    printf "the bottom of your /etc/sudoers file and replace NON-ROOT-USER with the name of your \n"
    printf "non-root user:\n\n"
    printf "NON-ROOT-USER ALL=(ALL) NOPASSWD:ALL\n\n";
    exit 96
fi


#--
#--  MySQL setup
#--
printf  "\n\n"
printf  "#=---------------------------------------------------------------=#\n"
printf  "#=----------------------   MySQL setup  -------------------------=#\n"
printf  "#=---------------------------------------------------------------=#\n"
ROOT_SQL_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
CURUSER=$(whoami)
sudo timedatectl set-timezone Etc/UTC
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $ROOT_SQL_PASS"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $ROOT_SQL_PASS"
echo -e "[client]\nuser=root\npassword=$ROOT_SQL_PASS" | sudo tee /root/.my.cnf



#--
#--  Install/Update packages for $UBUNTU_DISPLAY
#--
printf  "\n\n"
printf  "#=---------------------------------------------------------------=#\n"
printf  "#=----------------- Installing lots of packages -----------------=#\n"
printf  "#=---------------------------------------------------------------=#\n"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install git python-virtualenv python3-virtualenv curl ntp build-essential screen cmake pkg-config libboost-all-dev libevent-dev libunbound-dev libminiupnpc-dev libunwind8-dev liblzma-dev libldns-dev libexpat1-dev libgtest-dev mysql-server lmdb-utils libzmq3-dev




#--
#--  Clone, build, and install the nodejs-pool
#--
printf  "\n\n"
printf  "#=---------------------------------------------------------------=#\n"
printf  "#=--------  Clone, build, and install the nodejs-pool  ----------=#\n"
printf  "#=---------------------------------------------------------------=#\n\n"
cd ~
git clone https://github.com/Snipa22/nodejs-pool.git  # Change this depending on how the deployment goes.
cd /usr/src/gtest
sudo cmake .
sudo make
sudo mv libg* /usr/lib/


#--
#--  Clone monerod, apply pathc, and start time daemon 
#--
printf  "\n\n"
printf  "#=---------------------------------------------------------------=#\n"
printf  "#=-------------  Clone, build, and install monerod  -------------=#\n"
printf  "#=---------------------------------------------------------------=#\n\n"
cd ~
sudo systemctl enable ntp
cd /usr/local/src
sudo git clone https://github.com/monero-project/monero.git
cd monero
sudo git checkout v0.11.1.0
curl https://raw.githubusercontent.com/Snipa22/nodejs-pool/master/deployment/monero_daemon.patch | sudo git apply -v
sudo make -j$(nproc)
sudo cp ~/nodejs-pool/deployment/monerod.service /lib/systemd/system/



#--
#--  Setup accounts and process raw blockchain
#--
printf  "#=---------------------------------------------------------------=#\n"
sudo useradd -m monerod -d /home/monerod



###BLOCKCHAIN_DOWNLOAD_DIR=$(sudo -u monerod mktemp -d)
###sudo -u monerod wget --limit-rate=50m -O $BLOCKCHAIN_DOWNLOAD_DIR/blockchain.raw https://downloads.getmonero.org/blockchain.raw
###sudo -u monerod /usr/local/src/monero/build/release/bin/monero-blockchain-import --input-file $BLOCKCHAIN_DOWNLOAD_DIR/blockchain.raw --batch-size 20000 --database lmdb#fastest --verify off --data-dir /home/monerod/.bitmonero


sudo -u monerod /usr/local/src/monero/build/release/bin/monero-blockchain-import --input-file /home/monerod/blockchain.raw --batch-size 20000 --database lmdb#fastest --verify off --data-dir /home/monerod/.bitmonero

####sudo -u monerod rm -rf $BLOCKCHAIN_DOWNLOAD_DIR

#--
#--  Auto start monerod, install nvm, Node v6.9.2, pm2, rsa Key, and setup for the 
#--
printf  "#=---------------------------------------------------------------=#\n"
sudo systemctl daemon-reload
sudo systemctl enable monerod
sudo systemctl start monerod
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
source ~/.nvm/nvm.sh
nvm install v6.9.2
cd ~/nodejs-pool
npm install
npm install -g pm2
openssl req -subj "/C=IT/ST=Pool/L=Daemon/O=Mining Pool/CN=mining.pool" -newkey rsa:2048 -nodes -keyout cert.key -x509 -out cert.pem -days 36500
mkdir ~/pool_db/
sed -r "s/(\"db_storage_path\": ).*/\1\"\/home\/$CURUSER\/pool_db\/\",/" config_example.json > config.json



#--
#--  Install web front end
#--
printf  "#=---------------------------------------------------------------=#\n"

cd ~
git clone https://github.com/mesh0000/poolui.git
cd poolui
npm install
./node_modules/bower/bin/bower update
./node_modules/gulp/bin/gulp.js build
cd build
sudo ln -s `pwd` /var/www



#--
#--  Install Caddy web server
#--
#--  CHANGE THE LOG FILES FOR CADDY SO THEY POINT TO /var/log LIKE NORMAL PEOPLE
#--
printf  "#=---------------------------------------------------------------=#\n"

CADDY_DOWNLOAD_DIR=$(mktemp -d)
cd $CADDY_DOWNLOAD_DIR
curl -sL "https://snipanet.com/caddy.tar.gz" | tar -xz caddy init/linux-systemd/caddy.service
sudo mv caddy /usr/local/bin
sudo chown root:root /usr/local/bin/caddy
sudo chmod 755 /usr/local/bin/caddy
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
sudo groupadd -g 33 www-data
sudo useradd -g www-data --no-user-group --home-dir /var/www --no-create-home --shell /usr/sbin/nologin --system --uid 33 www-data
sudo mkdir /etc/caddy
sudo chown -R root:www-data /etc/caddy
sudo mkdir /etc/ssl/caddy
sudo chown -R www-data:root /etc/ssl/caddy
sudo chmod 0770 /etc/ssl/caddy
sudo cp ~/nodejs-pool/deployment/caddyfile /etc/caddy/Caddyfile
sudo chown www-data:www-data /etc/caddy/Caddyfile
sudo chmod 444 /etc/caddy/Caddyfile
sudo sh -c "sed 's/ProtectHome=true/ProtectHome=false/' init/linux-systemd/caddy.service > /etc/systemd/system/caddy.service"
sudo chown root:root /etc/systemd/system/caddy.service
sudo chmod 644 /etc/systemd/system/caddy.service
sudo systemctl daemon-reload
sudo systemctl enable caddy.service
sudo systemctl start caddy.service
rm -rf $CADDY_DOWNLOAD_DIR
cd ~



#--
#--  finish install of pm2 and modules
#--  CHANGE THE LOG FILES FOR CADDY SO THEY POINT TO /var/log LIKE NORMAL PEOPLE
#--
printf  "#=---------------------------------------------------------------=#\n"

sudo env PATH=$PATH:`pwd`/.nvm/versions/node/v6.9.2/bin `pwd`/.nvm/versions/node/v6.9.2/lib/node_modules/pm2/bin/pm2 startup systemd -u $CURUSER --hp `pwd`
cd ~/nodejs-pool
sudo chown -R $CURUSER. ~/.pm2
echo "Installing pm2-logrotate in the background!"
pm2 install pm2-logrotate &


#--
#--  install lmdb, setup SQL tables for the pool, need to prompt for answers
#--
#--  CHANGE THE LOG FILES FOR PM2 SO THEY POINT TO /var/log LIKE NORMAL PEOPLE
#--
#--

printf  "#=---------------------------------------------------------------=#\n"
mysql -u root --password=$ROOT_SQL_PASS < deployment/base.sql
mysql -u root --password=$ROOT_SQL_PASS pool -e "INSERT INTO pool.config (module, item, item_value, item_type, Item_desc) VALUES ('api', 'authKey', '`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`', 'string', 'Auth key sent with all Websocket frames for validation.')"

mysql -u root --password=$ROOT_SQL_PASS pool -e "INSERT INTO pool.config (module, item, item_value, item_type, Item_desc) VALUES ('api', 'secKey', '`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`', 'string', 'HMAC key for Passwords.  JWT Secret Key.  Changing this will invalidate all current logins.')"

pm2 start init.js --name=api --log-date-format="YYYY-MM-DD HH:mm Z" -- --module=api

bash ~/nodejs-pool/deployment/install_lmdb_tools.sh
cd ~/nodejs-pool/sql_sync/
env PATH=$PATH:`pwd`/.nvm/versions/node/v6.9.2/bin node sql_sync.js

printf "\n";
printf "You're setup!  Please read the rest of the readme for the remainder of your setup and configuration\n"
printf "These steps include: Setting your Fee Address, Pool Address, Global Domain, and the Mailgun setup!\n\n"


printf  "#=---------------------------------------------------------------=#\n"
printf  "#=--------------  Install and configure nodeadmin  --------------=#\n"
printf  "#=---------------------------------------------------------------=#\n"
cd ~ && mkdir node-admin & cd node-admin
npm -y init
npm -y install express
sudo npm -y install express-generator -g
express --view=pug sqladmin
cd sqladmin
npm -y install nodeadmin
 




