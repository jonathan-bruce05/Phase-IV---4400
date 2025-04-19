-- CS4400: Introduction to Database Systems: Monday, March 3, 2025
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like the model and the engine.  
Finally, an airplane must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (in ip_airlineID varchar(50), in ip_tail_num varchar(50),
	in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_plane_type varchar(100), in ip_maintenanced boolean, in ip_model varchar(50),
    in ip_neo boolean)
sp_main: begin

	-- Ensure that the plane type is valid: Boeing, Airbus, or neither
    # Change != to is not for null comparison and order of check to prevent null triggering error for not in.
    # i.e if not null, must be boeing or airbus, if not leave sp_main
    if ip_plane_type is not null and ip_plane_type not in ('Boeing', 'Airbus') then
		select 'Plane type not valid' as error_message;
		leave sp_main;
	end if;
    
    -- Ensure that the type-specific attributes are accurate for the type
    # changed NULL comparisons fron = and != to is or is not
    # boeing must be have maintenanced T/F and ip_model valid
    if ip_plane_type = 'Boeing' and (ip_maintenanced is NULL or ip_model is NULL or ip_neo is not NULL) then
		select 'Attributes wrong for Boeing plane' as error_message;
        leave sp_main;
	end if;
    
    # airbus must be T/F neo, so if maintenanced or model not NULL or neo is NULL, reject
    if ip_plane_type = 'Airbus' and (ip_maintenanced is not NULL or ip_model is not NULL or ip_neo is NULL) then
		select 'Attributes wrong for Airbus' as error_message;
        leave sp_main;
	end if;
        
	# if you are neither, all of your type-specifics should be null
	if ip_plane_type = NULL and (ip_maintenanced is not NULL or ip_model is not NULL or ip_neo is not NULL) then
		select 'Attributes wrong for general plane' as error_message;
        leave sp_main;
    end if;
    
    -- Ensure that the airplane and location values are new and unique
    # checking airline exists
    if (select count(*) from airline where airlineID = ip_airlineID) < 1 then
		select 'invalid airline ID' as error_message;
		leave sp_main;
	end if;
    # check tail num doesn't already exist
    # changed tail number check to be within airline, not for all planes.
    if (select count(*) from airplane where tail_num = ip_tail_num and airlineID = ip_airlineID) > 0 then
		select 'invalid tailnum' as error_message;
		leave sp_main;
	end if;
	# check location doesn't exist
    if (select count(*) from location where locationID = ip_locationID) > 0 then
		select 'location already exists' as error_message;
		leave sp_main;
	end if;
    
    # checking that speed and seat capacity are non zero (>0)
    if ip_speed < 1 or ip_seat_capacity < 1 then
		select 'You need speed and seat capacities greater than 0.' as error_message;
		leave sp_main;
	end if;
    
    
    -- Add airplane and location into respective tables
    # if you have made it past the above, you are a valid airplane. Congrats!
    insert into location (locationID) values (ip_locationID);
    insert into airplane (airlineID, tail_num, seat_capacity, speed, locationID, plane_type, maintenanced, model, neo ) 
		values (ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID, ip_plane_type, ip_maintenanced, ip_model, ip_neo);

end //
delimiter ;

-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport.  A new airport must have a unique
identifier along with a new and database-wide unique location if it will be used
to support airplane takeoffs and landings.  An airport may have a longer, more
descriptive name.  An airport must also have a city, state, and country designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (in ip_airportID char(3), in ip_airport_name varchar(200),
    in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50))
sp_main: begin

	-- Ensure that the airport and location values are new and unique
    # the part about may in airport name makes me thing it doesn't need to be filled in necessarily, so I won't put a check here for that.
    # ^^^ I think the "may" should probably still check that the other parameters are filled, so I placed in a check to ensure not null except for the airport_name param.
    # also moved check up to prevent errors in null comparisons in selection statements below this.
    if ip_airportID is null or ip_locationID is null or ip_city is null or ip_state is null or ip_country is null then
		select 'airportID, locationID, city, state, or country is NULL' as error_message;
        leave sp_main;
    end if;
    
    if (select count(*) from location where locationID = ip_locationID) > 0 then
		select 'locationID already exists' as error_message;
		leave sp_main;
	end if;
    
    if (select count(*) from airport where airportID = ip_airportID) > 0 then
		select 'airport already exists with that ID' as error_message;
		leave sp_main;
	end if;
    
    -- Add airport and location into respective tables
	insert into location (locationID) values (ip_locationID);
    insert into airport (airportID, airport_name, city, state, country, locationID) 
		values (ip_airportID, ip_airport_name, ip_city, ip_state, ip_country, ip_locationID);
	
end //
delimiter ;

-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time.  A person must have a first name, and might also have a last name.

A person can hold a pilot role or a passenger role (exclusively).  As a pilot,
a person must have a tax identifier to receive pay, and an experience level.  As a
passenger, a person will have some amount of frequent flyer miles, along with a
certain amount of funds needed to purchase tickets for flights. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main: begin

	# Variable to see if passenger = 1 or pilot = 0
    declare person_type integer;
    
    # See if input first name is null, personID, or locationID as well. Last name does not matter
    if ip_personID is null 
		or ip_first_name is null 
		or ip_locationID is null then
        select 'Invalid input NULL first_name, personID, or locationID' as error_message;
		leave sp_main;
    end if;

	-- Ensure that the location is valid
    if ((select count(*) from location where locationID = ip_locationID) < 1) then
		select 'Invalid input location' as error_message;
		leave sp_main;
    end if;
    -- Ensure that the persion ID is unique
	if ((select count(*) from person where personID = ip_personID) > 0) then
		select 'Invalid input personID not unique' as error_message;
		leave sp_main;
    end if;
    -- Ensure that the person is a pilot or passenger
    # Checks if person is passenger
    if (ip_taxID is not null and ip_experience is not null 
        and ip_miles is null and ip_funds is null) then
         set person_type = 0;
    elseif (ip_taxID is null and ip_experience is null 
            and ip_miles is not null and ip_funds is not null) then
         set person_type = 1;
    else
    -- not satisfy either role
		select 'Invalid input person is not pilot or passenger' as error_message;
		leave sp_main;
    end if;
    
    -- Insert into person table
    insert into person (personID, first_name, last_name, locationID)
         values (ip_personID, ip_first_name, ip_last_name, ip_locationID);

    -- Insert into appropriate table
    if person_type = 0 then
         insert into pilot (personID, taxID, experience)
             values (ip_personID, ip_taxID, ip_experience);
    else
         insert into passenger (personID, miles, funds)
             values (ip_personID, ip_miles, ip_funds);
    end if;

