#!/bin/bash

###############################################################################
# Inspired from                                                               #
# https://community.letsencrypt.org/t/                                        #
# how-to-completely-automating-certificate-renewals-on-debian/5615            #
###############################################################################

###################
#  Configuration  #
###################

# This line MUST be present in all scripts executed by cron!
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Certs that will expire in less than this value will be renewed
REMAINING_DAYS_TO_RENEW=30

# Command to execute if certs have been renewed
SERVICES_TO_RELOAD="nginx postfix metronome"

# Parameters for email alert
EMAIL_ALERT_FROM="cron-certrenewer@domain.tld (Cron certificate renewer)"
EMAIL_ALERT_TO="ADMIN_EMAIL"
EMAIL_ALERT_SUBJ="WARNING: SSL certificate renewal for CERT_NAME failed!"

# Letsencrypt stuff

# The executable
LEBIN="/root/letsencrypt/letsencrypt-auto"
# The config file 
LECFG="/etc/letsencrypt/conf.ini"
# The directory where current .pem certificates are stored
LELIVE="/etc/letsencrypt/live"
# Renewal directory, which contains renewal configs for all certificates.
LERENEWAL="/etc/letsencrypt/renewal"

################
#  Misc tools  #
################

# -----------------------------------
# Given a certificate file, return the number of days before it expires
# -----------------------------------
function daysBeforeCertificateExpire()
{
    local CERT_FILE=$1
    local DATE_EXPIRE=$(openssl x509 -in $CERT_FILE -text -noout \
                       | grep "Not After"                        \
                       | cut -c 25-)
    local D1=$(date -d $DATE_EXPIRE +%s)
    local D2=$(date -d "now"        +%s)
    local DAYS_EXP=$(echo \( $D1 - $D2 \) / 86400 | bc)
    echo $DAYS_EXP
}

# -----------------------------------
# Send an alert email stating that the renewing of a cert failed, and paste the
# logs into the mail body
# -----------------------------------
function sendAlert()
{
    local CERT_NAME=$1
    local LOG_FILE=$2
    local SUBJ=$(echo $EMAIL_ALERT_SUBJ | sed "s/CERT_NAME/${CERT_NAME}/g")

    cat ${LOG_FILE}                     \
    | mail -aFrom:"${EMAIL_ALERT_FROM}" \
           -s "${SUBJ}"                 \
           ${EMAIL_ALERT_TO}
}

# -----------------------------------
# -----------------------------------
function restartServices()
{
    eval "/bin/sync"

    local SERVICE
    for SERVICE in ${SERVICES_TO_RESTART}
    do
        eval "service ${SERVICE} restart"
    done
}

###############################
#  Actual lets encrypt stuff  #
###############################

# -----------------------------------
# Given a certificate name, echo True or False if it will soon expire
# (see REMAINING_DAYS_TO_RENEW)
# -----------------------------------
function certificateNeedsToBeRenewed()
{
    local CERT_NAME=$1
    local CERT_FILE="${LELIVE}/${CERT_NAME}/cert.pem"
    local DAYS_BEFORE_EXPIRE=`daysBeforeCertificateExpire $CERT_FILE`

    if [[ ${DAYS_BEFORE_EXPIRE} -lt ${REMAINING_DAYS_TO_RENEW} ]]
    then
        echo "True"
    else
        echo "False"
    fi
}

# -----------------------------------
# Given a certificate name, attempt to renew it
# Stuff is logged in a file
# -----------------------------------
function renewCertificate() 
{
    local CERT_NAME=$1
    local LOG_FILE=$2
    local CERT_FILE="${LELIVE}/${CERT_NAME}/cert.pem"
    local CERT_CONF="${LERENEWAL}/${CERT_NAME}.conf"
    # Parse "domains = xxxx", we might need to remove the last character
    # if it's a comma 
    local DOMAINS=$(grep -o --perl-regex "(?<=domains \= ).*" "${CERT_CONF}")
    local LAST_CHAR=$(echo ${DOMAINS} | awk '{print substr($0,length,1)}')
    if [ "${LAST_CHAR}" = "," ]
    then
        local DOMAINS=$(echo ${DOMAINS} |awk '{print substr($0, 1, length-1)}')
    fi

    ${LEBIN} certonly          \
        --renew-by-default     \
        --config "${LECFG}"    \
        --domains "${DOMAINS}" \
        > $(LOG_FILE) 2>&1
}

# -----------------------------------
# Attempt to renew all certificates in LELIVE directory
# -----------------------------------
function renewAllCertificates()
{
    local AT_LEAST_ONE_CERT_RENEWED="False"
    
    # Loop on certificates in live directory
    local CERT
    for CERT in $(ls -1 "${LELIVE}")
    do
        # Check if current certificate needs to be renewed
        if [[ $(certificateNeedsToBeRenewed ${CERT}) == "True" ]]
        then
            # If yes, attempt to renew it
            local LOG_FILE="/tmp/cron-cert-renewer.log"
            renewCertificate ${CERT} ${LOG_FILE}

            # Check it worked
            if [[ $(certificateNeedsToBeRenewed $CERT) == "True" ]]
            then
                local AT_LEAST_ONE_CERT_RENEWED="True"
            else
                sendAlert ${CERT} ${LOG_FILE}
            fi
        fi
    done

    echo ${AT_LEAST_ONE_CERT_RENEWED}
}

###################
#  Main function  #
###################

function main()
{
    renewAllCertificates
}
main


