from flask import Flask, jsonify
from flask_wtf.csrf import CSRFProtect

app = Flask(__name__)
csrf = CSRFProtect(app)


@app.get("/")
def home():
    return jsonify(message="SecureCloud PME - application en ligne")


@app.get("/health")
def health():
    return jsonify(status="ok")
