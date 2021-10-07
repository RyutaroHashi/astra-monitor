# FCC Monitor
* `string.sh` - parse HTML content of the [Experimental Licensing System Generic Search](https://apps.fcc.gov/oetcf/els/reports/GenericSearch.cfm) result. If it contains `STRING` more than `EXPECTED` times, notifications will be sent to recipients up to `THRESHOLD` times.

Use [SMS Gateway](https://en.wikipedia.org/wiki/SMS_gateway#Email_clients) or [SMS API](https://www.twilio.com/) to send SMS messages to a mobile device.

## Requirements
* cURL
* msmtp
* cron

## Setup
### msmtp
The major ISPs usually block emails if you try sending directly. To get around the problem, I use msmtp to route my messages through a third-party mail server such as Google, Yahoo, or Spectrum. msmtp is a simple mail transfer agent that supports SMTP Authentication over TLS/STARTTLS. Follow the steps below to setup msmtp on your system.
1. Install
   ```bash
   yum -y install msmtp
   useradd -rmd /usr/lib/msmtp msmtp
   mkdir /var/log/msmtp
   chmod 750 /var/log/msmtp
   chown msmtp.msmtp /var/log/msmtp
   ```
1. Configure
   ```bash
   su - msmtp
   cat > ~/.msmtprc <<EOF
   defaults
       tls on
       tls_starttls on
       tls_trust_file /etc/ssl/certs/ca-bundle.crt
       logfile /var/log/msmtp/msmtp.log
   
   account spectrum
       host mail.twc.com
       port 587
       auth on
       user EMAIL_ADDRESS
       password PASSWORD
       from EMAIL_ADDRESS
   EOF
   chmod 600 ~/.msmtprc
   ```
1. Test
   ```bash
   msmtp -a spectrum me@me.com <<EOF
   From: "FCC Monitor" <fcc@twc.com>
   To: me@me.com
   Subject: FCC Alert! - $COUNTER/$THRESHOLD
   Content-Type: text/plain; charset=utf-8
   
   The FCC has updated the status of Astra's application!
   EOF
   ```
1. Check the log
   ```bash
   tail -f /var/log/msmtp/msmtp.log
   ```

### cron
Set up scheduled tasks to monitor on a regular basis. Adjust the `hour (0 - 23)` and `day of week (0 - 6) (Sunday=0)` for the system time zone. See the following example for trading hours in PT (UTC/GMT-08:00).
```bash
# FCC Monitor (M-F 4AM-8PM ET)
*/5 1-17 * * 1-5 /opt/fcc-monitor/string.sh >/dev/null 2>&1
```