end //
delimiter ;

-- [4] grant_or_revoke_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a pilot license.  If the license
doesn't exist, it must be created; and, if it aready exists, then it must be removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists grant_or_revoke_pilot_license;
delimiter //
create procedure grant_or_revoke_pilot_license (in ip_personID varchar(50), in ip_license varchar(100))
sp_main: begin
	-- added control to ensure that liscense holder exists thus liscense exists.
    -- prevents null comparisons in invert portion
    if ip_personID is null or ip_license is null then
        leave sp_main;
    end if;
	
	-- Ensure that the person is a valid pilot
    if ((select count(*) from pilot where personID = ip_personID) < 1) then
        leave sp_main;
    end if;
    -- If license exists, delete it, otherwise add the license
    if (select count(*) from pilot_licenses where personID = ip_personID and license = ip_license) > 0 then
		#delete if it exists
        delete from pilot_licenses where personID = ip_personID and license = ip_license;
	else 
		#add it
        insert into pilot_licenses (personID, license) values (ip_personID, ip_license);
	end if;

end //
delimiter ;

-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  And
the airplane, if designated, must not be in use by another flight.  The flight
can be started at any valid location along the route except for the final stop,
and it will begin on the ground.  You must also include when the flight will
takeoff along with its cost. */
-- -----------------------------------------------------------------------------
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight (in ip_flightID varchar(50), in ip_routeID varchar(50),
    in ip_support_airline varchar(50), in ip_support_tail varchar(50), in ip_progress integer,
    in ip_next_time time, in ip_cost integer)
sp_main: begin
	
    #check flightID for uniqueness and not null
    if (select count(*) from flight where flightID = ip_flightID) > 0 or ip_flightID is null then
		leave sp_main;
	end if;
    
    -- added verify flight existence before comparison
    if (select count(*) from route where routeID = ip_routeID) < 1 then
		leave sp_main;
	end if;
    
    -- added check requiring flight starting at any valid location except final stop.
    if ip_progress != 0 and ip_progress = (select max(sequence) from route_path where routeID = ip_routeID) then
		leave sp_main;
	end if;
    
	if ip_support_airline is not NULL or ip_support_tail is not NULL then
    #if one is given, the other must be given
		if ip_support_airline is NULL or ip_support_tail is NULL then
			#select ('airline or tail is NULL');
			leave sp_main;
		end if;
        #additionally, we want to make sure this plane is not in use by a different flight
        if (select count(*) from flight where support_airline = ip_support_airline and support_tail = ip_support_tail) > 0 then
			#select ('plane is in use by another flight');
			leave sp_main; #in use already
		end if;
	end if;
    
	#make sure progress is valid (either 0 or one of the legs)
    if (ip_progress is NULL or (ip_progress not in (select sequence from route_path where routeID = ip_routeID) and ip_progress != 0) ) then
		#select ('progress is invalid');
		leave sp_main;
	end if;
    
    #make sure cost is valid
    if (ip_cost < 0 or ip_cost is NULL) then
		#select ('cost is invalid');
		leave sp_main;
	end if;
    
    #make sure time is not NULL
    if (ip_next_time is NULL) then
		#select ('time is null');
		leave sp_main;
	end if;
    
    #if all of the above is good, then we can add it. All planes begin on ground
    insert into flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time, cost) values
		(ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, 'on_ground', ip_next_time, ip_cost);
end //
delimiter ;

-- [6] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route.  The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel.  Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin
	
    -- variables
    declare v_flightExists boolean;
    declare v_flightStatus varchar(100);
    declare v_routeID varchar(50);
    declare v_progress int;
    declare v_airlineID varchar(50);
    declare v_tail_num varchar(50);
    declare v_current_leg varchar(50);
    declare v_distance int;
    declare v_airportID char(3);
    declare v_next_time time;
    
	-- Ensure that the flight exists
    select count(*) > 0 into v_flightExists from flight where flightID = ip_flightID;
    if not v_flightExists then
		leave sp_main;
	end if;
    -- Ensure that the flight is in the air
    select airplane_status into v_flightStatus from flight where flightID = ip_flightID;
    if v_flightStatus <> 'in_flight' then
		leave sp_main;
	end if;
    -- Increment the pilot's experience by 1
    update pilot set experience = experience + 1 where commanding_flight = ip_flightID;
    -- Increment the frequent flyer miles of all passengers on the plane
    select routeID, progress, support_airline, support_tail
    into v_routeID, v_progress, v_airlineID, v_tail_num
    from flight where flightID = ip_flightID;
    
    select l.legID, l.distance, l.arrival
    into v_current_leg, v_distance, v_airportID from route_path rp 
    join leg l on rp.legId = l.legID 
    where rp.routeID = v_routeID and rp.sequence = v_progress;
    
    update passenger p 
    join person pr on p.personID = pr.personID
    join airplane a on pr.locationID = a.locationID
    join flight f on a.airlineID = f.support_airline and a.tail_num = f.support_tail
    set p.miles = p.miles + v_distance
    where f.flightID = ip_flightID;
    -- Update the status of the flight and increment the next time to 1 hour later
		-- Hint: use addtime()
        set v_next_time = (select next_time from flight where flightID = ip_flightID);
        
        update flight
        set airplane_status = 'on_ground',
        next_time = addtime(v_next_time, '01:00:00')
        where flightID = ip_flightID;
