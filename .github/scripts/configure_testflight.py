import json, jwt, time, requests, sys

api_key          = json.load(open(sys.argv[1]))
bundle_id        = sys.argv[2]
owner_email      = sys.argv[3]
owner_name       = sys.argv[4]
app_name         = sys.argv[5]
beta_description = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] else f"Test {app_name} and provide feedback"
feedback_email   = sys.argv[7] if len(sys.argv) > 7 and sys.argv[7] else owner_email
contact_phone    = sys.argv[8] if len(sys.argv) > 8 and sys.argv[8] else "+1234567890"

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
print("🚀 COMPLETE HYBRID TESTFLIGHT SETUP")
print("="*70)

print("📱 Step 1: Finding app in App Store Connect...")
r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]={bundle_id}",
    headers=h()
)
r.raise_for_status()
apps = r.json().get("data", [])
if not apps:
    print(f"❌ App not found: {bundle_id}")
    sys.exit(1)
app_id = apps[0]["id"]
print(f"   ✅ App found: {app_id}")
print()

print("👤 Step 2: Ensuring user exists in App Store Connect...")
internal_user_id = None

def find_active_user():
    next_url = "https://api.appstoreconnect.apple.com/v1/users?limit=200"
    while next_url:
        r = requests.get(next_url, headers=h())
        r.raise_for_status()
        body = r.json()
        for user in body.get("data", []):
            attrs = user.get("attributes", {})
            if (attrs.get("email") or "").strip().lower() == owner_email.lower():
                return user["id"]
        next_url = body.get("links", {}).get("next")
    return None

def find_pending_invitation():
    r = requests.get(
        f"https://api.appstoreconnect.apple.com/v1/userInvitations?filter[email]={owner_email}",
        headers=h()
    )
    if r.status_code != 200:
        print("   ⚠️ Invitations lookup HTTP:", r.status_code)
        return None
    data = r.json().get("data", [])
    return data[0]["id"] if data else None

internal_user_id = find_active_user()

if internal_user_id:
    print(f"   ✅ User already active: {internal_user_id}")
else:
    pending_invite_id = find_pending_invitation()
    if pending_invite_id:
        print(f"   ⚠️ Pending invite exists: {pending_invite_id} — deleting and resending...")
        requests.delete(
            f"https://api.appstoreconnect.apple.com/v1/userInvitations/{pending_invite_id}",
            headers=h()
        )
        time.sleep(3)

    print("   📧 Sending App Store Connect invitation...")
    first = owner_name.split()[0] if owner_name else "Owner"
    last  = " ".join(owner_name.split()[1:]) if len(owner_name.split()) > 1 else "User"
    r = requests.post(
        "https://api.appstoreconnect.apple.com/v1/userInvitations",
        headers=h(),
        json={"data": {"type": "userInvitations", "attributes": {
            "email": owner_email, "firstName": first, "lastName": last,
            "roles": ["DEVELOPER"], "allAppsVisible": True
        }}}
    )
    print(f"   Invite HTTP: {r.status_code} | {r.text[:300]}")

    if r.status_code in (200, 201, 409):
        print("   ✅ Invitation sent/exists — waiting 15s then re-checking...")
        time.sleep(15)
        internal_user_id = find_active_user()
        if internal_user_id:
            print(f"   ✅ User is now active: {internal_user_id}")
        else:
            print("   ⏳ Not active yet — waiting 15s more and checking again...")
            time.sleep(15)
            internal_user_id = find_active_user()
            if internal_user_id:
                print(f"   ✅ User is now active after second check: {internal_user_id}")
            else:
                print("   ⚠️ User still pending — will be added to external group as fallback")
                print("   👉 User must accept the App Store Connect invitation to enable internal testing")
    else:
        print("   ❌ Failed to send invitation")
print()

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
    print(f"   ✅ Internal group exists: {groups[0]['attributes']['name']}")
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
        print("   ✅ Internal group created")
    else:
        print(f"   ❌ Failed to create internal group: {r.text}")
        sys.exit(1)
