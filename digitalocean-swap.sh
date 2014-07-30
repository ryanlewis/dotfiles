swapsize=${1-2G}

fallocate -l $swapsize /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo "/swapfile none swap sw 0 0" >> /etc/fstab

sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