end //
delimiter ;

-- [7] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that Airbus and general planes have at least one pilot
assigned, while Boeing must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff (in ip_flightID varchar(50))
sp_main: begin

	-- variables
	declare v_flightExists boolean;
    declare v_flightStatus varchar(100);
    declare v_routeID varchar(50);
    declare v_progress int;
    declare v_leg_count int;
    declare v_airlineID varchar(50);
    declare v_tail_num varchar(50);
    declare v_plane_type varchar(40);
    declare v_pilot_count int;
    declare v_airplane_speed int;
    declare v_distance int;
    declare v_flight_time int;

	-- Ensure that the flight exists
	select count(*) > 0 into v_flightExists from flight where flightID = ip_flightID;
    if not v_flightExists then
		leave sp_main;
	end if;
    -- Ensure that the flight is on the ground
    select airplane_status into v_flightStatus from flight where flightID = ip_flightID;
    if v_flightStatus <> 'on_ground' then
		leave sp_main;
	end if;
    -- Ensure that the flight has another leg to fly
    select routeID, progress, support_airline, support_tail
    into v_routeID, v_progress, v_airlineID, v_tail_num
    from flight where flightID = ip_flightID;
    
    select count(*) into v_leg_count
    from route_path where routeID = v_routeID;
    
    if v_progress >= v_leg_count then
		leave sp_main;
	end if;
    -- Ensure that there are enough pilots (1 for Airbus and general, 2 for Boeing)
		-- If there are not enough, move next time to 30 minutes later
	select plane_type into v_plane_type from airplane
    where airlineID = v_airlineID and tail_num = v_tail_num;
    
    select count(*) into v_pilot_count from pilot
    where commanding_flight = ip_flightID;
    
	if (v_plane_type = 'Boeing' and v_pilot_count < 2) OR (v_pilot_count < 1) then
		update flight set next_time = addtime(next_time, '00:30:00')
		where flightID = ip_flightID;
		leave sp_main;
	end if;
    -- Calculate the speed of airplane
    select speed into v_airplane_speed from airplane
    where airlineID = v_airlineID and tail_num = v_tail_num;
    -- distance of next leg
    select l.distance into v_distance
    from route_path rp
    join leg l on rp.legID = l.legID
    where rp.routeID = v_routeID and rp.sequence = v_progress + 1;
    -- calculate the time based on distance and speed, using sec_to_time b/c maketime doesnt handle fractions well
    set v_flight_time = sec_to_time(3600 * v_distance / v_airplane_speed);
    
    -- Update the next time, status, and progress
	update flight
    set airplane_status = 'in_flight',
	progress = progress + 1,
	next_time = addtime(next_time, v_flight_time)
    where flightID = ip_flightID;
end //
delimiter ;

-- [8] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the same airport as the flight,
and the flight must be heading towards that passenger's desired destination.
Also, each passenger must have enough funds to cover the flight.  Finally, there
must be enough seats to accommodate all boarding passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board (in ip_flightID varchar(50))
sp_main: begin


# TODO: FIX THIS PROCEDURE. CURRENTLY 5/10 ON AUTOGRADER
	declare curr_leg int;
	declare curr_airport varchar(3);
    declare next_airport varchar(3);
    declare flight_cost int;
    declare plane_capacity int;
    declare open_seats int;
    declare passID varchar(50);
    declare want_board int;


	-- Ensure the flight exists
    if (select count(*) from flight where flightID = ip_flightID) < 1 then
		#select ('flight does not exist');
        leave sp_main;
	end if;
    -- Ensure that the flight is on the ground
    if (select airplane_status from flight where flightID = ip_flightID) != 'on_ground' then
		#select ('flight is not on ground');
        leave sp_main;
	end if;
    -- Ensure that the flight has further legs to be flown
    #if curr_progress >= length, then flight has no further legs
    if (select progress from flight where flightID = ip_flightID) >= (select count(*) from flight f join route_path r on f.routeID = r.routeID where f.flightID = ip_flightID) then
		#select ('flight has no further legs');
        leave sp_main;
	end if;
    
    set curr_leg = (select progress from flight where flightID = ip_flightID);
    #special fix for first step of route since progress is 0 but first leg is 1
    if (curr_leg = 0) then
		set curr_leg = 1;
	end if;
    
    #set up airport vars
    set curr_airport = (select l.departure from leg l join route_path r on l.legID = r.legID join flight f on r.routeID=f.routeID and r.sequence = curr_leg
		where flightID = ip_flightID);
        
	set next_airport = (select l.arrival from leg l join route_path r on l.legID = r.legID join flight f on r.routeID=f.routeID and r.sequence = curr_leg
		where flightID = ip_flightID);
	
    set flight_cost = (select cost from flight where flightID = ip_flightID);
    

    
    -- Determine the number of passengers attempting to board the flight
    -- Use the following to check:
		-- The airport the airplane is currently located at
			#curr_airport
        -- The passengers are located at that airport
        -- The passenger's immediate next destination matches that of the flight
        -- The passenger has enough funds to afford the flight
        
    #I had views here, apparently they haven't have variables though...sooo    
    /*
	select p.personID
	from passenger p
	join airport a on p.locationID = a.locationID
	join passenger_vacations v on p.personID = v.personID
	where a.airportID = curr_airport
		and v.airportID = next_airport
		and p.funds >= flight_cost;
	*/
    
	-- Check if there enough seats for all the passengers
		#D: we have to check who is already on the plane, but we know if someone is already on then they're -1 from the capacity
		-- If not, do not add board any passengers
        -- If there are, board them and deduct their funds
        
	set plane_capacity = (select seat_capacity from flight join airplane on (support_airline, support_tail) = (airlineID, tail_num) where flightID = ip_flightID);
	
    #capacity - (everyone whose current location is the airplane (so their locationID matches the airplane's locationID?)
    set open_seats = plane_capacity - (select count(*) from person p join airplane a on p.locationID = a.locationID join flight f on (airlineID, tail_num) = (support_airline, support_tail) where flightID = ip_flightID);
    
    set want_board = (select count(*) from (select p.personID
								from passenger p
                                join person on person.personID = p.personID
								join airport a on person.locationID = a.locationID
								join passenger_vacations v on p.personID = v.personID
								where a.airportID = curr_airport
									and v.airportID = next_airport
									and p.funds >= flight_cost) as subquery);
	if want_board
			> open_seats then
		#select ('Plane does not have enough seats');
        leave sp_main;
	end if;
	
    update passenger p
	join (
		select p.personid
		from passenger p
		join person pr on pr.personid = p.personid
		join airport a on pr.locationid = a.locationid
		join passenger_vacations v on p.personid = v.personid
		where a.airportid = curr_airport
		  and v.airportid = next_airport
		  and p.funds >= flight_cost
	) as subquery on p.personid = subquery.personid
	set p.funds = p.funds - flight_cost;


                                                                                                    
    update person pr
	join (
		select p.personid
		from passenger p
		join person pr2 on pr2.personid = p.personid
		join airport a on pr2.locationid = a.locationid
		join passenger_vacations v on p.personid = v.personid
		where a.airportid = curr_airport
		  and v.airportid = next_airport
		  and p.funds >= flight_cost
	) as subquery on pr.personid = subquery.personid
	set pr.locationid = (
		select locationid
		from airplane
		join flight on (airlineid, tail_num) = (support_airline, support_tail)
		where flightid = ip_flightid
	);

	#select ('updated passengers');
