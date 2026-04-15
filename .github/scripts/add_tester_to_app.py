"""
Add tester to a specific app in App Store Connect / TestFlight.

Flow:
  1. Find the app by bundle ID.
  2. Check /v1/users — if the email is already an active team member,
     add them directly to the internal TestFlight group → ADDED_TO_INTERNAL.
  3. If not active, check for a pending /v1/userInvitations entry.
     - If one exists, re-check whether the user is now active (they may
       have just accepted the invite).
         If yes  → internal add flow → ADDED_TO_INTERNAL.
         If still not active → INVITATION_PENDING (no duplicate invite sent).
  4. No pending invite → send a fresh invitation → INVITATION_SENT.
  5. If Apple returns 409 on the invite call, re-check active user:
         Active  → internal add flow → ADDED_TO_INTERNAL.
         Not yet → INVITATION_PENDING.

tester_result.json keys:
  status, message, requestId, appleInvitationId, appleUserId,
  appleBetaTesterId, internalGroupId, appId

Exit codes:
  0  success  (ADDED_TO_INTERNAL | INVITATION_SENT | INVITATION_PENDING)
  1  fatal error
"""

import json
import jwt
import time
import requests
import sys
import pathlib

api_key    = json.load(open(sys.argv[1], encoding="utf-8"))
bundle_id  = sys.argv[2].strip()
email      = sys.argv[3].strip().lower()
first_name = (sys.argv[4].strip() if len(sys.argv) > 4 else "") or "Tester"
last_name  = (sys.argv[5].strip() if len(sys.argv) > 5 else "") or "User"
request_id = (sys.argv[6].strip() if len(sys.argv) > 6 else "")

BASE = "https://api.appstoreconnect.apple.com"


def create_token():
    return jwt.encode(
        {
            "iss": api_key["issuer_id"],
            "iat": int(time.time()),
            "exp": int(time.time()) + 1200,
            "aud": "appstoreconnect-v1",
        },
        api_key["key"],
        algorithm="ES256",
        headers={"kid": api_key["key_id"], "typ": "JWT"},
    )


def h():
    return {
        "Authorization": f"Bearer {create_token()}",
        "Content-Type": "application/json",
    }


def write_result(
    status,
    message,
    apple_invitation_id="",
    apple_user_id="",
    apple_beta_tester_id="",
    internal_group_id="",
    app_id="",
):
    payload = {
        "status": status,
        "message": message,
        "requestId": request_id,
        "appleInvitationId": apple_invitation_id or "",
        "appleUserId": apple_user_id or "",
        "appleBetaTesterId": apple_beta_tester_id or "",
        "internalGroupId": internal_group_id or "",
        "appId": app_id or "",
    }
    pathlib.Path("tester_result.json").write_text(
        json.dumps(payload, ensure_ascii=False), encoding="utf-8"
    )
    print(f"\n📄 Result: [{status}] {message}")
    print("📦 tester_result.json payload:")
    print(json.dumps(payload, indent=2, ensure_ascii=False))


# ── helpers ───────────────────────────────────────────────────────────────────

def find_active_user():
    """Return the /v1/users id for `email`, or None."""
    next_url = f"{BASE}/v1/users?limit=200"
    while next_url:
        r = requests.get(next_url, headers=h())
        r.raise_for_status()
        body = r.json()
        for user in body.get("data", []):
            if (user.get("attributes", {}).get("email") or "").strip().lower() == email:
                return user["id"]
        next_url = body.get("links", {}).get("next")
    return None


def find_pending_invitation():
    """Return the /v1/userInvitations id for `email`, or None."""
    r = requests.get(
        f"{BASE}/v1/userInvitations?filter[email]={email}",
        headers=h(),
    )
    if r.status_code != 200:
        return None
    data = r.json().get("data", [])
    return data[0]["id"] if data else None


