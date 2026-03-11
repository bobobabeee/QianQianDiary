# -*- coding: utf-8 -*-
"""初始化数据库表：python init_db.py"""
from app import app
from extensions import db

with app.app_context():
    db.create_all()
    print("数据库表创建完成")