end //
delimiter ;

-- [9] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport.  The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin

	declare curr_leg int;
    declare curr_airport varchar(3);
    declare airport_loc varchar(50);

	-- Ensure the flight exists
    -- Ensure that the flight is in the air (NOTE: ED SAYS TO MAKE THIS ON GROUND)
    
    if (select count(*) from flight where flightID = ip_flightID) < 1 then
		#select ('flight does not exist');
        leave sp_main;
	end if;
    if (select airplane_status from flight where flightID = ip_flightID) != 'on_ground' then
		#select ('flight is not on ground');
        leave sp_main;
	end if;
    
    set curr_leg = (select progress from flight where flightID = ip_flightID);
    #special fix for first step of route since progress is 0 but first leg is 1
    if (curr_leg = 0) then
		set curr_leg = 1;
	end if;
    
    #set up airport vars
    set curr_airport = (select l.arrival from leg l join route_path r on l.legID = r.legID join flight f on r.routeID=f.routeID and r.sequence = curr_leg
		where flightID = ip_flightID);
    
    #I think this part will be pretty similar to what I did above.
    
    -- Determine the list of passengers who are disembarking
	-- Use the following to check:
		-- Passengers must be on the plane supporting the flight
        -- Passenger has reached their immediate next destionation airport
        /*
        select pass.personID
			from passenger pass
			join passenger_vacations v on pass.personID = v.personID
			join person p on pass.personID = p.personID
			join airplane a on p.locationID = a.locationID
			join flight f on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
			where v.sequence = 1
			and v.airportID = curr_airport
			and f.flightID = ip_flightID;

		*/
        
	    set airport_loc = (select locationID from airport where airportID=curr_airport);
	-- Move the appropriate passengers to the airport
	-- Update the vacation plans of the passengers
    
    drop table if exists vacations;
    create temporary table vacations select * from passenger_vacations;
    
    #first, we delete their vacation intent.
	delete from passenger_vacations where sequence = 1 and personID in (select pass.personID
			from passenger pass
			join person p on pass.personID = p.personID
            join vacations v on v.personID=pass.personID
			join airplane a on p.locationID = a.locationID
			join flight f on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
            where f.flightID = ip_flightID
            and v.airportID=curr_airport);
	#next, we update the passenger's other intents to fix the sequence
    update passenger_vacations set sequence = sequence - 1 where personID in (select pass.personID
			from passenger pass
			join person p on pass.personID = p.personID
            join vacations v on v.personID=pass.personID
			join airplane a on p.locationID = a.locationID
			join flight f on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
			where f.flightID = ip_flightID
            and v.airportID = curr_airport);
	#lastly, they can leave the plane
    update person p
	join (
		select pass.personID
			from passenger pass
			join person p on pass.personID = p.personID
            join vacations v on v.personID=pass.personID
			join airplane a on p.locationID = a.locationID
			join flight f on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
			where f.flightID = ip_flightID
            and v.airportID = curr_airport
	) subquery on p.personID = subquery.personID
	set p.locationID = airport_loc;



end //
delimiter ;