print()

print("👥 Step 4: Ensuring external TestFlight group exists...")
external_group_id = None
public_link_enabled = False

r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=false",
    headers=h()
)
r.raise_for_status()
groups = r.json().get("data", [])

for g in groups:
    if g.get("attributes", {}).get("publicLinkEnabled", False):
        external_group_id = g["id"]
        public_link_enabled = True
        print(f"   ✅ Public external group exists: '{g['attributes']['name']}'")
        break

if not external_group_id and groups:
    external_group_id = groups[0]["id"]
    public_link_enabled = groups[0]["attributes"].get("publicLinkEnabled", False)
    print(f"   ✅ External group exists: '{groups[0]['attributes']['name']}'")

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
        gd = r.json()["data"]
        external_group_id = gd["id"]
        public_link_enabled = True
        print(f"   ✅ External group created: '{gd['attributes']['name']}'")
    else:
        print(f"   ❌ Could not create external group (HTTP {r.status_code}): {r.text}")
        sys.exit(1)

if not public_link_enabled:
    r = requests.patch(
        f"https://api.appstoreconnect.apple.com/v1/betaGroups/{external_group_id}",
        headers=h(),
        json={"data": {"type": "betaGroups", "id": external_group_id,
              "attributes": {"publicLinkEnabled": True, "publicLinkLimitEnabled": False}}}
    )
    if r.status_code == 200:
        print("   ✅ Public link enabled")
print()

# ── Step 5: Resolve betaTester ID only (group assignment happens after build is added) ──
print("🧪 Step 5: Resolving betaTester ID...")
tester_id = None

r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/betaTesters?filter[email]={owner_email}",
    headers=h()
)
print(f"   betaTesters lookup HTTP: {r.status_code}")
print(f"   betaTesters response: {r.text[:500]}")
if r.status_code == 200:
    data = r.json().get("data", [])
    if data:
        tester_id = data[0]["id"]
        print(f"   ✅ Existing betaTester found: {tester_id}")

if not tester_id:
    first = owner_name.split()[0] if owner_name else "Owner"
    last  = " ".join(owner_name.split()[1:]) if len(owner_name.split()) > 1 else "User"
    create_payload = {"data": {"type": "betaTesters", "attributes": {
        "email": owner_email, "firstName": first, "lastName": last
    }}}
    print(f"   📝 Creating betaTester: {json.dumps(create_payload)}")
    r = requests.post(
        "https://api.appstoreconnect.apple.com/v1/betaTesters",
        headers=h(), json=create_payload
    )
    print(f"   betaTester create HTTP: {r.status_code}")
    print(f"   betaTester create response: {r.text[:500]}")
    if r.status_code in (200, 201):
        tester_id = r.json()["data"]["id"]
        print(f"   ✅ betaTester created: {tester_id}")
    elif r.status_code == 409:
        print("   ⚠️ 409 — tester already exists, re-fetching...")
        r2 = requests.get(
            f"https://api.appstoreconnect.apple.com/v1/betaTesters?filter[email]={owner_email}",
            headers=h()
        )
        print(f"   re-fetch HTTP: {r2.status_code} | {r2.text[:300]}")
        if r2.status_code == 200:
            data = r2.json().get("data", [])
            if data:
                tester_id = data[0]["id"]
                print(f"   ✅ betaTester recovered: {tester_id}")
    else:
        print(f"   ❌ Unexpected error: {r.text[:500]}")

if tester_id:
    print(f"   ✅ tester_id confirmed: {tester_id}")
else:
    print("   ⚠️ Could not resolve tester_id — will skip group assignment")
print()

print("🔗 Step 6: Retrieving public TestFlight link...")
public_testflight_link = None
r = requests.get(
    f"https://api.appstoreconnect.apple.com/v1/betaGroups/{external_group_id}",
    headers=h()
)
if r.status_code == 200:
    public_testflight_link = r.json()["data"]["attributes"].get("publicLink")
    if public_testflight_link:
        print(f"   ✅ {public_testflight_link}")
        with open("testflight_public_link.txt", "w") as f:
            f.write(public_testflight_link)
    else:
        print("   ⚠️ publicLink is null — may need a moment to generate")
