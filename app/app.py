from flask import Flask, request, redirect, jsonify
import os
import psycopg2
import logging
import random
import string

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)
logger = logging.getLogger(__name__)

db_host= os.getenv("DB_HOST")
db_name= os.getenv("DB_NAME")
db_user= os.getenv("DB_USER")
db_password= os.getenv("DB_PASSWORD")
db_port= os.getenv("DB_PORT")

def get_db_connection():
    try:
        conn=psycopg2.connect(
            host= db_host,
            dbname= db_name,
            user= db_user,
            password= db_password,
            port= db_port
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection failed {e}")
        raise

@app.route("/version")
def version():
    return jsonify({'version': '2.0', 'deployment': 'CI/CD automated'}), 200

@app.route("/health")
def health():
    return jsonify({'status': 'healthy'}), 200

@app.route("/shorten", methods=["POST"])
def shorten():
    data = request.json
    long_url = data.get("url")
    
    if not long_url:
        logger.warning("No URL provided in request")
        return jsonify({"error": "URL is required"}), 400
    
    short_code = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO urls (short_code, long_url) VALUES (%s, %s)",
            (short_code, long_url)
        )
        conn.commit()
        cur.close()
        conn.close()
        logger.info(f"Short URL created: {short_code} -> {long_url}")
        return jsonify({"short_url": f"https://app.{os.getenv('DOMAIN_NAME')}/{short_code}"}), 201
    except Exception as e:
        logger.error(f"Failed to create short URL: {e}")
        return jsonify({"error": "Internal server error"}), 500
    
@app.route("/<short_code>", methods=["GET"])
def redirect_url(short_code):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT long_url FROM urls WHERE short_code = %s", (short_code,))
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        if result is None:
            logger.warning(f"Short code not found: {short_code}")
            return jsonify({"error": "Short URL not found"}), 404
        
        long_url = result[0]
        logger.info(f"Redirecting {short_code} -> {long_url}")
        return redirect(long_url)
    except Exception as e:
        logger.error(f"Redirect failed: {e}")
        return jsonify({"error": "Internal server error"}), 500

def create_table():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS urls (
            id SERIAL PRIMARY KEY,
            short_code VARCHAR(10) UNIQUE NOT NULL,
            long_url TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
        """)
        conn.commit()
        cur.close()
        conn.close()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        raise

if __name__ == '__main__':
    create_table()
    app.run(host='0.0.0.0', port=5000)