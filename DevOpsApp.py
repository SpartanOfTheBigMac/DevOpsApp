import boto3
from flask import Flask, request
from datetime import datetime, date


app = Flask(__name__)
#app.secret_key = ''  

#AWS_region = 

dynamodb = boto3.resource('dynamodb') #region_name= AWS_region)
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


@app.route('book', methods=['POST'])
def book_device():
    device_id = request.form.get('device_id')
    booking_date = request.form.get('date').strip()
    booking_time = request.form.get('time').strip()
    user = request.form.get('user').strip()

    if not device_id or not booking_date or not booking_time or not user:
        return {'error': 'All fields are required'}, 400

    # Check if the device is available
    available_devices = [item for item in Equipment if item['id'] == device_id]
    if not available_devices:
        return {'error': 'Device not found'}, 404

    # Create a new booking
    new_booking = {
        'device_id': device_id,
        'date': booking_date,
        'time': booking_time,
        'user': user
    }

    # Save the booking to DynamoDB
    try:
        table.put_item(Item=new_booking)
    except Exception as e:
        print(f"Error saving booking: {e}")
        return {'error': 'Failed to save booking'}, 500

    return {'message': 'Booking successful'}, 201

@app.route('/cancel', methods=['POST'])
def cancel_booking():
    item_id = request.form.get('item_id')

    if not item_id:
        return {'error': 'Item ID is required'}, 400

    # Delete the booking from DynamoDB
    try:
        table.delete_item(Key={'item_id': item_id})
    except Exception as e:
        print(f"Error deleting booking: {e}")
        return {'error': 'Failed to delete booking'}, 500

    return {'message': 'Booking cancelled successfully'}, 200