else:
    print(f"   ⚠️ Could not fetch group: HTTP {r.status_code}")
print()

print("⏳ Step 7: Waiting for build to finish processing...")
build_id = version = build_num = None
for attempt in range(20):
    r = requests.get(
        f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=1",
        headers=h()
    )
    r.raise_for_status()
    builds = r.json().get("data", [])
    if builds:
        b         = builds[0]
        build_id  = b["id"]
        version   = b["attributes"].get("version")
        build_num = b["attributes"].get("buildNumber", "")
        state     = b["attributes"].get("processingState", "PROCESSING")
        if state == "VALID":
            print(f"   ✅ Build ready: {version} ({build_num})")
            break
        print(f"   ⏳ {version} ({build_num}) state={state} — attempt {attempt+1}/20")
    else:
        print(f"   ⏳ No builds yet — attempt {attempt+1}/20")
    if attempt < 19:
        time.sleep(30)

if not build_id:
    with open("testflight_status.txt", "w") as f:
        f.write("PENDING_BUILD")
    sys.exit(0)
print()

print("🔒 Step 8: Setting export compliance...")
r = requests.patch(
    f"https://api.appstoreconnect.apple.com/v1/builds/{build_id}",
    headers=h(),
    json={"data": {"type": "builds", "id": build_id,
          "attributes": {"usesNonExemptEncryption": False}}}
)
print(f"   HTTP: {r.status_code}")
if r.status_code in (200, 409):
    print("   ✅ Export compliance set")
    time.sleep(5)
print()

