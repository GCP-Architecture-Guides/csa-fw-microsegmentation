##  Copyright 2023 Google LLC
##  
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##  
##      https://www.apache.org/licenses/LICENSE-2.0
##  
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.


##  This code creates demo environment for CSA Network Firewall microsegmentation 
##  This demo code is not built for production workload ##

#! /bin/bash
cat <<EOF > /etc/apt/sources.list
deb https://packages.cloud.google.com/apt debian-bullseye-mirror main
deb https://packages.cloud.google.com/apt debian-bullseye-security-mirror main
deb https://packages.cloud.google.com/apt debian-bullseye-updates-mirror main
EOF
apt update
apt -y install apache2
apt -y install libapache2-mod-php
apt -y install php-curl
service apache2 reload
rm /var/www/html/index.html
cat <<EOF > /var/www/html/index.php
<?php

# Set the API URL to consume
\$url = "http://hr_pplapp_us-east1_prod_middleware.microseg.private/api.php";

# Grab data from the API
\$client = curl_init(\$url);
curl_setopt(\$client,CURLOPT_RETURNTRANSFER,true);
\$response = curl_exec(\$client);

# JSON decode response
\$rows = json_decode(\$response, true);

# Create a heading and table to present data to the user
?>
<!DOCTYPE html>
<html>
<head>
  <title>HR People App - Firewall Microsegmentation - 3 Tier Example</title>
</head>

<body>
<h1>HR People App - Firewall Microsegmentation - 3 Tier Example</h1>
<h2>Character and Performance Database</h2>
<table border="2" cellspacing="4" cellpadding="4">
<tr>
<td><b>Name</b></td>
<td><b>Performance</b></td>
</tr>

<?php
# Iterate through response rows and present to the user
foreach (\$rows as \$row) {
  echo "<tr>\n";
  echo "<td>" . \$row['name'] . "</td><td>" . \$row['performance'] . "</td>\n";
  echo "</tr>\n";
}
?>

</table>
</body>
</html>
EOF
