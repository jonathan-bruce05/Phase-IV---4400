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

#helper methods first:

#helper method for forms with possible null or empty values
def normalize(val):
	if val.strip() == '' or val.strip().lower() == 'null':
		return None
	return val



#the first page you should land on
@app.route('/', methods=['GET', 'POST'])
def index():
	return render_template('index.html')

#TODO: simulation cycle


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

#TODO: people_in_the_air view


#TODO: people_on_the_ground view

#passengers page
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

#TODO: passengers_board


#TODO: passengers_disembark


@app.route('/view_pilots', methods=['GET', 'POST'])
def view_pilots():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM person join pilot on person.personID = pilot.personID')
		people = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		# print(people)
		return render_template('view_pilots.html', people=people, headers=column_names)
	except Exception as e:
		flash(f"Error fetching pilots: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()

#TODO: grant_or_revoke_pilot_license


#TODO: assign_pilot


#TODO: recycle_crew



@app.route('/view_flights', methods=['GET', 'POST'])
def view_flights():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM flight')
		flights = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		# print(flights)
		return render_template('view_flights.html', flights=flights, headers=column_names)
	except Exception as e:
		flash(f"Error fetching flights: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()

#route_summary view
@app.route('/route_summary', methods=['GET', 'POST'])
def route_summary():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM route_summary')
		routes = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		return render_template('route_summary.html', routes=routes, headers=column_names)
	except Exception as e:
		flash(f"Error fetching route summary: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()

		
#TODO: offer_flight	


#TODO: retire_flight


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

@app.route('/flights_on_the_ground')
def flights_on_the_ground():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM flights_on_the_ground')
		flights = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		return render_template('flights_on_the_ground.html', flights=flights, headers=column_names)
	except Exception as e:
		flash(f"Error fetching flights on the ground: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()

#TODO: flight_landing

#TODO: flight_takeoff



#airplanes page
@app.route('/view_airplanes', methods=['GET', 'POST'])
def view_airplanes():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM airplane')
		airplanes = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		return render_template('view_airplanes.html', airplanes=airplanes, headers=column_names)
	except Exception as e:
		flash(f"Error fetching airplanes: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()

#add_airplane page
@app.route('/add_airplane', methods=['GET', 'POST'])
def add_airplane():

	if request.method == 'POST':
		cursor = None #this is here from when I was debugging add_person, I'll remove it later.
		try:
			airlineID = normalize(request.form['airlineID'])
			tailNum = normalize(request.form['tailNum'])
			seats = normalize(request.form['seats'])
			speed = normalize(request.form['speed'])
			locID = normalize(request.form['locID'])
			plane_type = normalize(request.form['type'])
			maintenanced = normalize(request.form['maintenanced'])
			model = normalize(request.form['model'])
			neo = normalize(request.form['neo'])
			#fix ints
			seats = int(seats) if seats is not None else None
			speed = int(speed) if speed is not None else None

			#fix maintenanced and neo
			if maintenanced is not None:
				maintenanced = 1 if maintenanced.lower() == 'true' else 0 if maintenanced.lower() == 'false' else None
			if neo is not None:
				neo = 1 if neo.lower() == 'true' else 0 if neo.lower() == 'false' else None



			cursor = db_connection.cursor()
			cursor.callproc('add_airplane', (airlineID, tailNum, seats, speed, locID, plane_type, maintenanced, model, neo))

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
				flash('Airplane added successfully!')
		except Exception as e:
			flash(f"Error adding airplane: {e}")
		finally:
			if cursor:
				cursor.close()
			db_connection.commit()
		return redirect(url_for('view_airplanes'))
	return render_template('add_airplane.html')

#airports page
@app.route('/view_airports', methods=['GET', 'POST'])
def view_airports():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM airport')
		airports = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		return render_template('view_airports.html', airports=airports, headers=column_names)
	except Exception as e:
		flash(f"Error fetching airports: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()


#alternative airports view
@app.route('/alternative_airports', methods=['GET', 'POST'])
def alternative_airports():
	try:
		cursor = db_connection.cursor()
		cursor.execute('SELECT * FROM alternative_airports')
		airports = cursor.fetchall()
		column_names = [desc[0] for desc in cursor.description]
		return render_template('alternative_airports.html', airports=airports, headers=column_names)
	except Exception as e:
		flash(f"Error fetching alternative airports: {e}")
		return redirect(url_for('index'))
	finally:
		cursor.close()


#add_airport page
@app.route('/add_airport', methods=['GET', 'POST'])
def add_airport():
	if request.method == 'POST':
		cursor = None
		try:
			airportID = normalize(request.form['airportID'])
			name = normalize(request.form['name'])
			city = normalize(request.form['city'])
			state = normalize(request.form['state'])
			country = normalize(request.form['country'])
			locID = normalize(request.form['locID'])
			#everything is a string so should be fixed


			cursor = db_connection.cursor()
			cursor.callproc('add_airport', (airportID, name, city, state, country, locID))

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
				flash('Airport added successfully!')
		except Exception as e:
			flash(f"Error adding airport: {e}")
		finally:
			if cursor:
				cursor.close()
			db_connection.commit()
		return redirect(url_for('view_airports'))
	return render_template('add_airport.html')



if __name__ == '__main__':
	app.run(port=8000, debug=True)
    