-- [10] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
flight.  The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight.  Also, a pilot can only support
one flight (i.e. one airplane) at a time.  The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), ip_personID varchar(50))
sp_main: begin


	-- variable declarations for:
		--  flight data:
		declare v_routeID varchar(50);
		declare v_support_airline varchar(50);
		declare v_support_tail varchar(50);
		declare v_flightStatus varchar(100);
		declare v_progress int;
		declare v_totalLegs int;

		-- airplane data:
		declare v_airplaneType varchar(100);
    	declare v_airplaneLocation varchar(50);
		declare v_currentLegID varchar(50);
		declare v_depart_airport varchar(3);
		declare v_depart_locationID varchar(50);

		-- pilot data:
		declare v_personLocation varchar(50);
		declare v_commanding_flight varchar(50);
		declare v_licenseCount int;
        
        declare plane_capacity int;
        declare open_seats int;



	-- Ensure the flight exists
	select routeID, support_airline, support_tail, airplane_status, progress
		into v_routeID, 
			v_support_airline, 
			v_support_tail, 
			v_flightStatus, 
			v_progress
		from flight
		where flightID = ip_flightID;

    if (ip_flightID is null) then
        leave sp_main; #flight doesn't exist
    end if;
    
    if (select count(*) from flight where flightID = ip_flightID) < 1 then
		leave sp_main;
	end if;

    -- Ensure the flight is grounded
	if (v_flightStatus <> 'on_ground') then
        leave sp_main; #flight not on ground
    end if;

    -- Ensure that the flight has further legs to be flown
    select count(*) into v_totalLegs 
    	from route_path 
    	where routeID = v_routeID;
    if (v_progress >= v_totalLegs) then
        leave sp_main; #no further legs
    end if;

	-- Get Airplane data
	select plane_type, locationID 
    	into v_airplaneType, v_airplaneLocation
    	from airplane
    	where airlineID = v_support_airline and tail_num = v_support_tail;
    
    if (v_airplaneType is null) then
        leave sp_main; #airplane doesn't exist
    end if;

-- Ensure that the pilot exists and is not already assigned

    set plane_capacity = 
		(select seat_capacity from flight 
        join airplane on (support_airline, support_tail) = (airlineID, tail_num) 
        where flightID = ip_flightID);
	
    #capacity - (everyone whose current location is the airplane (so their locationID matches the airplane's locationID?)
    set open_seats = 
		plane_capacity - 
        (select count(*) from person p 
			join airplane a on p.locationID = a.locationID 
			join flight f on (airlineID, tail_num) = (support_airline, support_tail) 
            where flightID = ip_flightID);
	
    if open_seats < 1 then
		leave sp_main;
	end if;

	-- Ensure pilot exists and not already assigned
	select commanding_flight into v_commanding_flight
    	from pilot
    	where personID = ip_personID;

    if (v_commanding_flight is not null) then
        leave sp_main; #pilot on a flight already
    end if;

-- Ensure the pilot is located at the airport of the plane that is supporting the flight
	-- Ensure pilot location plane by setting pilot location to airplane location

	-- pilot's location
	select locationID into v_personLocation
		from person
		where personID = ip_personID;

	-- get current leg ID 
	select legID into v_currentLegID
		from route_path
		where routeID = v_routeID and sequence = v_progress + 1;

	-- get departure airport for leg
	select departure into v_depart_airport
		from leg
		where legID = v_currentLegID;

	-- get location of departure airport
	select locationID into v_depart_locationID
		from airport
		where airportID = v_depart_airport;

	if (v_personLocation <> v_depart_locationID) then
		leave sp_main; #pilot not at departure airport
	end if;

-- Ensure that the pilot has the appropriate license
	-- Ensure pilot liscense matches assigned plane
	select count(*) into v_licenseCount
    	from pilot_licenses
    	where personID = ip_personID and license = v_airplaneType;

    if (v_licenseCount = 0) then
        leave sp_main; #pilot missing license
    end if;

-- Assign the pilot to the flight and update their location to be on the plane
	-- If all checks, assign pilot to flight
	update pilot
		set commanding_flight = ip_flightID
		where personID = ip_personID;

	update person
		set locationID = v_airplaneLocation
		where personID = ip_personID;

end //
delimiter ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin

	-- Variable declarations for flight info
    declare v_routeID varchar(50);
    declare v_support_airline varchar(50);
    declare v_support_tail varchar(50);
    declare v_flightStatus varchar(100);
    declare v_progress int;
    declare v_totalLegs int;
    
    
    -- Variables for airplane and passenger checks
    declare v_airplaneLocation varchar(50);
    declare v_passengerCount int;
    
    -- Variables for final destination location
    declare v_finalLegID varchar(50);
    declare v_arrival_airport char(3);
    declare v_finalAirportLocation varchar(50);


	-- get flight info:
	select routeID, support_airline, support_tail, airplane_status, progress
		into v_routeID, 
			v_support_airline, 
			v_support_tail, 
			v_flightStatus, 
			v_progress
		from flight
		where flightID = ip_flightID;
        
	

	if (ip_flightID is null) then
		leave sp_main; #flight doesn't exist
	end if;
    
    if (select count(*) from flight where flightID = ip_flightID) < 1 then
		leave sp_main;
	end if;

    -- Ensure that the flight does not have any more legs
	select count(*) into v_totalLegs
		from route_path 
		where routeID = v_routeID;
	
	if (v_progress < v_totalLegs) then
		leave sp_main; #flight not ended
	end if;

	-- Ensure that the flight is on the ground
	if (v_flightStatus <> 'on_ground') then
		leave sp_main; #flight not on ground
	end if;

	-- get flight current location
	select locationID into v_airplaneLocation
		from airplane
		where airlineID = v_support_airline and tail_num = v_support_tail;

		if (v_airplaneLocation is null) then
			leave sp_main; #airplane location not found
		end if;

	-- get final airport location

		-- get final leg
		select legID into v_finalLegID
			from route_path
			where routeID = v_routeID and sequence = v_totalLegs;
		
		-- get final leg arrival airport code
		select arrival into v_arrival_airport
			from leg
			where legID = v_finalLegID;
		
		-- finally get locID of arrival airport
		select locationID into v_finalAirportLocation
			from airport
			where airportID = v_arrival_airport;
	

    
    -- Ensure that the flight is empty of passengers
    select count(*) into v_passengerCount
    	from passenger pa
    	join person p on pa.personID = p.personID
    	where p.locationID = v_airplaneLocation;
	if (v_passengerCount > 0) then
	    leave sp_main; #flight not empty of passengers
	end if;

	-- Move all pilots to the airport the plane of the flight is located at
	update person p
    	set p.locationID = v_finalAirportLocation
		where p.personID in (select personID from pilot where commanding_flight = ip_flightID);

    -- Update assignements of all pilots
	update pilot
		set commanding_flight = null
		where commanding_flight = ip_flightID;

    

	#select v_routeID, v_support_airline, v_support_tail, v_flightStatus, v_progress, v_totalLegs,
	#		v_airplaneLocation, v_passengerCount, v_finalLegID, v_arrival_airport, v_finalAirportLocation;

