#!/usr/bin/bash

#----------------------------------
# cPanel AutoConfig Script
# By Khalequzzaman Labonno
#----------------------------------

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root";
	exit 1
fi

#----------------------------------
# Detecting the Architecture
#----------------------------------

if ([ `uname -i` == x86_64 ] || [ `uname -m` == x86_64 ]); then
	ARCH=64
else
	ARCH=32
fi

#----------------------------------
# Checking OS and modules!
#----------------------------------

if [ "$(/usr/bin/whoami)" == "root" ]; then

	if [ -f /etc/redhat-release ]; then
		/usr/bin/yum install curl wget sudo openssl tar unzip -y --skip-broken &>/dev/null
		if [ -f /etc/yum.repos.d/mysql-community.repo ]; then
			/usr/bin/sed -i "s|enabled=1|enabled=0|g" /etc/yum.repos.d/mysql-community.repo &>/dev/null
		fi
		if [ ! -f /etc/yum.repos.d/epel.repo ]; then
			/usr/bin/yum install epel-release -y --skip-broken &>/dev/null
			/usr/bin/yum groupinstall "Development Tools" -y &>/dev/null
		else
			/usr/bin/sed -i "s|https|http|g" /etc/yum.repos.d/epel.repo &>/dev/null
		fi
		/usr/bin/yum-complete-transaction --cleanup-only &>/dev/null
		/usr/bin/yum update -y --skip-broken &>/dev/null
	elif [ -f /etc/lsb-release ]; then
		/usr/bin/apt update &>/dev/null && /usr/bin/apt upgrade -y &>/dev/null
		/usr/bin/apt install curl wget sudo openssl tar unzip -y &>/dev/null
	fi

