import requests
import os
from dotenv import load_dotenv

load_dotenv()
access_token = os.getenv("WHATSAPP_TOKEN")  # Ensure you have set this in your .env file

whatsapp_id = os.getenv("WHATSAPP_ID")  # Ensure you have set this in your .env file

def call(phone_number="917000978867"):
    url = f"https://graph.facebook.com/v22.0/{whatsapp_id}/calls"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
        }
    req_body = {
        "messaging_product": "whatsapp",
        "to": phone_number,
        "action": "connect",
        "session": {
            "sdp": "v=0\r\no=- 7669997803033704573 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\na=group:BUNDLE 0\r\na=extmap-allow-mixed\r\na=msid-semantic: WMS 3c28addc-03b7-4170-b5cd-535bfe767e75\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 0 8 110 126\r\nc=IN IP4 0.0.0.0\r\na=rtcp:9 IN IP4 0.0.0.0\r\na=ice-ufrag:6O0H\r\na=ice-pwd:TYCbtfOrBMPpfxFRgSbYnuTI\r\na=ice-options:trickle\r\na=fingerprint:sha-256 9F:45:2C:A8:C3:C0:CC:9B:59:4F:D1:02:56:52:FA:36:00:BE:C0:79:87:B3:D9:9C:3E:BF:60:98:25:B4:26:FC\r\na=setup:active\r\na=mid:0\r\na=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level\r\na=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time\r\na=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01\r\na=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid\r\na=sendrecv\r\na=msid:3c28addc-03b7-4170-b5cd-535bfe767e75 38c455bc-3727-4129-b336-8cd2c6a68486\r\na=rtcp-mux\r\na=rtcp-rsize\r\na=rtpmap:111 opus/48000/2\r\na=rtcp-fb:111 transport-cc\r\na=fmtp:111 minptime=10;useinbandfec=1\r\na=rtpmap:63 red/48000/2\r\na=fmtp:63 111/111\r\na=rtpmap:9 G722/8000\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\na=rtpmap:110 telephone-event/48000\r\na=rtpmap:126 telephone-event/8000\r\na=ssrc:2430753100 cname:MPddPt/R2ioP4vCm\r\na=ssrc:2430753100 msid:3c28addc-03b7-4170-b5cd-535bfe767e75 38c455bc-3727-4129-b336-8cd2c6a68486\r\n",
            "sdp_type": "offer"
        }
    }
    response = requests.post(url, headers=headers, json=req_body)
    print("Status Code:", response.status_code)
    print("Response:", response.json())

def send_whatsapp_message(text:str,number:str="917000978867"):
    """
    Sends a WhatsApp message using the WhatsApp Cloud API.
    """
    # Replace with your WhatsApp Cloud API URL and access token

    url = f"https://graph.facebook.com/v22.0/{whatsapp_id}/messages"


    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }

    # text += "\n\nTo manage your google calendar, reminders, notion, gmail, etc. from whatsapp, Please visit: \nhttps://app.sigmoyd.in/manage-auths"

    data = {
        "messaging_product": "whatsapp",
        "to": number,
        "type": "text",
        # "template": {
        #     "name": "hello_world",
        #     "language": {
        #         "code": "en_US"
        #     }
        # }
        "text": {
            "body": text
        }
    }

    response = requests.post(url, headers=headers, json=data)

    print("Status Code:", response.status_code)
    print("Response:", response.json())
    return response.json()