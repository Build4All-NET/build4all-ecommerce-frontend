import json, jwt, time, requests, sys

api_key          = json.load(open(sys.argv[1]))
bundle_id        = sys.argv[2]
owner_email      = sys.argv[3]
owner_name       = sys.argv[4]
app_name         = sys.argv[5]
beta_description = sys.argv[6] if len(sys.argv) > 6 and sys.argv[6] else f"Test {app_name} and provide feedback"
feedback_email   = sys.argv[7] if len(sys.argv) > 7 and sys.argv[7] else owner_email
contact_phone    = sys.argv[8] if len(sys.argv) > 8 and sys.argv[8] else "+1234567890"

BASE = "https://api.appstoreconnect.apple.com"

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
r = requests.get(f"{BASE}/v1/apps?filter[bundleId]={bundle_id}", headers=h())
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
    # Fast path: filter by username (Apple ID) — finds Account Holders
    r = requests.get(f"{BASE}/v1/users?filter[username]={owner_email}&limit=10", headers=h())
    if r.status_code == 200:
        for user in r.json().get("data", []):
            attrs = user.get("attributes", {})
            u_email    = (attrs.get("email")    or "").strip().lower()
            u_username = (attrs.get("username") or "").strip().lower()
            if u_email == owner_email.lower() or u_username == owner_email.lower():
                print(f"   ✅ Found via username filter: {user['id']}")
                return user["id"]
    # Slow path: paginate all users checking both email and username
    next_url = f"{BASE}/v1/users?limit=200"
    while next_url:
        r = requests.get(next_url, headers=h())
        r.raise_for_status()
        body = r.json()
        for user in body.get("data", []):
            attrs = user.get("attributes", {})
            u_email    = (attrs.get("email")    or "").strip().lower()
            u_username = (attrs.get("username") or "").strip().lower()
            if u_email == owner_email.lower() or u_username == owner_email.lower():
                return user["id"]
        next_url = body.get("links", {}).get("next")
    return None

