# Do this first:
1) You need flask and mysqlclient (pip install Flask, pip install mysqlclient)
2) Clone this, grab the most up to date version of cs4400_phase3_stored_procedures_team133 from the other repo!
3) Put your root password for mysql in password.txt.
    - This is set to be read by app.py
    - This avoids needing to change passwords
    - The file is in the .gitignore, so it shouldn't be added
4) Create a file `password.txt` in the same folder as `app.py`. The only text in this file should be your mysql password
5) Run `python app.py` and go to the port it indicates on the browser (should be 8000)

Do this to resolve issues with `pip install mysqlclient`:
https://pypi.org/project/mysqlclient/