end //
delimiter ;

-- [12] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  And the flight must be empty - no pilots or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin

	-- variables
	declare v_flightStatus varchar(100);
    declare v_flightProgress int;
    declare v_route_leg_count int;
    declare v_planeLocation varchar(50);
    declare v_people_on_plane int;
    declare v_airportLocation varchar(50);
    declare v_progressAdj int;


	# null check
    if (select count(*) from flight where flightID = ip_flightID) < 1 then
		leave sp_main; #flightID invalid or NULL
	end if;


	-- Ensure that the flight is on the ground
    select airplane_status into v_flightStatus from flight where flightID = ip_flightID;
    
    if (v_flightStatus <> 'on_ground') then
		#select 'flight is not on the ground';
        leave sp_main;
	end if;
    -- Ensure that the flight does not have any more legs
    select progress, (select count(*) from route_path where routeID = flight.routeID)
    into v_flightProgress, v_route_leg_count from flight where flightID = ip_flightID;
    
    if v_flightProgress < v_route_leg_count then
		#select 'still in progress or has more legs';
        leave sp_main;
	end if;
    
    -- Ensure that there are no more people on the plane supporting the flight
    select a.locationID into v_planeLocation from flight f 
    join airplane a on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
    where f.flightID = ip_flightID;
    
    select count(*) into v_people_on_plane from person where locationID = v_planeLocation;
    if v_people_on_plane > 0 then
		# select 'Plane is not empty';
        leave sp_main;
	end if;
    
    -- Ensure flight is either at start or end of its route
    select a.locationID into v_airportLocation from route_path rp 
    join leg l on rp.legID = l.legID
    join airport a on l.departure = a.airportID
    where rp.routeID = (select routeID from flight where flightID = ip_flightID)
    and rp.sequence = 1;
    
    if (select progress from flight where flight.flightID=ip_flightID) = 0 then
		set v_progressAdj = 1;
			select a.locationID into v_planeLocation from flight f 
			join route_path p on f.routeID=p.routeID
			join leg l on l.legID=p.legID
			join airport a on a.airportID=l.departure
			where p.sequence=f.progress+v_progressAdj
			and f.flightID=ip_flightID;
	else
		set v_progressAdj = 0;
        select a.locationID into v_planeLocation from flight f 
			join route_path p on f.routeID=p.routeID
			join leg l on l.legID=p.legID
			join airport a on a.airportID=l.arrival
			where p.sequence=f.progress+v_progressAdj
			and f.flightID=ip_flightID;
	end if;
    
    
    
    if v_planeLocation <> v_airportLocation then
		select a.locationID into v_airportLocation from route_path rp 
		join leg l on rp.legID = l.legID
		join airport a on l.arrival = a.airportID
		where rp.routeID = (select routeID from flight where flightID = ip_flightID)
		and rp.sequence = (select count(*) from route_path 
			where routeID = (select routeID from flight where flightID = ip_flightID));
		
        if v_planeLocation <> v_airportLocation then
			# select 'plane is not at start or end of its route';
            leave sp_main;
		end if;
	end if;
    
    -- Remove the flight from the system
    update flight 
    set support_airline = NULL,
	support_tail = NULL 
    where flightID = ip_flightID;
    
    delete from flight where flightID = ip_flightID;
end //
delimiter ;


-- [13] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin
	-- variables
	declare next_flight varchar(50);
    declare currStatus varchar(50);
    declare currProgress int;
    declare endSequence int;


	-- Identify the next flight to be processed
    create or replace view candidates as
    select flightID, airplane_status from flight f 
		where next_time = (select min(next_time) from flight)
        order by flightID asc;
    if (select count(*) from candidates where airplane_status = 'in_flight') > 0 then
		set next_flight = (select flightID from candidates where airplane_status = 'in_flight' order by flightID asc limit 1);
	else
		set next_flight = (select flightID from candidates order by flightID asc limit 1);
	end if;
    
    set currStatus = (select airplane_status from flight where flightID=next_flight);
    
    set currProgress = (select progress from flight where flightID=next_flight);
    set endSequence = (select max(sequence) from route_path p
		join flight f on p.routeID=f.routeID where f.flightID=next_flight);
    
    
    -- If the flight is in the air:
		-- Land the flight and disembark passengers
        -- If it has reached the end:
			-- Recycle crew and retire flight
	if (currStatus = 'in_flight') then
		call flight_landing(next_flight);
        call passengers_disembark(next_flight);
        if (currProgress = endSequence) then
			call recycle_crew(next_flight);
            call retire_flight(next_flight);
		end if;
	end if;
        
	-- If the flight is on the ground:
		-- Board passengers and have the plane takeoff
    if (currStatus = 'on_ground') then
		if (currProgress = endSequence) then
			call recycle_crew(next_flight);
            call retire_flight(next_flight);
		else
			call passengers_board(next_flight);
            call flight_takeoff(next_flight);
		end if;
	end if;
	-- Hint: use the previously created procedures