def find_pending_invitation():
    r = requests.get(
        f"{BASE}/v1/userInvitations?filter[email]={owner_email}",
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
        requests.delete(f"{BASE}/v1/userInvitations/{pending_invite_id}", headers=h())
        time.sleep(3)

    print("   📧 Sending App Store Connect invitation...")
    first = owner_name.split()[0] if owner_name else "Owner"
    last  = " ".join(owner_name.split()[1:]) if len(owner_name.split()) > 1 else "User"
    r = requests.post(
        f"{BASE}/v1/userInvitations",
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
    f"{BASE}/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=true",
    headers=h()
)
r.raise_for_status()
groups = r.json().get("data", [])
if groups:
    internal_group_id = groups[0]["id"]
    print(f"   ✅ Internal group exists: {groups[0]['attributes']['name']}")
else:
    r = requests.post(
        f"{BASE}/v1/betaGroups",
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
    f"{BASE}/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=false",
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
        f"{BASE}/v1/betaGroups",
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
        f"{BASE}/v1/betaGroups/{external_group_id}",
        headers=h(),
        json={"data": {"type": "betaGroups", "id": external_group_id,
              "attributes": {"publicLinkEnabled": True, "publicLinkLimitEnabled": False}}}
    )
    if r.status_code == 200:
        print("   ✅ Public link enabled")
print()

# ── Step 5: Resolve betaTester and add to INTERNAL group (one-shot approach) ──
print("🧪 Step 5: Resolving betaTester and adding to internal group...")
tester_id = None
added_to_internal_already = False  # True when Step 5 confirms internal membership

if internal_group_id:
    # Check if already in internal group
    r = requests.get(
        f"{BASE}/v1/betaGroups/{internal_group_id}/betaTesters?limit=200",
        headers=h()
    )
    member_count = len(r.json().get("data", [])) if r.status_code == 200 else "?"
    print(f"   Internal group members → HTTP {r.status_code} | found {member_count} testers")
    if r.status_code == 200:
        for tester in r.json().get("data", []):
            attrs = tester.get("attributes", {})
            t_email = (attrs.get("email") or "").strip().lower()
            if t_email == owner_email.lower():
                tester_id = tester["id"]
                added_to_internal_already = True
                print(f"   ✅ Already in internal group: {tester_id}")
                break

# Check for TEAM_MEMBER betaTester
if not tester_id:
    r = requests.get(
        f"{BASE}/v1/betaTesters?filter[email]={owner_email}&filter[inviteType]=TEAM_MEMBER",
        headers=h()
    )
    if r.status_code == 200:
        data = r.json().get("data", [])
        if data:
            tester_id = data[0]["id"]
            print(f"   ✅ TEAM_MEMBER betaTester found: {tester_id}")

# One-shot: POST /v1/betaTesters with internal group relationship
if not tester_id and internal_group_id:
    print("   ℹ️  No TEAM_MEMBER betaTester found — trying one-shot creation...")
    first = owner_name.split()[0] if owner_name else "Owner"
    last  = " ".join(owner_name.split()[1:]) if len(owner_name.split()) > 1 else "User"
    r_shot = requests.post(
        f"{BASE}/v1/betaTesters",
        headers=h(),
        json={"data": {
            "type": "betaTesters",
            "attributes": {"email": owner_email, "firstName": first, "lastName": last},
            "relationships": {
                "betaGroups": {"data": [{"type": "betaGroups", "id": internal_group_id}]}
            }
        }}
    )
    print(f"   One-shot HTTP {r_shot.status_code} | {r_shot.text[:500]}")
    if r_shot.status_code in (200, 201):
        shot_data = r_shot.json().get("data", {})
        shot_id   = shot_data.get("id", "")
        shot_type = shot_data.get("attributes", {}).get("inviteType", "")
        print(f"   betaTester {shot_id!r} created — inviteType={shot_type!r}")
        if shot_id:
            tester_id = shot_id
            time.sleep(3)
            r_verify = requests.get(
                f"{BASE}/v1/betaGroups/{internal_group_id}/betaTesters?limit=200",
                headers=h()
            )
            member_count = len(r_verify.json().get("data", [])) if r_verify.status_code == 200 else "?"
            print(f"   Group verify → HTTP {r_verify.status_code} | {member_count} members")
            if r_verify.status_code == 200:
                for member in r_verify.json().get("data", []):
                    if member.get("id") == shot_id:
                        print("   ✅ One-shot confirmed: betaTester IS in the internal group!")
                        added_to_internal_already = True
                        break
            if not added_to_internal_already and shot_type == "TEAM_MEMBER":
                added_to_internal_already = True
    elif r_shot.status_code == 409:
        r_rft = requests.get(
            f"{BASE}/v1/betaTesters?filter[email]={owner_email}",
            headers=h()
        )
        print(f"   Refetch after 409 → HTTP {r_rft.status_code} | {r_rft.text[:300]}")
        if r_rft.status_code == 200:
            for bt in r_rft.json().get("data", []):
                bt_type = bt.get("attributes", {}).get("inviteType", "")
                if bt_type == "TEAM_MEMBER":
                    tester_id = bt["id"]
                    print(f"   ✅ TEAM_MEMBER found after 409: {tester_id}")
                    break
            if not tester_id and r_rft.json().get("data"):
                tester_id = r_rft.json()["data"][0]["id"]
                print(f"   ℹ️  Using fallback betaTester: {tester_id}")

if tester_id:
    print(f"   ✅ tester_id confirmed: {tester_id} | already_in_internal={added_to_internal_already}")
else:
    print("   ⚠️ Could not resolve tester_id — will skip group assignment")
print()

print("🔗 Step 6: Retrieving public TestFlight link...")
public_testflight_link = None
r = requests.get(f"{BASE}/v1/betaGroups/{external_group_id}", headers=h())
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
        f"{BASE}/v1/builds?filter[app]={app_id}&sort=-uploadedDate&limit=1",
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
    f"{BASE}/v1/builds/{build_id}",
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
    f"{BASE}/v1/betaBuildLocalizations",
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
            f"{BASE}/v1/betaGroups/{internal_group_id}/relationships/builds",
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
        f"{BASE}/v1/betaGroups/{external_group_id}/relationships/builds",
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
if tester_id:
    print("🧪 Step 5b: Adding tester to groups (build now in both groups)...")
    print()

    if internal_group_id:
        if added_to_internal_already:
            print("   ✅ Tester already confirmed in INTERNAL group (added in Step 5)")
        else:
            print("   📦 Adding tester to INTERNAL group...")
            added_to_internal = False
            for int_attempt in range(5):
                r = requests.post(
                    f"{BASE}/v1/betaGroups/{internal_group_id}/relationships/betaTesters",
                    headers=h(),
                    json={"data": [{"type": "betaTesters", "id": tester_id}]}
                )
                print(f"   Internal group attempt {int_attempt+1}: HTTP {r.status_code} | {r.text[:300]}")
                if r.status_code in (200, 204):
                    print("   ✅ Tester added to INTERNAL group — instant access, no review needed!")
                    added_to_internal = True
                    break
                elif r.status_code == 409:
                    if "STATE_ERROR" in r.text or "cannot be assigned" in r.text:
                        print(f"   ⏳ STATE_ERROR — retrying in 20s (attempt {int_attempt+1}/5)...")
                        time.sleep(20)
                        continue
                    else:
                        print("   ✅ Tester already in INTERNAL group — instant access, no review needed!")
                        added_to_internal = True
                        break
                elif r.status_code in (403, 422):
                    if int_attempt < 4:
                        print(f"   ⏳ HTTP {r.status_code} — retrying in 20s...")
                        time.sleep(20)
                    else:
                        print(f"   ⚠️ User not yet a team member after {int_attempt+1} attempts")
                else:
                    print(f"   ⚠️ Unexpected error (HTTP {r.status_code}): {r.text[:200]}")
                    break
            if not added_to_internal:
                print("   ⚠️ Could not add to INTERNAL group — user must accept App Store Connect invitation first")
    else:
        print("   ⚠️ No internal group ID — skipping internal group assignment")
    print()

    print("   📦 Adding tester to EXTERNAL group...")
    external_added = False
    for ext_attempt in range(3):
        r = requests.post(
            f"{BASE}/v1/betaGroups/{external_group_id}/relationships/betaTesters",
            headers=h(),
            json={"data": [{"type": "betaTesters", "id": tester_id}]}
        )
        print(f"   External group HTTP: {r.status_code} | {r.text[:300]}")
        if r.status_code in (200, 204):
            print("   ✅ Tester added to EXTERNAL group")
            external_added = True
            break
        elif r.status_code == 409:
            if "STATE_ERROR" in r.text or "cannot be assigned" in r.text:
                print(f"   ⏳ STATE_ERROR on external group — deleting conflicting EMAIL betaTesters...")
                r_em = requests.get(
                    f"{BASE}/v1/betaTesters?filter[email]={owner_email}&filter[inviteType]=EMAIL",
                    headers=h()
                )
                if r_em.status_code == 200:
                    for bt in r_em.json().get("data", []):
                        btid = bt["id"]
                        if btid != tester_id:
                            print(f"   🗑️  Deleting conflicting betaTester {btid}...")
                            rd = requests.delete(f"{BASE}/v1/betaTesters/{btid}", headers=h())
                            print(f"       DELETE HTTP {rd.status_code}")
                time.sleep(10)
                first = owner_name.split()[0] if owner_name else "Owner"
                last  = " ".join(owner_name.split()[1:]) if len(owner_name.split()) > 1 else "User"
                r_ext = requests.post(
                    f"{BASE}/v1/betaTesters",
                    headers=h(),
                    json={"data": {
                        "type": "betaTesters",
                        "attributes": {"email": owner_email, "firstName": first, "lastName": last},
                        "relationships": {
                            "betaGroups": {"data": [{"type": "betaGroups", "id": external_group_id}]}
                        }
                    }}
                )
                print(f"   External one-shot HTTP {r_ext.status_code} | {r_ext.text[:300]}")
                if r_ext.status_code in (200, 201):
                    time.sleep(3)
                    r_ev = requests.get(
                        f"{BASE}/v1/betaGroups/{external_group_id}/betaTesters?limit=200",
                        headers=h()
                    )
                    if r_ev.status_code == 200:
                        for member in r_ev.json().get("data", []):
                            m_email = (member.get("attributes", {}).get("email") or "").strip().lower()
                            if m_email == owner_email.lower():
                                print("   ✅ One-shot confirmed: tester in external group!")
                                external_added = True
                                break
                elif r_ext.status_code == 409:
                    print("   ✅ Tester already in external group (409)")
                    external_added = True
                if not external_added:
                    time.sleep(20)
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

print("📝 Step 11.5: Ensuring beta app description and feedback email are set...")
r = requests.get(
    f"{BASE}/v1/betaAppLocalizations?filter[app]={app_id}",
    headers=h()
)
if r.status_code == 200 and r.json().get("data"):
    loc_id = r.json()["data"][0]["id"]
    existing_attrs = r.json()["data"][0].get("attributes", {})
    print(f"   Existing localization {loc_id}: desc={bool((existing_attrs.get('description') or '').strip())} feedbackEmail={bool((existing_attrs.get('feedbackEmail') or '').strip())}")
    # Always PATCH to ensure both description and feedbackEmail are set
    r_p = requests.patch(
        f"{BASE}/v1/betaAppLocalizations/{loc_id}",
        headers=h(),
        json={"data": {
            "type": "betaAppLocalizations",
            "id": loc_id,
            "attributes": {"description": beta_description, "feedbackEmail": feedback_email}
        }}
    )
    print(f"   PATCH HTTP: {r_p.status_code}")
    if r_p.status_code == 200:
        print("   ✅ Beta app description + feedbackEmail updated")
    else:
        print(f"   ⚠️ PATCH failed: {r_p.text[:300]}")
else:
    r_c = requests.post(
        f"{BASE}/v1/betaAppLocalizations",
        headers=h(),
        json={"data": {
            "type": "betaAppLocalizations",
            "attributes": {"locale": "en-US", "description": beta_description, "feedbackEmail": feedback_email},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}
        }}
    )
    print(f"   POST HTTP: {r_c.status_code}")
    if r_c.status_code in (200, 201):
        print("   ✅ Beta app description created")
    elif r_c.status_code == 409:
        # Already exists but wasn't found by filter — try to fetch and patch
        r2 = requests.get(f"{BASE}/v1/betaAppLocalizations?filter[app]={app_id}", headers=h())
        if r2.status_code == 200 and r2.json().get("data"):
            loc_id2 = r2.json()["data"][0]["id"]
            r_p2 = requests.patch(
                f"{BASE}/v1/betaAppLocalizations/{loc_id2}",
                headers=h(),
                json={"data": {
                    "type": "betaAppLocalizations",
                    "id": loc_id2,
                    "attributes": {"description": beta_description, "feedbackEmail": feedback_email}
                }}
            )
            print(f"   PATCH after 409 HTTP: {r_p2.status_code}")
            if r_p2.status_code == 200:
                print("   ✅ Beta app description updated after 409")
        else:
            print("   ✅ Beta app description already exists (409)")
    else:
        print(f"   ⚠️ Could not create description: {r_c.text[:300]}")
