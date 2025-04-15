#Idk what we need yet so I'm just importing a lot for now. I'll clean this up late
from flask import Flask, url_for, redirect, session, flash, render_template, request
#import hashlib
import MySQLdb
#import re
#import sys
#import json

app = Flask(__name__, static_url_path="")
app.secret_key = 'flight_tracking'

#reads password from file so that we can avoid that issue
def get_db_password():
    with open('password.txt', 'r') as f:
        return f.read().strip()

db_password = get_db_password()
#print(db_password)

# connect to DB
db_connection = MySQLdb.connect(host="127.0.0.1",
						   user = "root",
						   passwd = db_password,
						   db = "flight_tracking",
						   port = 3306)


#the first page you should land on
@app.route('/', methods=['GET', 'POST'])
def index():
	return render_template('index.html')


@app.route('/view_people', methods=['GET', 'POST'])
def view_people():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM person')
		people = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		# print(people)
		return render_template('view_people.html', people=people, headers=column_names)
	except Exception as e:
		flash(f"Error fetching people: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()


@app.route('/view_passengers', methods=['GET', 'POST'])
def view_passengers():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM person join passenger on person.personID = passenger.personID')
		people = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		# print(people)
		return render_template('view_passengers.html', people=people, headers=column_names)
	except Exception as e:
		flash(f"Error fetching passengers: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()

@app.route('/flights_in_the_air')
def flights_in_the_air():
    try:
        cursor = db_connection.cursor()
        cursor.execute('SELECT * FROM flights_in_the_air')
        flights = cursor.fetchall()
        column_names = [desc[0] for desc in cursor.description]
        return render_template('flights_in_the_air.html', flights=flights, headers=column_names)
    except Exception as e:
        flash(f"Error fetching flights in the air: {e}")
        return redirect(url_for('index'))
    finally:
        cursor.close()


#helper method for forms with possible null or empty values
def normalize(val):
	if val.strip() == '' or val.strip().lower() == 'null':
		return None
	return val


#for adding a person, found on view_people.html
@app.route('/add_person', methods=['GET', 'POST'])
def add_person():
	if request.method == 'POST':
		cursor = None
		try:
			personID = normalize(request.form['personID'])
			first_name = normalize(request.form['first_name'])
			last_name = normalize(request.form['last_name'])
			locationID = normalize(request.form['locationID'])
			taxID = normalize(request.form['taxID'])
			experience = normalize(request.form['experience'])
			miles = normalize(request.form['miles'])
			funds = normalize(request.form['funds'])

			#fix ints
			experience = int(experience) if experience is not None else None
			miles = int(miles) if miles is not None else None
			funds = int(funds) if funds is not None else None

			cursor = db_connection.cursor()
			cursor.callproc('add_person', (personID, first_name, last_name, locationID, taxID, experience, miles, funds))
			#db_connection.commit()

			result = list(cursor.fetchall())
			#print(result)
			if cursor.description:
				column_names = [desc[0] for desc in cursor.description]
			#print(column_names)
			if result and column_names:
				if 'error_message' in column_names:
					flash(result[0][0].strip("(),'"))
			else:
				flash('Person added successfully!')
		except Exception as e:
			flash(f"Error adding person: {e}")
		finally:
			if cursor:
				cursor.close()
			db_connection.commit()
		return redirect(url_for('view_people'))
	return render_template('add_person.html')

if __name__ == '__main__':
	app.run(port=8000, debug=True)
    