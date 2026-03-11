# -*- coding: utf-8 -*-
"""
成功日记模型
"""
from extensions import db

DIARY_CATEGORIES = ("work", "health", "relationship", "growth", "daily")


class Diary(db.Model):
    __tablename__ = "diaries"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    content = db.Column(db.Text, nullable=False)
    date = db.Column(db.String(10), nullable=False, index=True)  # yyyy-MM-dd
    category = db.Column(db.String(32), nullable=False, default="daily")
    mood_icon = db.Column(db.String(64), nullable=True, default="")
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    def to_dict(self):
        return {
            "id": self.id,
            "content": self.content,
            "date": self.date,
            "category": self.category,
            "mood_icon": self.mood_icon or "",
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None,
        }
