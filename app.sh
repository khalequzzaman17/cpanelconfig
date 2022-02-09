#!/bin/bash
############################################################
# cP AutoConfig Script - Written by Khalequzzaman Labonno
############################################################

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 
	exit 1
fi

if [ -f /etc/redhat-release ]; then
	yum install curl wget sudo openssl tar unzip -y --skip-broken &>/dev/null
if [ -f /etc/yum.repos.d/mysql-community.repo ]; then
	sed -i "s|enabled=1|enabled=0|g" /etc/yum.repos.d/mysql-community.repo
fi

if [ ! -f /etc/yum.repos.d/epel.repo ]; then
	yum install epel-release -y --skip-broken &>/dev/null
else
	sed -i "s|https|http|g" /etc/yum.repos.d/epel.repo
fi

if [ ! -d /usr/local/cpanel ] ; then
	systemctl stop NetworkManager.service && systemctl disable NetworkManager.service
	systemctl enable network.service && systemctl start network.service
  hostname=$(curl -Ls https://scripts.names4u.win/cpanel/hostname)
	hostnamectl set-hostname $hostname
	cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest
else
    echo "cPanel/WHM is already installled on the server."
fi

if [ -d /usr/local/cpanel ] ; then
	/usr/local/cpanel/scripts/setupftpserver pure-ftpd --force &>/dev/null
	echo "Pure-FTP Installed & it has been initialized.";
	# Installing ionCube and SourceGuardian Loader
	sed -i 's/phploader=.*/phploader=ioncube,sourceguardian/' /var/cpanel/cpanel.config
	/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings &>/dev/null
	/usr/local/cpanel/bin/checkphpini && /usr/local/cpanel/bin/install_php_inis
	yum install ea-php*-php-sourceguardian ea-php*-php-ioncube10 -y --skip-broken &>/dev/null
	# Increasing php.ini limitations for all EA-PHP
	sed -i 's/disable_functions = .*/disable_functions = /' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/max_execution_time = .*/max_execution_time = 180/' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/max_input_time = .*/max_input_time = 180/' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/max_input_vars = .*/max_input_vars = 3000/' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/memory_limit = .*/memory_limit = 128M/' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/post_max_size = .*/post_max_size = 64M/' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/allow_url_fopen = .*/allow_url_fopen = On/' /opt/cpanel/ea-php*/root/etc/php.ini
	sed -i 's/file_uploads = .*/file_uploads = On/' /opt/cpanel/ea-php*/root/etc/php.ini
	yum update -y --skip-broken &>/dev/null && /usr/local/cpanel/scripts/restartsrv_cpsrvd &>/dev/null
	yum-complete-transaction --cleanup-only &>/dev/null # Cleaning-up unfinished transactions remaining
	/usr/local/cpanel/bin/install-login-profile --install limits # Enabling Shell Fork Bomb Protection
	# Installing ClamAV (Antivirus Software Toolkit)
	/scripts/update_local_rpm_versions --edit target_settings.clamav installed
	/usr/local/cpanel/scripts/check_cpanel_pkgs --fix --fix --targets=clamav &>/dev/null
	ln -s /usr/local/cpanel/3rdparty/bin/clamscan /usr/local/bin/clamscan &>/dev/null
	ln -s /usr/local/cpanel/3rdparty/bin/freshclam /usr/local/bin/freshclam &>/dev/null
	/usr/local/cpanel/scripts/check_cpanel_pkgs --fix &>/dev/null
	# Installing some PHP extensions for popular CMS
	yum install ea-php*-php-xmlrpc ea-php*-php-soap ea-php*-php-iconv ea-php*-php-mbstring -y &>/dev/null
	yum install ea-php*-php-gmp ea-php*-php-bcmath ea-php*-php-intl ea-php*-php-fileinfo -y &>/dev/null
	yum install ea-php*-php-pdo ea-php*-php-imap ea-php*-php-ldap ea-php*-php-zip -y &>/dev/null
	# Performing Tweak Settings for cPanel/WHM server
	sed -i 's/allowremotedomains=.*/allowremotedomains=1/' /var/cpanel/cpanel.config
	sed -i 's/resetpass=.*/resetpass=0/' /var/cpanel/cpanel.config
	sed -i 's/resetpass_sub=.*/resetpass_sub=0/' /var/cpanel/cpanel.config
	sed -i 's/enforce_user_account_limits=.*/enforce_user_account_limits=1/' /var/cpanel/cpanel.config
	sed -i 's/publichtmlsubsonly=.*/publichtmlsubsonly=0/' /var/cpanel/cpanel.config
	sed -i 's/emailusers_diskusage_warn_contact_admin=.*/emailusers_diskusage_warn_contact_admin=1/' /var/cpanel/cpanel.config
	sed -i 's/maxemailsperhour=.*/maxemailsperhour=50/' /var/cpanel/cpanel.config
	sed -i 's/emailsperdaynotify=.*/emailsperdaynotify=1000/' /var/cpanel/cpanel.config
	sed -i 's/exim-retrytime=.*/exim-retrytime=30/' /var/cpanel/cpanel.config
	/usr/local/cpanel/scripts/restartsrv_cpsrvd &>/dev/null
	yum install epel-release -y &>/dev/null && yum groupinstall "Development Tools" -y &>/dev/null
	# Disabling IPv6 address on the server's network
	grep -q '^net.ipv6.conf.all.disable_ipv6 = .*' /etc/sysctl.conf && grep -q '^net.ipv6.conf.default.disable_ipv6 = .*' /etc/sysctl.conf
	sed -i 's/^net.ipv6.conf.all.disable_ipv6 = .*/net.ipv6.conf.all.disable_ipv6 = 1/' /etc/sysctl.conf
	sed -i 's/^net.ipv6.conf.default.disable_ipv6 = .*/net.ipv6.conf.default.disable_ipv6 = 1/' /etc/sysctl.conf
	echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf && echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
	sysctl -p &>/dev/null # make the settings effective
if [ -d /usr/local/cpanel/whostmgr/docroot/cgi/configserver/csf ] ; then
	echo "CSF is already installed on the server!";
else
	echo -n "CSF not found! Would you like to install? (y/n) ";
	read yesno < /dev/tty
	if [ "x$yesno" = "xy" ] ; then
		cd /usr/src && rm -rf csf*
		/usr/bin/wget https://download.configserver.com/csf.tgz &>/dev/null
		tar -xzf csf.tgz && cd csf && sh install.sh &>/dev/null && cd ..
		rm -rf csf* && cd /root
		wget https://scripts.names4u.win/cpanel/csf_conf -O /etc/csf/csf.conf &>/dev/null
		systemctl restart csf &>/dev/null && systemctl restart lfd &>/dev/null
		echo "Done! CSF successfully installed & enabled!";
	else
		echo "Successfully skipped the installation of CSF.";
	fi
fi

if [ -d /usr/local/cpanel/whostmgr/docroot/cgi/configserver/cmc ] ; then
	echo "CMC is already installed on the server!";
else
	echo -n "CMC not found! Would you like to install? (y/n) ";
	read yesno < /dev/tty
	if [ "x$yesno" = "xy" ] ; then
		cd /usr/src && rm -rf cmc*
		/usr/bin/wget https://download.configserver.com/cmc.tgz &>/dev/null
		tar -xzf cmc.tgz && cd cmc && sh install.sh &>/dev/null && cd ..
		rm -rf cmc* && cd /root
		echo "Done! CMC successfully installed & enabled!";
	else
		echo "Successfully skipped the installation of CMC.";
	fi
fi

if [ -d /usr/local/cpanel/whostmgr/docroot/cgi/softaculous ] ; then
	echo "Softaculous is already installed on the server!";
else
	echo -n "Softaculous not found! Would you like to install? (y/n) ";
	read yesno < /dev/tty
	if [ "x$yesno" = "xy" ] ; then
		/usr/bin/wget -N https://files.softaculous.com/install.sh &>/dev/null
		chmod +x install.sh && ./install.sh &>/dev/null && rm -rf install*
		echo "Done! Softaculous successfully installed on your server!";
	else
		echo "Successfully skipped the installation of Softaculous.";
	fi
fi

if [ -d /usr/local/cpanel/3rdparty/wp-toolkit ] ; then
	echo "WP Toolkit is already installed on the server!";
else
	echo -n "WP Toolkit not found! Would you like to install? (y/n) ";
	read yesno < /dev/tty
	if [ "x$yesno" = "xy" ] ; then
		/usr/bin/wget -N https://wp-toolkit.plesk.com/cPanel/installer.sh &>/dev/null
		chmod +x installer.sh && ./installer.sh &>/dev/null && rm -rf installer*
		echo "Done! WP Toolkit successfully installed on your server!";
	else
		echo "Successfully skipped the installation of WP Toolkit.";
	fi
fi
# end
fi
	rm -rf /root/install* /root/error_log* /root/i360deploy*
fi
