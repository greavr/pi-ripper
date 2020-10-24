from twilio.rest import Client
from google.cloud import secretmanager
import logging
import google.cloud.logging
import os
import sys
from flask import jsonify

# Env Variables
LoggingClient = google.cloud.logging.Client()
project_id = os.environ['GCP_PROJECT']
target_number = os.environ['number']
account_sid = ""
auth_token = ""
sender_num = ""

# Function gets credentials from GCP Secret Manager
def GetSecrets():
    global project_id, account_sid, auth_token, sender_num

    try:
        client = secretmanager.SecretManagerServiceClient()
        sid_path = f"projects/{project_id}/secrets/sid/versions/latest"
        auth_path = f"projects/{project_id}/secrets/auth/versions/latest"
        sender_path = f"projects/{project_id}/secrets/sender_num/versions/latest"

        sid_raw_response = client.access_secret_version(request={"name": sid_path})
        auth_raw_response = client.access_secret_version(request={"name": auth_path})
        sender_raw_response = client.access_secret_version(request={"name": sender_path})

        account_sid = sid_raw_response.payload.data.decode("UTF-8")
        auth_token = auth_raw_response.payload.data.decode("UTF-8")
        sender_num = sender_raw_response.payload.data.decode("UTF-8")

        logging.info("Accessed secrets for Auth_tokent and SID")
        return True
    except:
        e = sys.exc_info()[0]
        logging.error("Unable to find secrets")
        logging.error(e)
        return False



def send_sms(request):
    # This Function Sends a txt message notification to target number
    global target_number, account_sid, auth_token, sender_num

    # Setup the logger
    LoggingClient.get_default_handler()
    LoggingClient.setup_logging()
    data = request.get_json()
    #data = {"movie":"test1","device":"raspberry-pi1"}
 
    # Your Account Sid and Auth Token from twilio.com/console
    if GetSecrets():
        # Create Twillio Txt
        client = Client(account_sid, auth_token)
    
        msg = f"{data['movie']} has finished ripping on {data['device']}"
    
        message = client.messages.create(
                                from_=sender_num,
                                body=msg,
                                to=target_number
                            )
        return "success"
    else:
        return "error"