# Team 33 CS 4400 Phase 4

## Setup Instructions:
1) You need flask and mysqlclient (`pip install Flask`, `pip install mysqlclient`)
2) Clone this, grab the most up to date version of cs4400_phase3_stored_procedures_team133 from the other repo!
    - You need one that works for all given procedures
    - Error messages will not flash if a procedure exits early without error messages in the procedures
        - `select 'message' as error_message;`
3) Make sure the MySQL server is up and running with the flight_tracking database and procedures present.
4) Put your root password for mysql in `password.txt` (which you will need to create).
    - This is set to be read by app.py
    - This avoids needing to change passwords
    - The file is in the .gitignore, so it shouldn't be added
5) Create a file `password.txt` in the same folder as `app.py`. The only text in this file should be your mysql password
6) Run `python app.py` and go to the port it indicates on the browser (should be 8000)

### Do this to resolve issues with `pip install mysqlclient`:
- https://pypi.org/project/mysqlclient/

## Run Instructions:
1) For testing, navigate to the root of the repo and run `python3 app.py` after completing setup above
2) The server should run on localhost:8000

## Technologies
- Frontend: Basic HTML/CSS/JS
    - A lot of the general styling is in `base.html`, with more specific styling on a per-page basis.
- Backend: Python with Flask, using MySQLClient to connect to the database.
    - Each procedure essentially has it's own unique page that pulls base functionality/design from `base.html`
- The back end was pretty much written first with a no-styling frontend. Styling was added after to make it look nice with a few functional additions.

## Work Distribution
- All members of the group worked on testing of the application to ensure it worked as expected with the procedures.
- All members also worked on pieces of the backend, although Devan got a lot of the initial flask stuff set up and working.
- Jonathan handled most of the styling after the backend page templates were in place.