from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def home():
    return jsonify(message="SecureCloud PME - application en ligne")


@app.get("/health")
def health():
    return jsonify(status="ok")