print()

print("📝 Step 11.6: Ensuring beta app review detail is set...")
first = owner_name.split()[0] if owner_name else "Owner"
last  = " ".join(owner_name.split()[1:]) if len(owner_name.split()) > 1 else "User"
r = requests.get(f"{BASE}/v1/apps/{app_id}/betaAppReviewDetail", headers=h())
print(f"   GET betaAppReviewDetail HTTP: {r.status_code}")
if r.status_code == 200:
    detail_id = r.json()["data"]["id"]
    r_p = requests.patch(
        f"{BASE}/v1/betaAppReviewDetails/{detail_id}",
        headers=h(),
        json={"data": {
            "type": "betaAppReviewDetails",
            "id": detail_id,
            "attributes": {
                "contactFirstName": first,
                "contactLastName": last,
                "contactPhone": contact_phone,
                "contactEmail": feedback_email
            }
        }}
    )
    print(f"   PATCH betaAppReviewDetail HTTP: {r_p.status_code}")
    if r_p.status_code == 200:
        print("   ✅ Beta app review detail updated")
    else:
        print(f"   ⚠️ PATCH failed: {r_p.text[:300]}")
else:
    print(f"   ⚠️ Could not fetch betaAppReviewDetail: {r.text[:200]}")
print()

print("📋 Step 12: Submitting for Beta App Review...")
review_submitted = False
# Wait for Apple to propagate the betaAppLocalization update before submitting
time.sleep(8)
for review_attempt in range(4):
    r = requests.post(
        f"{BASE}/v1/betaAppReviewSubmissions",
        headers=h(),
        json={"data": {"type": "betaAppReviewSubmissions",
              "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}}
    )
    print(f"   Attempt {review_attempt+1}: HTTP {r.status_code} | {r.text[:600]}")
    if r.status_code in (200, 201, 409):
        print("   ✅ Submitted for Beta App Review")
        review_submitted = True
        break
    elif r.status_code == 422 and "betaAppLocalization" in r.text and review_attempt < 3:
        print(f"   ⏳ betaAppLocalization not yet visible — waiting 15s and retrying (attempt {review_attempt+1}/4)...")
        time.sleep(15)
        continue
    else:
        print(f"   ⚠️ Review submission issue: {r.text[:600]}")
        break

status = "SUBMITTED_FOR_REVIEW" if review_submitted else "BUILD_ADDED"
with open("testflight_status.txt", "w") as f:
    f.write(status)

print()
print("="*70)
print("🎉 HYBRID TESTING CONFIGURED!")
if public_testflight_link:
    print(f"🔗 {public_testflight_link}")
print("="*70)
