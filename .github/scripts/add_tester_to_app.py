"""
Add tester to a specific app in App Store Connect / TestFlight.

Args (sys.argv):
  1  api_key_json   path to api_key.json
  2  bundle_id      iOS bundle ID
  3  email          tester email
  4  first_name
  5  last_name

Exit codes:
  0  success (user added OR invitation sent — details in tester_result.json)
  1  fatal error (app not found, bad credentials, etc.)
"""
import json, jwt, time, requests, sys, pathlib

api_key    = json.load(open(sys.argv[1], encoding="utf-8"))
bundle_id  = sys.argv[2].strip()
email      = sys.argv[3].strip().lower()
first_name = (sys.argv[4].strip() if len(sys.argv) > 4 else "") or "Tester"
last_name  = (sys.argv[5].strip() if len(sys.argv) > 5 else "") or "User"

def create_token():
    return jwt.encode({
        "iss": api_key["issuer_id"],
        "iat": int(time.time()),
        "exp": int(time.time()) + 1200,
        "aud": "appstoreconnect-v1"
    }, api_key["key"], algorithm="ES256",
    headers={"kid": api_key["key_id"], "typ": "JWT"})

def h():
    return {"Authorization": f"Bearer {create_token()}", "Content-Type": "application/json"}

def write_result(status, message):
    pathlib.Path("tester_result.json").write_text(
        json.dumps({"status": status, "message": message}, ensure_ascii=False),
        encoding="utf-8"
    )
    print(f"\n📄 Result: [{status}] {message}")

print("="*70)
print("👤 ADD TESTER TO APP")
print(f"   Email : {email}")
print(f"   Name  : {first_name} {last_name}")
print(f"   App   : {bundle_id}")
print("="*70)
print()

# ── Step 1: Find app ──────────────────────────────────────────────────────────
print("📱 Step 1: Finding app in App Store Connect...")
r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}",
    headers=h()
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
print("👤 Step 2: Checking if user is active in App Store Connect...")

def find_active_user():
    next_url = "https://api.appstoreconnect.apple.com/v1/users?limit=200"
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
    r = requests.get(
        f"https://api.appstoreconnect.apple.com/v1/userInvitations?filter[email]={email}",
        headers=h()
    )
    if r.status_code != 200:
        return None
    data = r.json().get("data", [])
    return data[0]["id"] if data else None

user_id = find_active_user()

