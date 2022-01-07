#!/usr/bin/env bash

# Fail on unset variables and command errors
set -ue -o pipefail

# Prevent commands misbehaving due to locale differences
export LC_ALL=C

# Set PATH
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

# Monitor Configuration
STRING='Pending'
EXPECTED=1
THRESHOLD=1
THRESHOLD_FILE=counter_fcc.txt
# msmtp
MSMTP_CONFIG=/usr/lib/msmtp/.msmtprc
MSMTP_ACCOUNT=spectrum
# Email
USE_EMAIL=false
EMAIL_TO="me@me.com you@you.com"
# SMS Gateway
USE_SMS=false
SMS_TO="2122222222@txt.att.net 6466666666@messaging.sprintpcs.com 3322222222@tmomail.net 4155555555@vtext.com"

# Use a temporary directory
cd /tmp

# Perform Search
curl -s -o GenericSearchResult -d 'callsign=&FRN=&scope_of_service=&id_file_num=&name_licensee=Astra Space&purpose_of_operation=&narrative_comments=&grant_date_from=&receipt_date_from=&expiration_date_from=&emission=&experiment_type=&tx_city=&transmitter_state=&frequency_type=&lower_frequency=&upper_frequency=&power_type=&erp_from=&erp_to=&show_records=10&pending=Y&special_temporary_authority=Y&conventional_license=Y' -X POST https://apps.fcc.gov/oetcf/els/reports/GenericSearchResult.cfm

# Check the file size
if [[ $(stat -c %s GenericSearchResult) -lt 10240 ]]; then
  echo 'cURL failed'
  exit 1
fi

# Count the total number of lines of STRING
records=$(grep "$STRING" GenericSearchResult | wc -l)
rm -f GenericSearchResult

if ! [[ "$records" -eq "$EXPECTED" ]] ; then
  echo "Application status changed!"

  # Increment the counter
  if [[ -f $THRESHOLD_FILE ]]; then
    COUNTER=$(cat $THRESHOLD_FILE)
    let COUNTER++
  else
    COUNTER=1
  fi
  echo $COUNTER > $THRESHOLD_FILE

  if [[ "$COUNTER" -le "$THRESHOLD" ]]; then
    # Send emails
    if $USE_EMAIL; then
      for recipient in $EMAIL_TO
      do
        msmtp -C $MSMTP_CONFIG -a $MSMTP_ACCOUNT $recipient <<EOF
From: "FCC Monitor" <fcc@twc.com>
To: $recipient
Subject: FCC Alert! - $COUNTER/$THRESHOLD
Content-Type: text/plain; charset=utf-8

The FCC has updated the status of Astra's application!
EOF
        sleep 1
      done
    fi
    # Send SMS messages via SMS Gateway
    if $USE_SMS; then
      for recipient in $SMS_TO
      do
        msmtp -C $MSMTP_CONFIG -a $MSMTP_ACCOUNT $recipient <<EOF
From: "FCC Monitor" <fcc@twc.com>
To: $recipient
Subject: FCC Alert! - $COUNTER/$THRESHOLD
Content-Type: text/plain; charset=utf-8

The FCC has updated the status of Astra's application!
EOF
        sleep 1
      done
    fi
  fi
else
  # Remove the counter file
  [[ -e $THRESHOLD_FILE ]] && rm -f $THRESHOLD_FILE
fi
