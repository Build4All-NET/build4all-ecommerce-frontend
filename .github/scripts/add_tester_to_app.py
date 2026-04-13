import json, jwt, time, requests, sys

# Args: api_key_json  bundle_id  email  first_name  last_name
api_key    = json.load(open(sys.argv[1]))
bundle_id  = sys.argv[2]
email      = sys.argv[3].strip().lower()
first_name = sys.argv[4].strip() if len(sys.argv) > 4 and sys.argv[4].strip() else "Tester"
last_name  = sys.argv[5].strip() if len(sys.argv) > 5 and sys.argv[5].strip() else "User"

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
    print(f"   ❌ App not found for bundle ID: {bundle_id}")
    sys.exit(1)
app_id = apps[0]["id"]
app_name = apps[0]["attributes"].get("name", bundle_id)
print(f"   ✅ App found: '{app_name}' ({app_id})")
print()

# ── Step 2: Ensure user exists in App Store Connect ───────────────────────────
print("👤 Step 2: Ensuring user exists in App Store Connect...")

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
if user_id:
    print(f"   ✅ User already active in App Store Connect: {user_id}")
else:
    pending_id = find_pending_invitation()
    if pending_id:
        print(f"   ⚠️ Pending invite found ({pending_id}) — deleting and resending...")
        requests.delete(
            f"https://api.appstoreconnect.apple.com/v1/userInvitations/{pending_id}",
            headers=h()
        )
        time.sleep(3)

    print(f"   📧 Sending App Store Connect invitation to {email}...")
    r = requests.post(
        "https://api.appstoreconnect.apple.com/v1/userInvitations",
        headers=h(),
        json={"data": {"type": "userInvitations", "attributes": {
            "email": email, "firstName": first_name, "lastName": last_name,
            "roles": ["DEVELOPER"], "allAppsVisible": True
        }}}
    )
    print(f"   Invite HTTP: {r.status_code} | {r.text[:300]}")

    if r.status_code in (200, 201, 409):
        print("   ⏳ Waiting 15s for account to activate...")
        time.sleep(15)
        user_id = find_active_user()
        if user_id:
            print(f"   ✅ User is now active: {user_id}")
        else:
            print("   ⚠️ User still pending — they must accept the App Store Connect invitation")
            print("   ℹ️  Internal testing will be available once they accept")
    else:
        print("   ❌ Failed to invite user")
print()

# ── Step 3: Ensure internal group exists ─────────────────────────────────────
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
    print(f"   ✅ Internal group: '{groups[0]['attributes']['name']}' ({internal_group_id})")
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
        print(f"   ✅ Internal group created ({internal_group_id})")
    else:
        print(f"   ❌ Failed to create internal group: {r.text[:200]}")
print()

# ── Step 4: Ensure external group exists ─────────────────────────────────────
print("👥 Step 4: Ensuring external TestFlight group exists...")
external_group_id = None
r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=false",
    headers=h()
)
r.raise_for_status()
groups = r.json().get("data", [])

for g in groups:
    if g.get("attributes", {}).get("publicLinkEnabled", False):
        external_group_id = g["id"]
        print(f"   ✅ Public external group: '{g['attributes']['name']}' ({external_group_id})")
        break

if not external_group_id and groups:
    external_group_id = groups[0]["id"]
    print(f"   ✅ External group: '{groups[0]['attributes']['name']}' ({external_group_id})")