# ── Branch A: User is already active → add to internal group directly ─────────
if user_id:
    print(f"   ✅ User is an active App Store Connect member: {user_id}")
    print()

    # Ensure internal group exists
    print("👥 Step 3: Ensuring internal TestFlight group exists...")
    internal_group_id = None
    r = requests.get(
        f"https://api.appstoreconnect.apple.com/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=true",
        headers=h()
    )
    r.raise_for_status()
    groups = r.json().get("data", [])
    if groups:
        internal_group_id = groups[0]["id"]
        print(f"   ✅ Internal group: '{groups[0]['attributes']['name']}'")
    else:
        r = requests.post(
            "https://api.appstoreconnect.apple.com/v1/betaGroups",
            headers=h(),
            json={"data": {"type": "betaGroups", "attributes": {
                "name": "Internal Testers", "isInternalGroup": True
            }, "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}}
        )
        if r.status_code in (200, 201):
            internal_group_id = r.json()["data"]["id"]
            print(f"   ✅ Internal group created")
        else:
            msg = f"Failed to create internal group: {r.text[:200]}"
            print(f"   ❌ {msg}")
            write_result("ERROR", msg)
            sys.exit(1)
    print()

    # Resolve / create betaTester record
    print("🧪 Step 4: Resolving betaTester record...")
    tester_id = None
    r = requests.get(
        f"https://api.appstoreconnect.apple.com/v1/betaTesters?filter[email]={email}",
        headers=h()
    )
    if r.status_code == 200:
        data = r.json().get("data", [])
        if data:
            tester_id = data[0]["id"]
            print(f"   ✅ betaTester found: {tester_id}")

    if not tester_id:
        r = requests.post(
            "https://api.appstoreconnect.apple.com/v1/betaTesters",
            headers=h(),
            json={"data": {"type": "betaTesters", "attributes": {
                "email": email, "firstName": first_name, "lastName": last_name
            }}}
        )
        if r.status_code in (200, 201):
            tester_id = r.json()["data"]["id"]
            print(f"   ✅ betaTester created: {tester_id}")
        elif r.status_code == 409:
            r2 = requests.get(
                f"https://api.appstoreconnect.apple.com/v1/betaTesters?filter[email]={email}",
                headers=h()
            )
            if r2.status_code == 200:
                data = r2.json().get("data", [])
                if data:
                    tester_id = data[0]["id"]
                    print(f"   ✅ betaTester recovered: {tester_id}")
        if not tester_id:
            msg = "Could not resolve betaTester ID"
            print(f"   ❌ {msg}")
            write_result("ERROR", msg)
            sys.exit(1)
    print()

    # Add to internal group
    print("📦 Step 5: Adding tester to INTERNAL group...")
    added = False
    for attempt in range(5):
        r = requests.post(
            f"https://api.appstoreconnect.apple.com/v1/betaGroups/{internal_group_id}/relationships/betaTesters",
            headers=h(),
            json={"data": [{"type": "betaTesters", "id": tester_id}]}
        )
        print(f"   Attempt {attempt+1}: HTTP {r.status_code} | {r.text[:200]}")
        if r.status_code in (200, 204):
            print("   ✅ Tester added to INTERNAL group — instant access, no review needed!")
            added = True
            break
        elif r.status_code == 409:
            if "STATE_ERROR" in r.text or "cannot be assigned" in r.text:
                print(f"   ⏳ STATE_ERROR — retrying in 15s...")
                time.sleep(15)
                continue
            else:
                print("   ✅ Tester already in INTERNAL group — instant access, no review needed!")
                added = True
                break
        elif r.status_code in (403, 422):
            if attempt < 4:
                print(f"   ⏳ Not yet active (HTTP {r.status_code}), retrying in 15s...")
                time.sleep(15)
                rechk = find_active_user()
                if rechk:
                    user_id = rechk
            else:
                print(f"   ❌ Could not add — user is listed as active but Apple rejected assignment")
        else:
            print(f"   ❌ Unexpected error (HTTP {r.status_code})")
            break

    if added:
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} has been added to the internal TestFlight group for '{app_name}'. "
            f"They can now test the app directly — no Apple review required."
        )
    else:
        write_result(
            "ERROR",
            f"Could not add {email} to the internal group. Please check App Store Connect."
        )

# ── Branch B: User not active → send invitation ───────────────────────────────
else:
    print(f"   ℹ️ User is NOT yet an active App Store Connect member")
    print()

    print("📧 Step 3: Sending App Store Connect invitation...")

    # Delete stale pending invite first
    pending_id = find_pending_invitation()
    if pending_id:
        print(f"   ⚠️ Deleting stale pending invite ({pending_id}) and resending...")
        requests.delete(
            f"https://api.appstoreconnect.apple.com/v1/userInvitations/{pending_id}",
            headers=h()
        )
        time.sleep(3)

    r = requests.post(
        "https://api.appstoreconnect.apple.com/v1/userInvitations",
        headers=h(),
        json={"data": {"type": "userInvitations", "attributes": {
            "email": email, "firstName": first_name, "lastName": last_name,
            "roles": ["DEVELOPER"], "allAppsVisible": True
        }}}
    )
    print(f"   Invite HTTP: {r.status_code} | {r.text[:400]}")

    if r.status_code in (200, 201):
        print("   ✅ Invitation sent successfully")
        write_result(
            "INVITATION_SENT",
            f"An App Store Connect invitation has been sent to {email}. "
            f"Please ask {first_name} {last_name} to accept the invitation email from Apple, "
            f"then re-run this workflow from the interface to add them to the internal testing group."
        )
    elif r.status_code == 409:
        # Email already in system — could be an existing Apple ID not yet accepted
        print("   ⚠️ Email already exists in Apple's system (409)")
        write_result(
            "INVITATION_PENDING",
            f"An invitation already exists for {email} in App Store Connect. "
            f"Please ask {first_name} {last_name} to check their email and accept the Apple invitation, "
            f"then re-run this workflow from the interface to add them to the internal testing group."
        )
    else:
        print(f"   ❌ Failed to send invitation (HTTP {r.status_code})")
        write_result(
            "ERROR",
            f"Failed to send App Store Connect invitation to {email} (HTTP {r.status_code}). "
            f"Please check the email address and try again."
        )

print()
result = json.loads(pathlib.Path("tester_result.json").read_text(encoding="utf-8"))
print("="*70)
print(f"📋 STATUS  : {result['status']}")
print(f"📋 MESSAGE : {result['message']}")
print("="*70)
