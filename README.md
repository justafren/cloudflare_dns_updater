
I created this script as I self host a few applications on my home network and expose them publically through Cloudflare. 
Unfortunately, my ISP doesn't allow non-business customers to have a static IP address, so when my public IP changes all of my 
services go offline.  

When ran, this script gets a list of all the type "A" DNS records for a zone and then checks each records IP address against the 
current public IP address of the network it's being ran on. If they differ - it updates the dns record with new public IP 
and adds a comment to the record with the time this happened.  

####Dependencies
Some environment that can run bash scripts
`jq` installed
`curl` installed

You will also need;
-Zone ID for the domain you are running this script against - To find this, go to the cloudflare dashboard -> click websites then chose a domain name you want to run this script against and then the zone ID will be listed on that page 
-Cloudflare account email address
-Cloudflare global API key - you can follow [this guide](https://developers.cloudflare.com/fundamentals/api/get-started/keys/) on how to generate one  

####Setup
1. Clone this repository

2. Run `mv config.env.example config.env` and open the file  

3. Replace each config entry with the information you gathered above

4. Make sure the script is executable - `chmod +x cloudflare_dns_updater.sh` 

5. Run the script `./cloudflare_dns_updater.sh`
 