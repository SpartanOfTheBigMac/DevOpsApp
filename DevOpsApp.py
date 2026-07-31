import boto3
from flask import Flask
from datetime import datetime, date

app = Flask(__name__)

# AWS crap here



dynamodb = boto3.resource('dynamodb', region_name= AWS_region)
table = dynamodb.Table('Hardware')

Equipment = [      
        {'id':'ipad-trolley', 'name':'Tech services iPad Trolley (15x devices)'},
        {'id':'chromebook-trolley-1', 'name':'Tech services Chromebook Trolley (16x devices)'},
        {'id':'chromebook-trolley-2', 'name':'Library Chromebook Trolley (16x devices)'},
        {'id':'chromebook-trolley-3', 'name':'English Chromebook Trolley (32x devices)'},
        {'id':'chromebook-trolley-4', 'name':'Maths Chromebook Trolley (32x devices)'},
    ]

Equipment_by_id = {item['id']: item['name'] for item in Equipment}

def device_table_scan():
    devices = []
    response = table.scan()
    devices.extend(response.get('items', []))
    while 'LastEvaluatedKey' in response:
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        devices.extend(response.get('items', []))
    return devices



@app.route('/', methods=['GET'])
def index():
    bookings = []
    try:
        raw_bookings = device_table_scan()
        today_str = date.today().isoformat()
        upcoming_bookings = [booking for booking in raw_bookings if booking['date'] >= today_str]
        upcoming_bookings.sort(key=lambda x: (x['date'], x['time']))

        for booking in upcoming_bookings:
            device_name = Equipment_by_id.get(booking['device_id'], 'Unknown Device')
            bookings.append({
                'device_name': device_name,
                'date': booking['date'],
                'time': booking['time'],
                'item_id': booking['item_id']
            })

    except Exception as e:
        print(f"Error fetching bookings: {e}")

    return {'bookings': bookings}