if not external_group_id:
    r = requests.post(
        "https://api.appstoreconnect.apple.com/v1/betaGroups",
        headers=h(),
        json={"data": {"type": "betaGroups", "attributes": {
            "name": "External Testers", "isInternalGroup": False,
            "publicLinkEnabled": True, "publicLinkLimitEnabled": False
        }, "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}}
    )
    if r.status_code in (200, 201):
        external_group_id = r.json()["data"]["id"]
        print(f"   ✅ External group created ({external_group_id})")
    else:
        print(f"   ❌ Failed to create external group: {r.text[:200]}")
        sys.exit(1)
print()

# ── Step 5: Resolve betaTester ID ────────────────────────────────────────────
print("🧪 Step 5: Resolving betaTester ID...")
tester_id = None
r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/betaTesters?filter[email]={email}",
    headers=h()
)
print(f"   betaTesters lookup HTTP: {r.status_code}")
if r.status_code == 200:
    data = r.json().get("data", [])
    if data:
        tester_id = data[0]["id"]
        print(f"   ✅ Existing betaTester found: {tester_id}")

if not tester_id:
    r = requests.post(
        "https://api.appstoreconnect.apple.com/v1/betaTesters",
        headers=h(),
        json={"data": {"type": "betaTesters", "attributes": {
            "email": email, "firstName": first_name, "lastName": last_name
        }}}
    )
    print(f"   betaTester create HTTP: {r.status_code} | {r.text[:300]}")
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
    else:
        print(f"   ❌ Could not create betaTester: {r.text[:300]}")

if not tester_id:
    print("   ❌ FATAL: Cannot resolve tester ID")
    sys.exit(1)

print(f"   ✅ tester_id: {tester_id}")
print()

# ── Step 6: Add tester to INTERNAL group ─────────────────────────────────────
print("📦 Step 6: Adding tester to INTERNAL group...")
added_to_internal = False
if internal_group_id:
    for attempt in range(5):
        r = requests.post(
            f"https://api.appstoreconnect.apple.com/v1/betaGroups/{internal_group_id}/relationships/betaTesters",
            headers=h(),
            json={"data": [{"type": "betaTesters", "id": tester_id}]}
        )
        print(f"   Attempt {attempt+1}: HTTP {r.status_code} | {r.text[:200]}")
        if r.status_code in (200, 204):
            print("   ✅ Added to INTERNAL group — instant access, no review needed!")
            added_to_internal = True
            break
        elif r.status_code == 409:
            if "STATE_ERROR" in r.text or "cannot be assigned" in r.text:
                print(f"   ⏳ STATE_ERROR — retrying in 10s...")
                time.sleep(10)
                continue
            else:
                print("   ✅ Already in INTERNAL group — instant access, no review needed!")
                added_to_internal = True
                break
        elif r.status_code in (403, 422):
            if attempt < 4:
                print(f"   ⏳ Not yet an active team member (HTTP {r.status_code}), retrying in 15s...")
                time.sleep(15)
                rechk = find_active_user()
                if rechk:
                    user_id = rechk
                    print(f"   ✅ User became active: {user_id}")
            else:
                print(f"   ⚠️ User not yet a team member after {attempt+1} attempts")
                print("   ℹ️  They must accept the App Store Connect invitation email to enable internal testing")
        else:
            print(f"   ⚠️ Unexpected error (HTTP {r.status_code}): {r.text[:200]}")
            break
    if not added_to_internal:
        print("   ⚠️ Could not add to INTERNAL group yet — pending invitation acceptance")
else:
    print("   ⚠️ No internal group — skipping")
print()

# ── Step 7: Add tester to EXTERNAL group ─────────────────────────────────────
print("📦 Step 7: Adding tester to EXTERNAL group...")
added_to_external = False
for attempt in range(5):
    r = requests.post(
        f"https://api.appstoreconnect.apple.com/v1/betaGroups/{external_group_id}/relationships/betaTesters",
        headers=h(),
        json={"data": [{"type": "betaTesters", "id": tester_id}]}
    )
    print(f"   Attempt {attempt+1}: HTTP {r.status_code} | {r.text[:200]}")
    if r.status_code in (200, 204):
        print("   ✅ Added to EXTERNAL group")
        added_to_external = True
        break
    elif r.status_code == 409:
        if "STATE_ERROR" in r.text or "cannot be assigned" in r.text:
            print(f"   ⏳ STATE_ERROR — no approved build in group yet, retrying in 10s...")
            time.sleep(10)
            continue
        else:
            print("   ✅ Already in EXTERNAL group")
            added_to_external = True
            break
    else:
        print(f"   ⚠️ Unexpected error (HTTP {r.status_code}): {r.text[:200]}")
        break

if not added_to_external:
    print("   ⚠️ Could not add to external group — no approved build exists yet")
    print("   ℹ️  Once a build is approved, the tester will be added automatically on the next build run")
print()

# ── Step 8: Get public TestFlight link ───────────────────────────────────────
print("🔗 Step 8: Getting public TestFlight link...")
r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/betaGroups/{external_group_id}",
    headers=h()
)
public_link = None
if r.status_code == 200:
    public_link = r.json()["data"]["attributes"].get("publicLink")
    if public_link:
        print(f"   ✅ {public_link}")
    else:
        print("   ⚠️ Public link not yet generated")
print()

# ── Summary ───────────────────────────────────────────────────────────────────
print("="*70)
print("📋 SUMMARY")
print(f"   Account   : {first_name} {last_name} <{email}>")
print(f"   App       : {app_name}")
print(f"   ASC invite: {'✅ Active team member' if user_id else '⏳ Invitation sent — awaiting acceptance'}")
print(f"   Internal  : {'✅ Added' if added_to_internal else '⏳ Pending — accept App Store Connect invite first'}")
print(f"   External  : {'✅ Added' if added_to_external else '⏳ Pending — needs an approved build in the group'}")
if public_link:
    print(f"   Public link: {public_link}")
print("="*70)