print("📝 Step 9: Adding beta build localization...")
r = requests.post(
    "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations",
    headers=h(),
    json={"data": {"type": "betaBuildLocalizations",
          "attributes": {"locale": "en-US", "whatsNew": f"Welcome to {app_name} beta!"},
          "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}}
)
print(f"   HTTP: {r.status_code}")
if r.status_code in (200, 201, 409):
    print("   ✅ Beta build localization set")
print()

if internal_group_id:
    print("📦 Step 10: Adding build to internal group...")
    for attempt in range(15):
        r = requests.post(
            f"https://api.appstoreconnect.apple.com/v1/betaGroups/{internal_group_id}/relationships/builds",
            headers=h(),
            json={"data": [{"type": "builds", "id": build_id}]}
        )
        print(f"   Attempt {attempt+1}: HTTP {r.status_code}")
        if r.status_code in (200, 204, 409):
            print("   ✅ Build added to internal group")
            break
        if r.status_code == 422:
            print("   ⏳ Not ready yet, retrying in 30s...")
            time.sleep(30)
            continue
        time.sleep(30)
    print()

print("📦 Step 11: Adding build to external group...")
for attempt in range(15):
    r = requests.post(
        f"https://api.appstoreconnect.apple.com/v1/betaGroups/{external_group_id}/relationships/builds",
        headers=h(),
        json={"data": [{"type": "builds", "id": build_id}]}
    )
    print(f"   Attempt {attempt+1}: HTTP {r.status_code}")
    if r.status_code in (200, 204, 409):
        print("   ✅ Build added to external group")
        break
    if r.status_code == 422:
        print("   ⏳ Not ready yet, retrying in 30s...")
        time.sleep(30)
        continue
    time.sleep(30)
print()

# ── Step 5b: Add tester to groups NOW that builds are in both groups ──────────
# Apple requires a build in the group before external testers can be assigned.
if tester_id:
    print("🧪 Step 5b: Adding tester to groups (build now in both groups)...")
    print()

    if internal_group_id:
        print("   📦 Adding tester to INTERNAL group...")
        added_to_internal = False
        for int_attempt in range(5):
            r = requests.post(
                f"https://api.appstoreconnect.apple.com/v1/betaGroups/{internal_group_id}/relationships/betaTesters",
                headers=h(),
                json={"data": [{"type": "betaTesters", "id": tester_id}]}
            )
            print(f"   Internal group attempt {int_attempt+1}: HTTP {r.status_code} | {r.text[:300]}")
            if r.status_code in (200, 204):
                print("   ✅ Tester added to INTERNAL group — instant access, no review needed!")
                added_to_internal = True
                break
            elif r.status_code == 409:
                resp_text = r.text
                if "STATE_ERROR" in resp_text or "cannot be assigned" in resp_text:
                    print(f"   ⏳ STATE_ERROR — retrying in 20s (attempt {int_attempt+1}/5)...")
                    time.sleep(20)
                    continue
                else:
                    print("   ✅ Tester already in INTERNAL group — instant access, no review needed!")
                    added_to_internal = True
                    break
            elif r.status_code in (403, 422):
                if int_attempt < 4:
                    print(f"   ⏳ User not yet an active team member (HTTP {r.status_code}), retrying in 20s (attempt {int_attempt+1}/5)...")
                    time.sleep(20)
                    rechk = find_active_user()
                    if rechk:
                        internal_user_id = rechk
                        print(f"   ✅ User became active: {internal_user_id}")
                else:
                    print(f"   ⚠️ User not yet a team member after {int_attempt+1} attempts (HTTP {r.status_code})")
                    print(f"   ℹ️  Once they accept the App Store Connect invitation, run a new build to gain internal testing access")
            else:
                print(f"   ⚠️ Unexpected error adding to internal group (HTTP {r.status_code}): {r.text[:200]}")
                break
        if not added_to_internal:
            print("   ⚠️ Could not add to INTERNAL group — user must accept App Store Connect invitation first")
            print("   ℹ️  They can join via the public TestFlight link in the meantime")
    else:
        print("   ⚠️ No internal group ID — skipping internal group assignment")
    print()

    print("   📦 Adding tester to EXTERNAL group...")
    external_added = False
    for ext_attempt in range(5):
        r = requests.post(
            f"https://api.appstoreconnect.apple.com/v1/betaGroups/{external_group_id}/relationships/betaTesters",
            headers=h(),
            json={"data": [{"type": "betaTesters", "id": tester_id}]}
        )
        print(f"   External group HTTP: {r.status_code} | {r.text[:300]}")

        if r.status_code in (200, 204):
            print("   ✅ Tester added to EXTERNAL group")
            external_added = True
            break
        elif r.status_code == 409:
            resp_text = r.text
            if "STATE_ERROR" in resp_text or "cannot be assigned" in resp_text:
                print(f"   ⏳ STATE_ERROR — tester cannot be assigned yet, retrying in 20s (attempt {ext_attempt+1}/5)...")
                time.sleep(20)
                continue
            else:
                print("   ✅ Tester already in EXTERNAL group")
                external_added = True
                break
        else:
            print(f"   ❌ Unexpected error adding to external group: {r.text[:300]}")
            break

    if not external_added:
        print("   ⚠️ Could not add tester to external group — they can join via public link")
    print()

print("📋 Step 12: Submitting for Beta App Review...")
review_submitted = False
r = requests.post(
    "https://api.appstoreconnect.apple.com/v1/betaAppReviewSubmissions",
    headers=h(),
    json={"data": {"type": "betaAppReviewSubmissions",
          "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}}
)
print(f"   HTTP: {r.status_code} | {r.text[:200]}")
if r.status_code in (200, 201, 409):
    print("   ✅ Submitted for Beta App Review")
    review_submitted = True
else:
    print(f"   ⚠️ Review submission issue: {r.text[:200]}")

status = "SUBMITTED_FOR_REVIEW" if review_submitted else "BUILD_ADDED"
with open("testflight_status.txt", "w") as f:
    f.write(status)

print()
print("="*70)
print("🎉 HYBRID TESTING CONFIGURED!")
if public_testflight_link:
    print(f"🔗 {public_testflight_link}")
print("="*70)
