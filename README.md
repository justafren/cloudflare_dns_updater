
## Cloudflare DNS updater

I created this script as I self host a few applications on my home network and expose them publically through Cloudflare. 
Unfortunately, my ISP doesn't allow non-business customers to have a static IP address, so when my public IP changes all of my 
services go offline.  

When ran, this script gets a list of all the type "A" DNS records for a zone and then checks each records IP address against the 
current public IP address of the network it's being ran on. If they differ - it updates the dns record with new public IP 
and adds a comment to the record with the timestamp so I know the last time it has been updated.

#### Dependencies
Any type of environment that can run bash scripts  
`jq` installed  
`curl` installed  

You will also need;  
-Zone ID for the domain you are running this script against - To find this, go to the cloudflare dashboard -> click websites -> chose a domain name you want to run this script against and then the zone ID will be listed on that page   
-Cloudflare account email address  
-Cloudflare global API key - you can follow [this guide](https://developers.cloudflare.com/fundamentals/api/get-started/keys/) on how to generate one    

#### Setup
1. Clone this repository

2. Run `mv config.env.example config.env` and open the file  

3. Replace each config entry with the information you gathered above

4. Make sure the script is executable - `chmod +x cloudflare_dns_updater.sh` 

5. Run the script `./cloudflare_dns_updater.sh`
 
#### Run script as a cronjob
Why only automate half of the steps - lets run this as a cronjob so it automatically updates our records

The global rate limit for the Cloudflare API is 1200 requests per five minutes. Each time the script is run it will make `(number of dns records) * 2  + 1 `  requests - so in my case with 6 records it will make 13 requests each time it is ran. So unless you have over 100 DNS records we should be fine to run this script every minute.

I'm running on debian 11 but the steps should be generally the same across most unix systems

1. Run `crontab -e` to edit the crontab file
2. Add this entry, replacing the path to the script with the correct path;  
 `* * * * * $PATH_TO_SCRIPT/cloudflare_dns_updater.sh`
3. Close the editor

You can monitor it using this command to see if the cronjob is running `journalctl -u cron.service`. You should see the script being executed every minute.

The stdout/stderr logs from the script are sent to the users mail file, you can view that with this command - `tail /var/mail/$USER`

Now restart your router to get yourself a new IP address and verify that the records have been updated in the cloudflare dashboard as well as checking the output logs from the script

Once you are satisfied it's working you _may_ want to update the cronjob to pipe the output of the script into `/dev/null` to avoid the mail file filling up your hard drive. You can just add `>/dev/null 2>&1` to the end of the crontab entry like so;   
`* * * * * $PATH_TO_SCRIPT/cloudflare_dns_updater.sh >/dev/null 2>&1`