def ensure_internal_group(app_id):
    """Return the internal betaGroup id for the app, creating it if needed."""
    r = requests.get(
        f"{BASE}/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=true",
        headers=h(),
    )
    r.raise_for_status()
    groups = r.json().get("data", [])
    if groups:
        gid = groups[0]["id"]
        print(f"   ✅ Internal group: '{groups[0]['attributes']['name']}' ({gid})")
        return gid

    r = requests.post(
        f"{BASE}/v1/betaGroups",
        headers=h(),
        json={
            "data": {
                "type": "betaGroups",
                "attributes": {"name": "Internal Testers", "isInternalGroup": True},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        },
    )
    if r.status_code in (200, 201):
        gid = r.json()["data"]["id"]
        print(f"   ✅ Internal group created ({gid})")
        return gid
    return None


def resolve_beta_tester():
    """Return the betaTesters id for `email`, creating it if needed."""
    r = requests.get(
        f"{BASE}/v1/betaTesters?filter[email]={email}", headers=h()
    )
    if r.status_code == 200:
        data = r.json().get("data", [])
        if data:
            tid = data[0]["id"]
            print(f"   ✅ betaTester found: {tid}")
            return tid

    r = requests.post(
        f"{BASE}/v1/betaTesters",
        headers=h(),
        json={
            "data": {
                "type": "betaTesters",
                "attributes": {
                    "email": email,
                    "firstName": first_name,
                    "lastName": last_name,
                },
            }
        },
    )
    if r.status_code in (200, 201):
        tid = r.json()["data"]["id"]
        print(f"   ✅ betaTester created: {tid}")
        return tid

    if r.status_code == 409:
        r2 = requests.get(
            f"{BASE}/v1/betaTesters?filter[email]={email}", headers=h()
        )
        if r2.status_code == 200:
            data = r2.json().get("data", [])
            if data:
                tid = data[0]["id"]
                print(f"   ✅ betaTester recovered after 409: {tid}")
                return tid

    return None


def add_to_internal_group(user_id, app_id, app_name):
    """
    Full internal-group flow for an already-active user.
    Writes tester_result.json and exits.
    """
    print()
    print(f"   ✅ User is an active App Store Connect member: {user_id}")
    print()

    print("👥 Ensuring internal TestFlight group exists...")
    internal_group_id = ensure_internal_group(app_id)
    if not internal_group_id:
        msg = "Failed to find or create internal TestFlight group"
        print(f"   ❌ {msg}")
        write_result("ERROR", msg, apple_user_id=user_id, app_id=app_id)
        sys.exit(1)
    print()

    print("🧪 Resolving betaTester record...")
    tester_id = resolve_beta_tester()
    if not tester_id:
        msg = "Could not resolve betaTester ID"
        print(f"   ❌ {msg}")
        write_result(
            "ERROR", msg,
            apple_user_id=user_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        sys.exit(1)
    print()

    print("📦 Adding tester to INTERNAL group...")
    added = False
    for attempt in range(5):
        r = requests.post(
            f"{BASE}/v1/betaGroups/{internal_group_id}/relationships/betaTesters",
            headers=h(),
            json={"data": [{"type": "betaTesters", "id": tester_id}]},
        )
        print(f"   Attempt {attempt + 1}: HTTP {r.status_code} | {r.text[:200]}")

        if r.status_code in (200, 204):
            print("   ✅ Tester added to INTERNAL group — instant access, no review needed!")
            added = True
            break
        elif r.status_code == 409:
            if "STATE_ERROR" in r.text or "cannot be assigned" in r.text:
                print("   ⏳ STATE_ERROR — retrying in 15 s...")
                time.sleep(15)
            else:
                print("   ✅ Tester already in INTERNAL group — instant access, no review needed!")
                added = True
                break
        elif r.status_code in (403, 422):
            if attempt < 4:
                print(f"   ⏳ Not yet active (HTTP {r.status_code}), retrying in 15 s...")
                time.sleep(15)
            else:
                print("   ❌ Could not add — Apple rejected assignment after retries")
        else:
            print(f"   ❌ Unexpected error (HTTP {r.status_code})")
            break

    if added:
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} has been added to the internal TestFlight group for '{app_name}'. "
            "They can now test the app directly — no Apple review required.",
            apple_user_id=user_id,
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
    else:
        write_result(
            "ERROR",
            f"Could not add {email} to the internal group. Please check App Store Connect.",
            apple_user_id=user_id,
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
    sys.exit(0 if added else 1)


# ═══════════════════════════════════════════════════════════════════════════════

print("=" * 70)
print("👤 ADD TESTER TO APP")
print(f"   Email      : {email}")
print(f"   Name       : {first_name} {last_name}")
print(f"   App        : {bundle_id}")
print(f"   Request ID : {request_id or '(not provided)'}")
print("=" * 70)
print()

# ── Step 1: Find app ──────────────────────────────────────────────────────────
print("📱 Step 1: Finding app in App Store Connect...")
r = requests.get(
    f"{BASE}/v1/apps?filter[bundleId]={bundle_id}",
    headers=h(),
)
r.raise_for_status()

apps = r.json().get("data", [])
if not apps:
    msg = f"App not found for bundle ID: {bundle_id}"
    print(f"   ❌ {msg}")
    write_result("ERROR", msg)
    sys.exit(1)

app_id   = apps[0]["id"]
app_name = apps[0]["attributes"].get("name", bundle_id)
print(f"   ✅ App found: '{app_name}' ({app_id})")
print()

# ── Step 2: Check if user is already an active App Store Connect member ───────
print("👤 Step 2: Checking if user is active in /v1/users...")
user_id = find_active_user()

if user_id:
    # Already active — add directly to internal group, no invite needed
    print(f"   ✅ User already active ({user_id}) — skipping invitation")
    add_to_internal_group(user_id, app_id, app_name)   # exits

# ── Step 3: Not active — check for an existing pending invitation ─────────────
print("   ℹ️  User is NOT yet an active App Store Connect member")
print()
print("📧 Step 3: Checking for existing pending invitation...")

pending_id = find_pending_invitation()
if pending_id:
    print(f"   ⚠️  Pending invitation found ({pending_id})")
    print("   🔄 Re-checking whether user has since become active...")
    recheck_id = find_active_user()
    if recheck_id:
        # User accepted the invite since we last checked — proceed to group add
        print("   ✅ User is now active (accepted the invite) — proceeding to internal add flow")
        add_to_internal_group(recheck_id, app_id, app_name)   # exits
    else:
        print("   ℹ️  User has NOT accepted the invitation yet")
        write_result(
            "INVITATION_PENDING",
            f"An invitation was previously sent to {email} in App Store Connect. "
            f"Please ask {first_name} {last_name} to check their email and accept the Apple invitation, "
            "then re-run this workflow to add them to the internal testing group.",
            apple_invitation_id=pending_id,
            app_id=app_id,
        )
        sys.exit(0)

# ── Step 4: No pending invite — send a fresh invitation ──────────────────────
print()
print("📧 Step 4: Sending App Store Connect invitation...")

r = requests.post(
    f"{BASE}/v1/userInvitations",
    headers=h(),
    json={
        "data": {
            "type": "userInvitations",
            "attributes": {
                "email": email,
                "firstName": first_name,
                "lastName": last_name,
                "roles": ["DEVELOPER"],
                "allAppsVisible": True,
            },
        }
    },
)

print(f"   Invite HTTP: {r.status_code} | {r.text[:400]}")

if r.status_code in (200, 201):
    invitation_id = ""
    try:
        invitation_id = r.json().get("data", {}).get("id", "")
    except Exception:
        pass

    print("   ✅ Invitation sent successfully")
    write_result(
        "INVITATION_SENT",
        f"An App Store Connect invitation has been sent to {email}. "
        f"Please ask {first_name} {last_name} to accept the invitation email from Apple, "
        "then re-run this workflow to add them to the internal testing group.",
        apple_invitation_id=invitation_id,
        app_id=app_id,
    )

elif r.status_code == 409:
    # Apple says the address is already known in their system — re-check active user
    print("   ⚠️  409 from Apple — re-checking if user is now active...")
    recheck_id = find_active_user()
    if recheck_id:
        print("   ✅ User is active (409 race-condition) — proceeding to internal add flow")
        add_to_internal_group(recheck_id, app_id, app_name)   # exits

    # Not active — look up the pending invitation ID for the result payload
    pending_id = find_pending_invitation()
    print("   ℹ️  User still not active after 409 — returning INVITATION_PENDING")
    write_result(
        "INVITATION_PENDING",
        f"An invitation already exists for {email} in App Store Connect. "
        f"Please ask {first_name} {last_name} to check their email and accept the Apple invitation, "
        "then re-run this workflow to add them to the internal testing group.",
        apple_invitation_id=pending_id or "",
        app_id=app_id,
    )

else:
    print(f"   ❌ Failed to send invitation (HTTP {r.status_code})")
    write_result(
        "ERROR",
        f"Failed to send App Store Connect invitation to {email} (HTTP {r.status_code}). "
        "Please check the email address and try again.",
        app_id=app_id,
    )
    sys.exit(1)

print()
result = json.loads(pathlib.Path("tester_result.json").read_text(encoding="utf-8"))
print("=" * 70)
print(f"📋 STATUS  : {result['status']}")
print(f"📋 MESSAGE : {result['message']}")
print("=" * 70)
