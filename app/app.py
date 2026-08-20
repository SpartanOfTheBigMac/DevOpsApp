"""
DevOps Pipeline Demo Application
---------------------------------
A minimal, interactive Flask "guestbook" used purely as a deployable artifact
to demonstrate a CI/CD pipeline. Functionality is intentionally simple:
visitors can submit a name + message and see all previous entries.

Endpoints:
  GET/POST /       -> guestbook form + list of entries
  GET      /health  -> health check used by the deploy pipeline / monitoring
"""

from flask import Flask, render_template, request, redirect
import sqlite3
import os

app = Flask(__name__)
DB_PATH = os.path.join(os.path.dirname(__file__), "guestbook.db")


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db()
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    conn.commit()
    conn.close()


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        name = (request.form.get("name") or "Anonymous").strip()[:50] or "Anonymous"
        message = (request.form.get("message") or "").strip()[:280]
        if message:
            conn = get_db()
            conn.execute(
                "INSERT INTO messages (name, message) VALUES (?, ?)",
                (name, message),
            )
            conn.commit()
            conn.close()
        return redirect("/")

    conn = get_db()
    rows = conn.execute(
        "SELECT name, message, created_at FROM messages ORDER BY id DESC LIMIT 50"
    ).fetchall()
    conn.close()
    return render_template("index.html", messages=rows)


@app.route("/health")
def health():
    """Used to confirm the service is up after deployment."""
    return {"status": "ok"}, 200


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
