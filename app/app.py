from flask import Flask, render_template, request
import mysql.connector
import os
import socket

app = Flask(__name__)

# Adatbázis adatok az AWS-ből (majd az Ansible fogja beállítani)
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASS = os.environ.get('DB_PASS')
DB_NAME = os.environ.get('DB_NAME')

def get_db_connection():
    # Levágjuk a portot, ha benne van a környezeti változóban
    raw_host = os.environ.get('DB_HOST')
    host_only = raw_host.split(':')[0] if raw_host else None
    
    return mysql.connector.connect(
        host=host_only,
        port=3306,
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASS'),
        database=os.environ.get('DB_NAME')
    )
@app.route('/')
def index():
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT content FROM messages ORDER BY id DESC')
    messages = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return f"""
    <h1>Üdv a DevOps Appon!</h1>
    <p>Szerver IP: {local_ip}</p>
    <form action="/add" method="post">
        <input type="text" name="msg">
        <button type="submit">Küldés</button>
    </form>
    <h2>Üzenetek:</h2>
    <ul>
        {"".join([f"<li>{m[0]}</li>" for m in messages])}
    </ul>
    """

@app.route('/add', methods=['POST'])
def add():
    msg = request.form.get('msg')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('INSERT INTO messages (content) VALUES (%s)', (msg,))
    conn.commit()
    cursor.close()
    conn.close()
    return "Üzenet mentve! Menj vissza az előző oldalra."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)