#!/bin/bash

echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
systemctl restart sshd.service
yum install httpd php -y

cat <<EOF > /var/www/html/index.php
<?php
\$output = shell_exec('echo $HOSTNAME');
echo "<h1><center><pre>\$output</pre></center></h1>";
echo "<h1><center>This is terraform-webserver</center></h1>"
?>
EOF


systemctl restart php-fpm.service httpd.service
systemctl enable php-fpm.service httpd.service