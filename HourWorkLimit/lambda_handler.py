import os
import json
import boto3

org = boto3.client("organizations")

POLICY_ID = os.environ["POLICY_ID"]   # مثلا p-abc123xyz
OU_ID     = os.environ["OU_ID"]       # مثلا ou-abcd-efghijk

def _is_attached(policy_id, target_id):
    resp = org.list_policies_for_target(TargetId=target_id, Filter="SERVICE_CONTROL_POLICY")
    for p in resp.get("Policies", []):
        if p.get("Id") == policy_id:
            return True
    return False

def handler(event, context):
    """
    event نمونه:
      {"action":"attach"}  -> فعال‌کردن محدودیت (خارج از ساعات اداری)
      {"action":"detach"}  -> برداشتن محدودیت (شروع ساعات اداری)
    """
    action = (event or {}).get("action")
    if action not in ("attach", "detach"):
        return {"ok": False, "msg": "action must be 'attach' or 'detach'"}

    attached = _is_attached(POLICY_ID, OU_ID)

    if action == "attach":
        if attached:
            return {"ok": True, "msg": "already attached"}
        org.attach_policy(PolicyId=POLICY_ID, TargetId=OU_ID)
        return {"ok": True, "msg": "attached"}

    if action == "detach":
        if not attached:
            return {"ok": True, "msg": "already detached"}
        org.detach_policy(PolicyId=POLICY_ID, TargetId=OU_ID)
        return {"ok": True, "msg": "detached"}