end //
delimiter ;

-- [14] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located. 
We need to display what airports these flights are departing from, what airports 
they are arriving at, the number of flights that are flying between the 
departure and arrival airport, the list of those flights (ordered by their 
flight IDs), the earliest and latest arrival times for the destinations and the 
list of planes (by their respective flight IDs) flying these flights. */
-- -----------------------------------------------------------------------------

#I'm thinking these could definitely be condensed all into 1 big view, I just could not get it to work when I did that
#so it's 2 views for now, probably something to do with the count(*)/min/max in the 2nd one
create or replace view air_airport_data as
select departing.airportID as departing_from, arriving.airportID as arriving_at, a.locationID as airplane_IDs, f.flightID as flight_IDs from flight f
	join airport as departing #join to get airport
	join airport as arriving #repeat for the other col
	join airplane a on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
    where f.airplane_status = 'in_flight'
    #since the flight is in air, we can ignore the 0 progress case
    and f.routeID in 
		(select routeID from route_path 
		where sequence = f.progress
		and legID in (select legID from leg where departure=departing.airportID))
	and f.routeID in
		(select routeID from route_path 
		where sequence = f.progress
		and legID in (select legID from leg where arrival=arriving.airportID));

create or replace view air_num_flights as
select departing.airportID as departing_from, arriving.airportID as arriving_at, count(*) as tot_num, min(next_time) as earliest, 
    max(next_time) as latest
	from flight f
	join airplane a on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
	join airport as departing #join to get airport
	join airport as arriving #repeat for the other col
    where f.airplane_status = 'in_flight'
    #since the flight is in air, we can ignore the 0 progress case
    and f.routeID in 
		(select routeID from route_path 
		where sequence = f.progress
		and legID in (select legID from leg where departure=departing.airportID))
	and f.routeID in
		(select routeID from route_path 
		where sequence = f.progress
		and legID in (select legID from leg where arrival=arriving.airportID))
	group by departing.airportID, arriving.airportID;

