# -*- coding: utf-8 -*-
"""
重置数据库：删除所有表并重新创建（解决表结构与模型不一致导致的 500）
"""
from app import app
from extensions import db

with app.app_context():
    db.drop_all()
    db.create_all()
    print("数据库已重置，所有表已重新创建")