#----------------------------------
# Init cPanel Installation
#----------------------------------

	if [ ! -d /usr/local/cpanel ] ; then
		/usr/bin/systemctl stop NetworkManager.service && /usr/bin/systemctl disable NetworkManager.service
		/usr/bin/systemctl enable network.service && /usr/bin/systemctl start network.service
		hostname=$(curl -Ls https://scripts.names4u.win/cpanel/hostname)
		/usr/bin/hostnamectl set-hostname $hostname
		if [ -f /etc/redhat-release ]; then
			if [ ! "$(/usr/bin/rpm -E %{rhel})" == "7" ]; then
				cd /root && /usr/bin/mkdir cpanel_profile &>/dev/null && cd cpanel_profile && touch cpanel.config
				echo “mysql-version=10.3” > /root/cpanel_profile/cpanel.config
			fi
		fi
		cd /home && /usr/bin/curl -o latest -L https://securedownloads.cpanel.net/latest && /usr/bin/sh latest
		if [ -f /usr/local/cpanel/cpkeyclt ] ; then
			/usr/bin/clear && echo "Installation of cPanel/WHM has been completed.";
		fi
	else
		echo "cPanel/WHM is already installed on the server."
		/usr/local/cpanel/scripts/setupftpserver pure-ftpd --force &>/dev/null
		echo "Pure-FTP Installed & it has been initialized.";
		# Installing ionCube and SourceGuardian Loader
		/usr/bin/sed -i 's/phploader=.*/phploader=ioncube,sourceguardian/' /var/cpanel/cpanel.config
		/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings &>/dev/null
		/usr/local/cpanel/bin/checkphpini &>/dev/null && /usr/local/cpanel/bin/install_php_inis &>/dev/null
		if [ -f /etc/redhat-release ]; then
			/usr/bin/yum install ea-php*-php-sourceguardian ea-php*-php-ioncube10 -y --skip-broken &>/dev/null
		elif [ -f /etc/lsb-release ]; then
			/usr/bin/apt install ea-php*-php-sourceguardian ea-php*-php-ioncube10 -y &>/dev/null
		fi
		# Increasing php.ini limitations for all EA-PHP
		/usr/bin/sed -i 's/disable_functions = .*/disable_functions = /' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/max_execution_time = .*/max_execution_time = 180/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/max_input_time = .*/max_input_time = 180/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/max_input_vars = .*/max_input_vars = 3000/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/memory_limit = .*/memory_limit = 128M/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/post_max_size = .*/post_max_size = 64M/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/allow_url_fopen = .*/allow_url_fopen = On/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/bin/sed -i 's/file_uploads = .*/file_uploads = On/' /opt/cpanel/ea-php*/root/etc/php.ini &>/dev/null
		/usr/local/cpanel/scripts/restartsrv_cpsrvd &>/dev/null # Restarting cPanel to save the changes
		/usr/local/cpanel/bin/install-login-profile --install limits &>/dev/null # Enabling Shell Fork Bomb Protection
		# Installing ClamAV (Antivirus Software Toolkit)
		/scripts/update_local_rpm_versions --edit target_settings.clamav installed
		/usr/local/cpanel/scripts/check_cpanel_pkgs --fix --fix --targets=clamav &>/dev/null
		/usr/bin/ln -s /usr/local/cpanel/3rdparty/bin/clamscan /usr/local/bin/clamscan &>/dev/null
		/usr/bin/ln -s /usr/local/cpanel/3rdparty/bin/freshclam /usr/local/bin/freshclam &>/dev/null
		/usr/local/cpanel/scripts/check_cpanel_pkgs --fix &>/dev/null # Installation of Missing Packages/RPMs
		# Installing PHP extensions for popular CMS
		if [ -f /etc/redhat-release ]; then
			/usr/bin/yum install ea-php*-php-xmlrpc ea-php*-php-soap ea-php*-php-iconv ea-php*-php-mbstring -y &>/dev/null
			/usr/bin/yum install ea-php*-php-gmp ea-php*-php-bcmath ea-php*-php-intl ea-php*-php-fileinfo -y &>/dev/null
			/usr/bin/yum install ea-php*-php-pdo ea-php*-php-imap ea-php*-php-ldap ea-php*-php-zip -y &>/dev/null
		elif [ -f /etc/lsb-release ]; then
			/usr/bin/apt install ea-php*-php-xmlrpc ea-php*-php-soap ea-php*-php-iconv ea-php*-php-mbstring -y &>/dev/null
			/usr/bin/apt install ea-php*-php-gmp ea-php*-php-bcmath ea-php*-php-intl ea-php*-php-fileinfo -y &>/dev/null
			/usr/bin/apt install ea-php*-php-pdo ea-php*-php-imap ea-php*-php-ldap ea-php*-php-zip -y &>/dev/null
		fi
		# Performing Tweak Settings for cPanel server
		/usr/bin/sed -i 's/allowremotedomains=.*/allowremotedomains=1/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/resetpass=.*/resetpass=0/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/resetpass_sub=.*/resetpass_sub=0/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/enforce_user_account_limits=.*/enforce_user_account_limits=1/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/publichtmlsubsonly=.*/publichtmlsubsonly=0/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/emailusers_diskusage_warn_contact_admin=.*/emailusers_diskusage_warn_contact_admin=1/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/maxemailsperhour=.*/maxemailsperhour=50/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/emailsperdaynotify=.*/emailsperdaynotify=1000/' /var/cpanel/cpanel.config &>/dev/null
		/usr/bin/sed -i 's/exim-retrytime=.*/exim-retrytime=30/' /var/cpanel/cpanel.config &>/dev/null
		/usr/local/cpanel/scripts/restartsrv_cpsrvd &>/dev/null # Restarting cPanel to save the changes
		# Uninstallation of ImunifyAV from cPanel v88
		if [ -f /usr/bin/imunify-antivirus ]; then
			/usr/bin/wget https://repo.imunify360.cloudlinux.com/defence360/imav-deploy.sh -O /root/imav-deploy.sh &>/dev/null
			/usr/bin/chmod +x /root/imav-deploy.sh && /root/imav-deploy.sh --uninstall &>/dev/null && rm -f /root/imav-deploy.sh &>/dev/null
		fi
		# Disabling IPv6 address on the server's network
		grep -q '^net.ipv6.conf.all.disable_ipv6 = .*' /etc/sysctl.conf && grep -q '^net.ipv6.conf.default.disable_ipv6 = .*' /etc/sysctl.conf
		/usr/bin/sed -i 's/^net.ipv6.conf.all.disable_ipv6 = .*/net.ipv6.conf.all.disable_ipv6 = 1/' /etc/sysctl.conf
		/usr/bin/sed -i 's/^net.ipv6.conf.default.disable_ipv6 = .*/net.ipv6.conf.default.disable_ipv6 = 1/' /etc/sysctl.conf
		echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf && echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
		/usr/sbin/sysctl -p &>/dev/null # make the settings effective

		if [ -d /usr/local/cpanel/whostmgr/docroot/cgi/configserver/csf ] ; then
			echo "CSF is already installed on the server!";
		else
			echo -n "CSF not found! Would you like to install? (y/n) ";
			read yesno < /dev/tty
			if [ "x$yesno" = "xy" ] ; then
				/usr/bin/wget https://download.configserver.com/csf.tgz -O /usr/src/csf.tgz &>/dev/null
				/usr/bin/tar -xzf /usr/src/csf.tgz -C /usr/src && cd /usr/src/csf && sh install.sh &>/dev/null
				cd /root && /usr/bin/rm -rf /usr/src/csf /usr/src/csf.tgz /usr/src/error_log &>/dev/null
				/usr/bin/wget https://scripts.names4u.win/cpanel/csf_conf -O /etc/csf/csf.conf &>/dev/null
				/usr/bin/systemctl restart csf &>/dev/null && /usr/bin/systemctl restart lfd &>/dev/null
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
				/usr/bin/wget https://download.configserver.com/cmc.tgz -O /usr/src/cmc.tgz &>/dev/null
				/usr/bin/tar -xzf cmc.tgz -C /usr/src && cd /usr/src/cmc && /usr/bin/sh install.sh &>/dev/null
				cd /root && /usr/bin/rm -rf /usr/src/cmc /usr/src/cmc.tgz /usr/src/error_log &>/dev/null
				echo "Done! CMC successfully installed & enabled!";
			else
				echo "Successfully skipped the installation of CMC.";
			fi
		fi

		if [ -f /usr/bin/imunify360-agent ] ; then
			echo "Imunify360 is already installed on the server!";
		else
			echo -n "Imunify360 not found! Would you like to install? (y/n) ";
			read yesno < /dev/tty
			if [ "x$yesno" = "xy" ] ; then
				/usr/bin/wget https://repo.imunify360.cloudlinux.com/defence360/i360deploy.sh -O /root/i360deploy.sh &>/dev/null
				/usr/bin/chmod +x /root/i360deploy.sh && /root/i360deploy.sh &>/dev/null
				cd /root && /usr/bin/rm -f /root/i360deploy.sh /root/error_log &>/dev/null
				echo "Done! Imunify360 successfully installed & enabled!";
			else
				echo "Successfully skipped the installation of Imunify360.";
			fi
		fi

		if [ -d /usr/local/cpanel/whostmgr/docroot/cgi/softaculous ] ; then
			echo "Softaculous is already installed on the server!";
		else
			echo -n "Softaculous not found! Would you like to install? (y/n) ";
			read yesno < /dev/tty
			if [ "x$yesno" = "xy" ] ; then
				/usr/bin/sed -i -e \'s/127.0.0.1.*api.softaculous.com//g\' \'/etc/hosts\' &>/dev/null
				/usr/bin/sed -i \'/^$/d\' \'/etc/hosts\' &>/dev/null # Remove API from /etc/hosts File
				/usr/bin/wget https://files.softaculous.com/install.sh -O /root/install.sh &>/dev/null
				/usr/bin/chmod +x /root/install.sh && /root/install.sh &>/dev/null
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
				/usr/bin/wget https://wp-toolkit.plesk.com/cPanel/installer.sh -O /root/installer.sh &>/dev/null
				/usr/bin/chmod +x /root/installer.sh && /root/installer.sh &>/dev/null
				echo "Done! WP Toolkit successfully installed on your server!";
			else
				echo "Successfully skipped the installation of WP Toolkit.";
			fi
		fi

		if [ -f /etc/redhat-release ] ; then
			echo "Shortly you'll be asked for the installation of JB";
			echo "Firstly, JetBackup4 & secondly JetBackup5 process.";
			echo "If you wish to install JetBackup5, please skip JB4.";
			if [ -d /usr/local/jetapps/var/lib/JetBackup/Core/ ] ; then
				echo "JetBackup 4 is already installed on the server!";
			else
				echo -n "JetBackup 4 not found! Would you like to install? (y/n) ";
				read yesno < /dev/tty
				if [ "x$yesno" = "xy" ] ; then
					/usr/bin/yum install https://repo.jetlicense.com/centOS/jetapps-repo-latest.rpm -y &>/dev/null
					/usr/bin/yum clean all --enablerepo=jetapps* &>/dev/null
					/usr/bin/yum install jetapps-cpanel --disablerepo=* --enablerepo=jetapps -y &>/dev/null
					/usr/bin/jetapps --install jetbackup stable &>/dev/null
					echo "Done! JetBackup 4 successfully installed on your server!";
				else
					echo "Successfully skipped the installation of JetBackup 4.";
				fi
			fi
		fi

		if [ -d /usr/local/jetapps/var/lib/jetbackup5/Core/ ] ; then
			echo "JetBackup 5 is already installed on the server!";
		else
			echo -n "JetBackup 5 not found! Would you like to install? (y/n) ";
			read yesno < /dev/tty
			if [ "x$yesno" = "xy" ] ; then
				/usr/bin/bash <(/usr/bin/curl -LSs https://repo.jetlicense.com/static/install) &>/dev/null
				/usr/bin/jetapps --install jetbackup5-cpanel stable &>/dev/null
				echo "Done! JetBackup 5 successfully installed on your server!";
			else
				echo "Successfully skipped the installation of JetBackup 5.";
			fi
		fi

		if [ -f /usr/local/lsws/admin/misc/lscmctl ] ; then
			echo "LiteSpeed is already installed on the server!";
		else
			echo -n "LiteSpeed not found! Would you like to install? (y/n) ";
			read yesno < /dev/tty
			if [ "x$yesno" = "xy" ] ; then
				touch /root/lsws-install.sh
				echo "serial_no="TRIAL"
php_suexec="2"
port_offset="1000"
admin_user="admin"
admin_pass="a1234567"
admin_email="root@localhost"
easyapache_integration="1"
auto_switch_to_lsws="1"
deploy_lscwp="0"" > "/root/lsws.options";
				/usr/bin/wget https://get.litespeed.sh -O /root/lsws-install.sh &>/dev/null
				/usr/bin/sh /root/lsws-install.sh TRIAL &>/dev/null
				/usr/bin/wget https://litespeedtech.com/packages/cpanel/buildtimezone_ea4.tar.gz -O /root/buildtimezone_ea4.tar.gz &>/dev/null
				/usr/bin/tar -xzvf /root/buildtimezone_ea4.tar.gz &>/dev/null
				/usr/bin/chmod a+x /root/buildtimezone*.sh && /root/buildtimezone_ea4.sh y &>/dev/null
				/usr/sbin/yum-complete-transaction --cleanup-only &>/dev/null
				/usr/bin/yum install ea-php*-php-devel -y --skip-broken 1> /dev/null
				/usr/bin/yum remove ea-apache24-mod_ruid2 -y &>/dev/null
				/usr/local/lsws/admin/misc/lscmctl cpanelplugin --install &>/dev/null
				/usr/local/lsws/admin/misc/lscmctl setcacheroot &>/dev/null
				/usr/local/lsws/admin/misc/lscmctl scan &>/dev/null
				/usr/local/lsws/admin/misc/lscmctl enable -m &>/dev/null
				/usr/bin/rm -f /root/buildtimezone* /root/lsws* &>/dev/null
				echo "Done! LiteSpeed successfully installed on your server!";
			else
				echo "Successfully skipped the installation of LiteSpeed.";
			fi
		fi

		if [ -f /etc/redhat-release ] ; then
			if [[ -f /usr/sbin/clnreg_ks && -f /usr/bin/cldetect ]] ; then
				echo "CloudLinux is already installed on the server!";
			else
				echo -n "CloudLinux not found! Would you like to install? (y/n) ";
				read yesno < /dev/tty
				if [ "x$yesno" = "xy" ] ; then
					/usr/bin/wget https://repo.cloudlinux.com/cloudlinux/sources/cln/cldeploy -O /root/cldeploy &>/dev/null
					cd /home && /usr/bin/sh cldeploy --skip-registration -k 999 &> /dev/null
					/usr/bin/yum install lvemanager -y &> /dev/null
					/usr/bin/yum groupinstall alt-php alt-nodejs alt-python alt-ruby -y &> /dev/null
					/usr/bin/yum install ea-apache24-mod_suexec -y &> /dev/null
					/usr/bin/yum install ea-apache24-mod-alt-passenger -y &> /dev/null
					/usr/bin/yum install grub2 --disableexcludes=all -y &> /dev/null
					/usr/bin/yum install cagefs -y &> /dev/null && /usr/sbin/cagefsctl –init &> /dev/null
					echo "Done! CloudLinux successfully installed on your server!";
				else
					echo "Successfully skipped the installation of CloudLinux.";
				fi
			fi
		fi

		# End of cPanelConfig Shell Script
	fi
	/usr/bin/rm -f /root/install* /root/error_log* /root/i360deploy* &>/dev/null
fi