create or replace view flights_in_the_air (departing_from, arriving_at, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as
#select '_', '_', '_', '_', '_', '_', '_' from 
select air_airport_data.departing_from, air_airport_data.arriving_at, air_num_flights.tot_num, 
	group_concat(distinct air_airport_data.flight_IDs order by air_airport_data.flight_IDs) as flight_list, 
    air_num_flights.earliest, air_num_flights.latest, 
    group_concat(distinct air_airport_data.airplane_IDs order by air_airport_data.flight_IDs) as airplane_list
    from air_airport_data join air_num_flights 
    on air_airport_data.departing_from = air_num_flights.departing_from and air_airport_data.arriving_at = air_num_flights.arriving_at
    group by air_airport_data.departing_from, air_airport_data.arriving_at, air_num_flights.tot_num, air_num_flights.earliest, air_num_flights.latest;
    
-- [15] flights_on_the_ground()
-- ------------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are 
located. We need to display what airports these flights are departing from, how 
many flights are departing from each airport, the list of flights departing from 
each airport (ordered by their flight IDs), the earliest and latest arrival time 
amongst all of these flights at each airport, and the list of planes (by their 
respective flight IDs) that are departing from each airport.*/
-- ------------------------------------------------------------------------------

#select '_', '_', '_', '_', '_', '_';

#starting with flights_in_the_air. We need to handle the 0 progress case now but it should be mostly the same

#same situation as above, I'm sure these could be merged into 1 view but it isn't worth the time atm.
create or replace view ground_airport_data as 
select departing.airportID as departing_from, a.locationID as airplane_IDs, f.flightID as flight_IDs from flight f
	join airport as departing #join to get airport
	join airplane a on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
    where f.airplane_status = 'on_ground'
	#2 cases: progress = 0 -> sequence = 1 | progress != 0 -> sequence = progress
    and (f.routeID in (select routeID from route_path 
		where f.progress = 0
        and sequence = 1
        #departure because we are technically getting the "next" leg.
        and legID in (select legID from leg where departure=departing.airportID))
	or f.routeID in (select routeID from route_path 
		where f.progress != 0 
        and sequence = f.progress 
        #arrival because the progress hasn't updated yet
        and legID in (select legID from leg where arrival=departing.airportID)));
      
create or replace view ground_num_flights as
select departing.airportID as departing_from, count(*) as tot_num, min(next_time) as earliest, 
    max(next_time) as latest
	from flight f
	join airplane a on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
	join airport as departing #join to get airport
    where f.airplane_status = 'on_ground'
    #2 cases: progress = 0 -> sequence = 1 | progress != 0 -> sequence = progress
    and (f.routeID in (select routeID from route_path 
		where f.progress = 0
        and sequence = 1
        #departure because we are technically getting the "next" leg.
        and legID in (select legID from leg where departure=departing.airportID))
	or f.routeID in (select routeID from route_path 
		where f.progress != 0 
        and sequence = f.progress 
        #arrival because the progress hasn't updated yet
        and legID in (select legID from leg where arrival=departing.airportID)))
	group by departing.airportID;

#we need to group by here for some reason in order to use group_concat above
create or replace view flights_on_the_ground (departing_from, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as 
select ground_airport_data.departing_from, ground_num_flights.tot_num, 
	group_concat(distinct ground_airport_data.flight_IDs order by ground_airport_data.flight_IDs) as flight_list, 
    ground_num_flights.earliest, ground_num_flights.latest, 
    group_concat(distinct ground_airport_data.airplane_IDs order by ground_airport_data.flight_IDs) as airplane_list
    from ground_airport_data 
    join ground_num_flights on ground_airport_data.departing_from = ground_num_flights.departing_from
	group by ground_airport_data.departing_from, ground_num_flights.tot_num, ground_num_flights.earliest, ground_num_flights.latest;


-- [16] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. We 
need to display what airports these people are departing from, what airports 
they are arriving at, the list of planes (by the location id) flying these 
people, the list of flights these people are on (by flight ID), the earliest 
and latest arrival times of these people, the number of these people that are 
pilots, the number of these people that are passengers, the total number of 
people on the airplane, and the list of these people by their person id. */
-- -----------------------------------------------------------------------------



create or replace view all_people as
select p.personID,p.locationID, pass.personID as passID, pilot.personID as pilotID
	from person p 
    #left joins here so we put nulls for the opposite role
    left join passenger pass on pass.personID=p.personID
    left join pilot on pilot.personID=p.personID;

create or replace view airplane_data as
#airplane_list is really just locationIDs, it gets group concat'd later
select distinct locationID as airplane_list, 
		count(*) as num_airplanes, 
		min(next_time) as earliest_arrival, 
        max(next_time) as latest_arrival, 
        flightID from airplane a
	join flight f on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)
    where f.airplane_status = 'in_flight'
    group by f.flightID;

create or replace view people_count as
select p.locationID, flightID as flight_list, 
		count(passID) as num_passengers, 
        count(pilotID) as num_pilots, 
        count(distinct personID) as joint, 
        group_concat(personID) as person_list from all_people p
    join (select * from flight f join airplane a on (a.airlineID, a.tail_num) = (f.support_airline, f.support_tail)) d on p.locationID = d.locationID
    where airplane_status = 'in_flight'
    group by p.locationID, d.flightID;

#this is called destinations, but it's really also a collection of above data so I can join it a little easier below
create or replace view destinations as
select departure as departing_from, arrival as arriving_at, num_airplanes, airplane_list, earliest_arrival, latest_arrival 
from airplane_data d
	join flight on flight.flightID = d.flightID
	join route_path on route_path.routeID = flight.routeID
	join leg on leg.legID = route_path.legID 
	where route_path.sequence = flight.progress;
    

create or replace view people_in_the_air (departing_from, arriving_at, num_airplanes,
	airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
	num_passengers, joint_pilots_passengers, person_list) as
#select '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_';
select departing_from, arriving_at, sum(d.num_airplanes), group_concat(airplane_list order by airplane_list), 
		group_concat(flight_list order by flight_list), min(earliest_arrival), 
        max(latest_arrival), sum(num_pilots), sum(num_passengers), 
        sum(joint) as joint_pilots_passengers, group_concat(person_list order by person_list)
	from destinations d
    join people_count p on d.airplane_list=p.locationID
    group by departing_from, arriving_at;



-- [17] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground and in an 
airport are located. We need to display what airports these people are departing 
from by airport id, location id, and airport name, the city and state of these 
airports, the number of these people that are pilots, the number of these people 
that are passengers, the total number people at the airport, and the list of 
these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view all_people as
select p.personID,p.locationID, pass.personID as passID, pilot.personID as pilotID
	from person p 
    #left joins here so we put nulls for the opposite role
    left join passenger pass on pass.personID=p.personID
    left join pilot on pilot.personID=p.personID;
    
create or replace view people_location as
select locationID, count(passID) as num_passengers, count(pilotID) as num_pilots, count(distinct personID) as joint, group_concat(personID) as person_list
	from all_people
    group by locationID;
    
create or replace view people_on_the_ground (departing_from, airport, airport_name,
	city, state, country, num_pilots, num_passengers, joint_pilots_passengers, person_list) as
#select '_', '_', '_', '_', '_', '_', '_', '_', '_', '_
select a.airportID as departing_from, a.locationID as airport, 
		a.airport_name, 
        a.city, a.state, a.country,
        sum(p.num_pilots),
        sum(p.num_passengers),
        sum(p.joint) as joint_pilots_passengers,
        group_concat(p.person_list order by person_list)
        from people_location p
        join airport a on a.locationID=p.locationID
        where p.locationID not like 'plane%' #avoid planes on ground?
        group by airportID;

-- [18] route_summary()
-- -----------------------------------------------------------------------------
/* This view will give a summary of every route. This will include the routeID, 
the number of legs per route, the legs of the route in sequence, the total 
distance of the route, the number of flights on this route, the flightIDs of 
those flights by flight ID, and the sequence of airports visited by the route. */
-- -----------------------------------------------------------------------------

create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_flights, flight_list, airport_sequence) as
#select '_', '_', '_', '_', '_', '_', '_';
select p.routeID as route, count(distinct p.legID) as num_legs, 
					group_concat(distinct p.legID order by sequence) as leg_sequence,
                    #this sums the distance, then divides by the number of counted flightIDs to get the proper length
                    #otherwise, the length is sum(distance) * count(flightIDs)
                    #nullif is there just in case there are no flightIDs, I didn't want a div by 0.
                    round(sum(distance)/
							case when count(distinct flightID) = 0 
								then 1
							else count(distinct flightID)
							end) as route_length,
                    count(distinct flightID) as num_flights,
                    group_concat(distinct flightID) as flight_list,
                    group_concat(distinct concat(departure, '->', arrival) order by sequence) as airport_sequence
		from route_path p 
        join leg l on p.legID=l.legID
        left join flight f on f.routeID=p.routeID
        group by p.routeID;
        
-- [19] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. It should 
specify the city, state, the number of airports shared, and the lists of the 
airport codes and airport names that are shared both by airport ID. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports (city, state, country, num_airports,
	airport_code_list, airport_name_list) as
#select '_', '_', '_', '_', '_', '_';
select city, state, country, 
		count(*) as num_airports,
		group_concat(distinct airportID) as airport_code_list,
        group_concat(distinct airport_name order by airportID) as airport_name_list
	from airport
    group by city, state, country
    having count(*) > 1; #otherwise, we get every single airport (not just shared)
        
