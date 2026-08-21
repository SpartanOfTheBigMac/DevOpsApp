import boto3
from flask import Flask, request, gunicorn
from datetime import datetime, date
from botocore.exceptions import ClientError



app = Flask(__name__)
dynamodb = boto3.resource('dynamodb')
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
    devices.extend(response.get('Items', []))
    while 'LastEvaluatedKey' in response:
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        devices.extend(response.get('Items', []))
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
                'device_id': booking['device_id']
            })  

    except Exception as e:
        print(f"Error fetching bookings: {e}")

    return {'bookings': bookings}


@app.route('/book', methods=['POST'])
def book_device():
    device_id = request.form.get('device_id')
    booking_date = request.form.get('date')
    booking_time = request.form.get('time')
    user = request.form.get('user')

    if not device_id or not booking_date or not booking_time or not user:
             return {'error': 'All fields are required'}, 400

    device_id = device_id.strip()
    booking_date = booking_date.strip()
    booking_time = booking_time.strip()
    user = user.strip()

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

    try:
        table.put_item(
            Item=new_booking,
            ConditionExpression="attribute_not_exists(device_id) AND attribute_not_exists(#d)",
            ExpressionAttributeNames={"#d": "date"}
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            return {'error': 'That device is already booked for that date'}, 409
        print(f"Error saving booking: {e}")
        return {'error': 'Failed to save booking'}, 500

@app.route('/cancel', methods=['POST'])
def cancel_booking():
    device_id = request.form.get('device_id')
    booking_date = request.form.get('date')

    if not device_id or not booking_date:
        return {'error': 'device_id and date are required'}, 400

    try:
        table.delete_item(Key={'device_id': device_id, 'date': booking_date})
    except Exception as e:
        print(f"Error deleting booking: {e}")
        return {'error': 'Failed to delete booking'}, 500

    return {'message': 'Booking cancelled successfully'}, 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)