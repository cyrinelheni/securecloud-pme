import os

import psycopg
from flask import Flask, jsonify
from flask_wtf.csrf import CSRFProtect

app = Flask(__name__)
csrf = CSRFProtect(app)


@app.get("/")
def home():
    return jsonify(message="SecureCloud PME - application en ligne")


@app.get("/health")
def health():
    # Utilisee par l'ALB : ne depend pas de la base
    return jsonify(status="ok")


@app.get("/db")
def db_check():
    # Verifie la connexion a la base. Les identifiants viennent des
    # variables d'environnement, remplies par ECS depuis Secrets Manager.
    try:
        with psycopg.connect(
            host=os.environ["DB_HOST"],
            dbname=os.environ.get("DB_NAME", "securecloud"),
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            sslmode="require",  # connexion chiffree vers RDS
            connect_timeout=5,
        ) as conn:
            version = conn.execute("SHOW server_version").fetchone()[0]
        return jsonify(database="ok", postgresql=version)
    except (KeyError, psycopg.Error):
        app.logger.exception("Connexion a la base impossible")
        # Message generique : aucun detail technique n'est expose
        return jsonify(database="indisponible"), 503
