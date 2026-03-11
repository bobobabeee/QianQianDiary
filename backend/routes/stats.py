# -*- coding: utf-8 -*-
"""
统计接口：美德践行分布（饼图）、完成率
"""
from flask import Blueprint, request
from sqlalchemy import func

from models.virtue_log import VirtueLog, VIRTUE_TYPES
from utils.response import ok, fail
from utils.validators import valid_date
from middleware.auth import require_auth

stats_bp = Blueprint("stats", __name__, url_prefix="/api/v1/stats")


@stats_bp.route("/virtue", methods=["GET"])
@require_auth
def virtue_stats(user_id):
    """
    ?start_date=2026-03-01&end_date=2026-03-31
    返回：by_type 各类型完成次数，completion_rate 完成率
    """
    start_date = request.args.get("start_date", "").strip()
    end_date = request.args.get("end_date", "").strip()

    if not valid_date(start_date):
        return fail(400, "start_date 格式为 yyyy-MM-dd", None)
    if not valid_date(end_date):
        return fail(400, "end_date 格式为 yyyy-MM-dd", None)

    q = VirtueLog.query.filter(
        VirtueLog.user_id == user_id,
        VirtueLog.date >= start_date,
        VirtueLog.date <= end_date,
        VirtueLog.completed == True,
    )
    rows = q.with_entities(VirtueLog.virtue_type, func.count(VirtueLog.id)).group_by(VirtueLog.virtue_type).all()

    by_type = {t: 0 for t in VIRTUE_TYPES}
    total_completed = 0
    for vt, cnt in rows:
        by_type[vt] = cnt
        total_completed += cnt

    from datetime import datetime, timedelta
    s = datetime.strptime(start_date, "%Y-%m-%d")
    e = datetime.strptime(end_date, "%Y-%m-%d")
    days = (e - s).days + 1
    total_possible = days * len(VIRTUE_TYPES)
    completion_rate = round(total_completed / total_possible, 2) if total_possible > 0 else 0.0

    return ok("success", {"by_type": by_type, "completion_rate": completion_rate, "total_completed": total_completed})
