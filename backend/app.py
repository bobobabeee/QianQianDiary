# -*- coding: utf-8 -*-
"""
Flask 应用入口：统一前缀 /api/v1，JWT 鉴权，全局异常，CORS，日志
"""
import logging
import os
from flask import Flask, jsonify
from flask_cors import CORS

from config import Config
from extensions import db
from routes.auth import auth_bp
from routes.diary import diary_bp
from routes.virtue import virtue_bp
from routes.calendar import calendar_bp
from routes.stats import stats_bp
from routes.vision import vision_bp

# 注册模型（供 create_all 创建表）
from models import User, Diary, VirtueLog, VisionItem  # noqa: F401


def create_app(config_class=Config) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config_class)
    app.config["SQLALCHEMY_DATABASE_URI"] = Config.get_sqlalchemy_uri()

    # 日志
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    app.logger.setLevel(logging.INFO)

    db.init_app(app)
    CORS(app, origins=config_class.CORS_ORIGINS, supports_credentials=True)

    # 蓝图
    app.register_blueprint(auth_bp)
    app.register_blueprint(diary_bp)
    app.register_blueprint(virtue_bp)
    app.register_blueprint(calendar_bp)
    app.register_blueprint(stats_bp)
    app.register_blueprint(vision_bp)

    @app.route("/")
    def index():
        return jsonify({"code": 200, "msg": "success", "data": {"service": "Qianqian Diary API"}})

    @app.route("/health")
    def health():
        return jsonify({"code": 200, "msg": "success", "data": {"status": "healthy"}})

    # 全局异常处理
    @app.errorhandler(Exception)
    def handle_error(e):
        app.logger.exception("unhandled error: %s", e)
        msg = "服务器内部错误"
        if os.environ.get("FLASK_DEBUG") == "1":
            msg = str(e)
        return jsonify({"code": 500, "msg": msg, "data": None}), 200

    return app


app = create_app()

if __name__ == "__main__":
    host = os.environ.get("FLASK_HOST", "0.0.0.0")
    port = int(os.environ.get("FLASK_PORT", "5001"))
    app.run(host=host, port=port, debug=False)
