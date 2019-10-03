from typing import Union

from flask import Request, Response

from werkzeug.local import LocalProxy

HTTPRequest = Union[LocalProxy, Request]

def run(request: HTTPRequest) -> Response:
    return Response("I work!")
