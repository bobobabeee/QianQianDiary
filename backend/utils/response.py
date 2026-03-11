# -*- coding: utf-8 -*-
"""统一返回格式 { code, msg, data }"""
from flask import jsonify


def ok(msg="success", data=None):
    return jsonify({"code": 200, "msg": msg, "data": data if data is not None else {}})


def fail(code: int, msg: str, data=None):
    body = {"code": code, "msg": msg, "data": data}
    return jsonify(body), 200
