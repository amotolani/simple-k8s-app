#!flask/bin/python
import json

from flask import Flask, request

# Main flask application
app = Flask(__name__)

SERVER_ERROR_MSG = "The server encountered an internal error"


@app.route("/", methods=["GET"])
def get_root():
    """Returns `Hello Smile`"""
    
    body = json.dumps({
        "message": "Hello Smile" 
    })
    return body, 200



@app.route("/healthy", methods=["GET"])
def get_health():
    """Health Check"""
    try:
        # implement some meaniful health checks
        pass
    except Exception as e:
        return SERVER_ERROR_MSG , 500
    return "", 200


def init_app():
    """
    Initializes and returns a flask app
    """

    return app


if __name__ == "__main__":
    app = init_app()
    # Run app locally with development server in debug mode.
    app.run(host="0.0.0.0", port=8080, debug=True)
else:
    # Create App for production server
    app = init_app()
