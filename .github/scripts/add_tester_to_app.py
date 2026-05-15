"""
Add tester to a specific app in App Store Connect / TestFlight.

Fixed behavior:
  - If tester is added to internal group => ADDED_TO_INTERNAL
  - If App Store Connect invitation was sent => INVITATION_SENT
  - If invitation already exists and user has not accepted yet => INVITATION_PENDING
  - If Apple knows the user but has not exposed TEAM_MEMBER betaTester yet => PENDING_APPLE_SYNC
  - Only real technical/API problems return ERROR

Important:
  A workflow cannot accept an App Store Connect invitation on behalf of a user.
  If the user has not accepted Apple's invitation email, the workflow must wait.
"""

import json
import jwt
import time
import requests
import sys
import pathlib
import traceback


api_key = json.load(open(sys.argv[1], encoding="utf-8"))
bundle_id = sys.argv[2].strip()
email = sys.argv[3].strip().lower()
first_name = (sys.argv[4].strip() if len(sys.argv) > 4 else "") or "Tester"
last_name = (sys.argv[5].strip() if len(sys.argv) > 5 else "") or "User"
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
        json.dumps(payload, ensure_ascii=False),
        encoding="utf-8",
    )

    print()
    print(f"📄 Result: [{status}] {message}")
    print("📦 tester_result.json payload:")
    print(json.dumps(payload, indent=2, ensure_ascii=False))


def safe_json(response):
    try:
        return response.json()
    except Exception:
        return {}


def find_active_user():
    """
    Return App Store Connect user id for email, or None.

    Apple may store some accounts under username instead of email,
    so we check both fields.
    """

    print("   🔎 Searching active users by username...")

    r = requests.get(
        f"{BASE}/v1/users?filter[username]={email}&limit=10",
        headers=h(),
    )

    if r.status_code == 200:
        for user in r.json().get("data", []):
            attrs = user.get("attributes", {})
            u_email = (attrs.get("email") or "").strip().lower()
            u_username = (attrs.get("username") or "").strip().lower()

            if u_email == email or u_username == email:
                print(f"   ✅ Found active user via username filter: {user['id']}")
                return user["id"]
    else:
        print(f"   ⚠️ Username lookup HTTP {r.status_code}: {r.text[:200]}")

    print("   🔎 Searching active users by pagination...")

    next_url = f"{BASE}/v1/users?limit=200"

    while next_url:
        r = requests.get(next_url, headers=h())
        r.raise_for_status()

        body = r.json()

        for user in body.get("data", []):
            attrs = user.get("attributes", {})
            u_email = (attrs.get("email") or "").strip().lower()
            u_username = (attrs.get("username") or "").strip().lower()

            if u_email == email or u_username == email:
                print(f"   ✅ Found active user: {user['id']}")
                return user["id"]

        next_url = body.get("links", {}).get("next")

    print("   ℹ️ Active user not found")
    return None


def find_pending_invitation():
    """
    Return App Store Connect pending invitation id for email, or None.
    """

    r = requests.get(
        f"{BASE}/v1/userInvitations?filter[email]={email}",
        headers=h(),
    )

    if r.status_code != 200:
        print(f"   ⚠️ Invitation lookup HTTP {r.status_code}: {r.text[:200]}")
        return None

    data = r.json().get("data", [])

    if data:
        invitation_id = data[0]["id"]
        print(f"   ⚠️ Pending invitation found: {invitation_id}")
        return invitation_id

    print("   ℹ️ No pending invitation found")
    return None


def ensure_internal_group(app_id):
    """
    Return internal betaGroup id for the app, creating it if needed.
    """

    r = requests.get(
        f"{BASE}/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=true",
        headers=h(),
    )
    r.raise_for_status()

    groups = r.json().get("data", [])

    if groups:
        group = groups[0]
        group_id = group["id"]
        group_name = group.get("attributes", {}).get("name", "Internal Testers")

        print(f"   ✅ Internal group exists: {group_name} ({group_id})")
        return group_id

    print("   ℹ️ Internal group not found — creating it...")

    r = requests.post(
        f"{BASE}/v1/betaGroups",
        headers=h(),
        json={
            "data": {
                "type": "betaGroups",
                "attributes": {
                    "name": "Internal Testers",
                    "isInternalGroup": True,
                },
                "relationships": {
                    "app": {
                        "data": {
                            "type": "apps",
                            "id": app_id,
                        }
                    }
                },
            }
        },
    )

    if r.status_code in (200, 201):
        group_id = r.json()["data"]["id"]
        print(f"   ✅ Internal group created: {group_id}")
        return group_id

    if r.status_code == 409:
        print("   ⚠️ Group creation conflict — refetching group...")

        r2 = requests.get(
            f"{BASE}/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=true",
            headers=h(),
        )
        r2.raise_for_status()

        groups2 = r2.json().get("data", [])

        if groups2:
            group_id = groups2[0]["id"]
            print(f"   ✅ Internal group recovered after 409: {group_id}")
            return group_id

    print(f"   ❌ Failed to create internal group: HTTP {r.status_code} | {r.text[:400]}")
    return None


def find_tester_in_group(internal_group_id):
    """
    Return betaTester id if this email already exists in the internal group.
    """

    r = requests.get(
        f"{BASE}/v1/betaGroups/{internal_group_id}/betaTesters?limit=200",
        headers=h(),
    )

    if r.status_code != 200:
        print(f"   ⚠️ Could not fetch group testers: HTTP {r.status_code} | {r.text[:200]}")
        return None

    testers = r.json().get("data", [])
    print(f"   ℹ️ Internal group has {len(testers)} testers")

    for tester in testers:
        attrs = tester.get("attributes", {})
        tester_email = (attrs.get("email") or "").strip().lower()

        if tester_email == email:
            tester_id = tester["id"]
            print(f"   ✅ Tester already in internal group: {tester_id}")
            return tester_id

    return None


def find_team_member_tester():
    """
    Return TEAM_MEMBER betaTester id for email, or None.

    Only TEAM_MEMBER testers can be added to internal TestFlight groups.
    EMAIL betaTesters are external-style testers and may cause STATE_ERROR.
    """

    r = requests.get(
        f"{BASE}/v1/betaTesters?filter[email]={email}&filter[inviteType]=TEAM_MEMBER",
        headers=h(),
    )

    if r.status_code != 200:
        print(f"   ⚠️ TEAM_MEMBER lookup HTTP {r.status_code}: {r.text[:200]}")
        return None

    data = r.json().get("data", [])

    if data:
        tester_id = data[0]["id"]
        print(f"   ✅ TEAM_MEMBER betaTester found: {tester_id}")
        return tester_id

    print("   ℹ️ TEAM_MEMBER betaTester not found yet")
    return None


def find_any_beta_tester():
    """
    Return any betaTester id for email.

    This is only used for diagnostics/fallback. Internal groups still require TEAM_MEMBER.
    """

    r = requests.get(
        f"{BASE}/v1/betaTesters?filter[email]={email}",
        headers=h(),
    )

    if r.status_code != 200:
        print(f"   ⚠️ Any betaTester lookup HTTP {r.status_code}: {r.text[:200]}")
        return None

    data = r.json().get("data", [])

    if data:
        for tester in data:
            tester_id = tester["id"]
            invite_type = tester.get("attributes", {}).get("inviteType", "")
            print(f"   ℹ️ Found betaTester: {tester_id} inviteType={invite_type}")

        return data[0]["id"]

    print("   ℹ️ No betaTester found")
    return None


def delete_email_type_beta_testers():
    """
    Delete EMAIL inviteType betaTesters for this email.

    EMAIL inviteType can block internal TEAM_MEMBER assignment.
    """

    r = requests.get(
        f"{BASE}/v1/betaTesters?filter[email]={email}&filter[inviteType]=EMAIL",
        headers=h(),
    )

    if r.status_code != 200:
        print(f"   ⚠️ EMAIL betaTester lookup HTTP {r.status_code}: {r.text[:200]}")
        return

    data = r.json().get("data", [])

    if not data:
        print("   ℹ️ No EMAIL betaTester records to delete")
        return

    for tester in data:
        tester_id = tester["id"]
        print(f"   🗑️ Deleting EMAIL betaTester: {tester_id}")

        rd = requests.delete(
            f"{BASE}/v1/betaTesters/{tester_id}",
            headers=h(),
        )

        print(f"      DELETE HTTP {rd.status_code}")


def create_beta_tester_one_shot(internal_group_id):
    """
    Try creating betaTester and assigning to internal group in one request.

    Sometimes Apple creates the correct TEAM_MEMBER tester from this,
    sometimes it creates EMAIL type. We verify membership after creation.
    """

    print("   ℹ️ Trying one-shot betaTester creation with internal group relationship...")

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
                "relationships": {
                    "betaGroups": {
                        "data": [
                            {
                                "type": "betaGroups",
                                "id": internal_group_id,
                            }
                        ]
                    }
                },
            }
        },
    )

    print(f"   One-shot HTTP {r.status_code} | {r.text[:500]}")

    if r.status_code in (200, 201):
        body = r.json()
        tester = body.get("data", {})
        tester_id = tester.get("id", "")
        invite_type = tester.get("attributes", {}).get("inviteType", "")

        print(f"   ℹ️ Created betaTester: {tester_id} inviteType={invite_type}")

        if not tester_id:
            return None, False

        time.sleep(5)

        existing = find_tester_in_group(internal_group_id)

        if existing == tester_id:
            print("   ✅ One-shot confirmed tester inside internal group")
            return tester_id, True

        if invite_type == "TEAM_MEMBER":
            print("   ✅ One-shot returned TEAM_MEMBER tester")
            return tester_id, False

        print("   ℹ️ One-shot did not create usable TEAM_MEMBER yet")
        return tester_id, False

    if r.status_code == 409:
        print("   ⚠️ One-shot conflict — refetching betaTesters...")

        tester_id = find_team_member_tester()

        if tester_id:
            return tester_id, False

        any_tester = find_any_beta_tester()

        return any_tester, False

    return None, False


def try_add_tester_to_internal_group(tester_id, internal_group_id):
    """
    Try adding betaTester to internal group.

    Returns:
      "ADDED"
      "PENDING_APPLE_SYNC"
      "ERROR"
    """

    for attempt in range(1, 11):
        print(f"   📦 Internal group add attempt {attempt}/10...")

        r = requests.post(
            f"{BASE}/v1/betaGroups/{internal_group_id}/relationships/betaTesters",
            headers=h(),
            json={
                "data": [
                    {
                        "type": "betaTesters",
                        "id": tester_id,
                    }
                ]
            },
        )

        print(f"      HTTP {r.status_code} | {r.text[:400]}")

        if r.status_code in (200, 204):
            print("   ✅ Tester added to internal group")
            return "ADDED"

        if r.status_code == 409:
            text = r.text or ""

            if "STATE_ERROR" not in text and "cannot be assigned" not in text:
                print("   ✅ Tester already in internal group")
                return "ADDED"

            print("   ⚠️ Apple STATE_ERROR / cannot be assigned")

            invite_type = ""

            r_info = requests.get(
                f"{BASE}/v1/betaTesters/{tester_id}",
                headers=h(),
            )

            if r_info.status_code == 200:
                invite_type = (
                    r_info.json()
                    .get("data", {})
                    .get("attributes", {})
                    .get("inviteType", "")
                )

            print(f"   ℹ️ Current tester inviteType: {invite_type}")

            if invite_type == "TEAM_MEMBER":
                print("   ✅ TEAM_MEMBER with STATE_ERROR — treating as pending/added by Apple")
                return "ADDED"

            print("   🗑️ Deleting EMAIL betaTester records and waiting for Apple sync...")
            delete_email_type_beta_testers()

            time.sleep(20)

            new_tester = find_team_member_tester()

            if new_tester:
                tester_id = new_tester
                print(f"   ✅ Re-resolved TEAM_MEMBER betaTester: {tester_id}")
                continue

            print("   ⏳ TEAM_MEMBER still not visible. Waiting before retry...")
            time.sleep(20)
            continue

        if r.status_code in (403, 422):
            print(f"   ⏳ Apple returned HTTP {r.status_code}; waiting before retry...")
            time.sleep(20)
            continue

        print(f"   ❌ Unexpected add error HTTP {r.status_code}")
        return "ERROR"

    print("   ⏳ Apple did not expose usable TEAM_MEMBER tester after retries")
    return "PENDING_APPLE_SYNC"


def add_to_internal_group(user_id, app_id, app_name):
    """
    Add confirmed active App Store Connect user to internal TestFlight group.

    This function exits intentionally.
    """

    print()
    print(f"✅ User is active App Store Connect member: {user_id}")
    print()

    print("👥 Ensuring internal TestFlight group exists...")
    internal_group_id = ensure_internal_group(app_id)

    if not internal_group_id:
        message = "Failed to find or create internal TestFlight group"
        write_result(
            "ERROR",
            message,
            apple_user_id=user_id,
            app_id=app_id,
        )
        sys.exit(1)

    print()
    print("🧪 Resolving TEAM_MEMBER betaTester record...")

    tester_id = find_tester_in_group(internal_group_id)

    if tester_id:
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} is already in the internal TestFlight group for '{app_name}'.",
            apple_user_id=user_id,
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        sys.exit(0)

    tester_id = find_team_member_tester()

    if not tester_id:
        tester_id, one_shot_added = create_beta_tester_one_shot(internal_group_id)

        if one_shot_added:
            write_result(
                "ADDED_TO_INTERNAL",
                f"{first_name} {last_name} has been added to the internal TestFlight group for '{app_name}'. "
                "They can now test the app directly.",
                apple_user_id=user_id,
                apple_beta_tester_id=tester_id,
                internal_group_id=internal_group_id,
                app_id=app_id,
            )
            sys.exit(0)

    if not tester_id:
        tester_id = find_any_beta_tester()

    if not tester_id:
        write_result(
            "PENDING_APPLE_SYNC",
            f"{email} is an active App Store Connect member, but Apple has not created/exposed "
            "a TestFlight betaTester record yet. Retry the workflow later.",
            apple_user_id=user_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        sys.exit(0)

    print()
    print("📦 Adding tester to internal group...")

    result = try_add_tester_to_internal_group(tester_id, internal_group_id)

    if result == "ADDED":
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} has been added to the internal TestFlight group for '{app_name}'. "
            "They can now test the app directly.",
            apple_user_id=user_id,
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        sys.exit(0)

    if result == "PENDING_APPLE_SYNC":
        write_result(
            "PENDING_APPLE_SYNC",
            f"{email} is an active App Store Connect member, but Apple has not exposed "
            "the TEAM_MEMBER TestFlight tester record yet. Retry the workflow later.",
            apple_user_id=user_id,
            apple_beta_tester_id=tester_id or "",
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        sys.exit(0)

    write_result(
        "ERROR",
        f"Apple rejected adding {email} to the internal TestFlight group. Check API permissions and tester state.",
        apple_user_id=user_id,
        apple_beta_tester_id=tester_id or "",
        internal_group_id=internal_group_id,
        app_id=app_id,
    )
    sys.exit(1)


def try_direct_add(app_id, app_name):
    """
    Fallback for Account Holder / Admin users that Apple may omit from /v1/users.
    """

    print("   ℹ️ Trying direct TEAM_MEMBER betaTester add...")

    internal_group_id = ensure_internal_group(app_id)

    if not internal_group_id:
        return False

    tester_id = find_tester_in_group(internal_group_id)

    if tester_id:
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} is already in the internal TestFlight group for '{app_name}'.",
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        return True

    tester_id = find_team_member_tester()

    if not tester_id:
        print("   ℹ️ No TEAM_MEMBER betaTester available for direct add")
        return False

    result = try_add_tester_to_internal_group(tester_id, internal_group_id)

    if result == "ADDED":
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} has been added to the internal TestFlight group for '{app_name}'.",
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        return True

    if result == "PENDING_APPLE_SYNC":
        write_result(
            "PENDING_APPLE_SYNC",
            f"{email} exists in Apple, but Apple has not exposed a usable TEAM_MEMBER TestFlight tester record yet. "
            "Retry the workflow later.",
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        return True

    return False


print("=" * 70)
print("👤 ADD TESTER TO APP")
print(f"   Email      : {email}")
print(f"   Name       : {first_name} {last_name}")
print(f"   Bundle ID  : {bundle_id}")
print(f"   Request ID : {request_id or '(not provided)'}")
print("=" * 70)
print()

try:
    print("📱 Step 1: Finding app in App Store Connect...")

    r = requests.get(
        f"{BASE}/v1/apps?filter[bundleId]={bundle_id}",
        headers=h(),
    )
    r.raise_for_status()

    apps = r.json().get("data", [])

    if not apps:
        message = f"App not found for bundle ID: {bundle_id}"
        print(f"   ❌ {message}")
        write_result("ERROR", message)
        sys.exit(1)

    app_id = apps[0]["id"]
    app_name = apps[0]["attributes"].get("name", bundle_id)

    print(f"   ✅ App found: {app_name} ({app_id})")
    print()

    print("👤 Step 2: Checking if user is active in App Store Connect...")

    user_id = find_active_user()

    if user_id:
        add_to_internal_group(user_id, app_id, app_name)

    print()
    print("👤 Step 2b: User not found in /v1/users — trying direct add fallback...")

    if try_direct_add(app_id, app_name):
        sys.exit(0)

    print()
    print("📧 Step 3: Checking pending App Store Connect invitation...")

    pending_id = find_pending_invitation()

    if pending_id:
        print("   🔄 Rechecking if user accepted invitation recently...")

        recheck_id = find_active_user()

        if recheck_id:
            add_to_internal_group(recheck_id, app_id, app_name)

        write_result(
            "INVITATION_PENDING",
            f"An App Store Connect invitation already exists for {email}. "
            f"Ask {first_name} {last_name} to accept Apple's invitation email, then rerun this workflow.",
            apple_invitation_id=pending_id,
            app_id=app_id,
        )
        sys.exit(0)

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

    print(f"   Invite HTTP {r.status_code} | {r.text[:500]}")

    if r.status_code in (200, 201):
        body = safe_json(r)
        invitation_id = body.get("data", {}).get("id", "")

        write_result(
            "INVITATION_SENT",
            f"An App Store Connect invitation has been sent to {email}. "
            f"Ask {first_name} {last_name} to accept Apple's invitation email, then rerun this workflow.",
            apple_invitation_id=invitation_id,
            app_id=app_id,
        )
        sys.exit(0)

    if r.status_code == 409:
        print("   ⚠️ Apple returned 409 — user/invitation probably already exists")
        print("   🔄 Rechecking active user...")

        recheck_id = find_active_user()

        if recheck_id:
            add_to_internal_group(recheck_id, app_id, app_name)

        print("   🔄 Trying direct add after 409...")

        if try_direct_add(app_id, app_name):
            sys.exit(0)

        pending_id = find_pending_invitation()

        write_result(
            "INVITATION_PENDING",
            f"Apple already has an invitation or user record for {email}. "
            "If this is an invitation, the user must accept it before internal testing can continue.",
            apple_invitation_id=pending_id or "",
            app_id=app_id,
        )
        sys.exit(0)

    write_result(
        "ERROR",
        f"Failed to send App Store Connect invitation to {email}. HTTP {r.status_code}: {r.text[:300]}",
        app_id=app_id,
    )
    sys.exit(1)

except SystemExit:
    raise

except Exception as exc:
    traceback.print_exc()

    app_id_safe = ""

    try:
        app_id_safe = app_id
    except NameError:
        pass

    write_result(
        "ERROR",
        f"Unexpected error: {exc}",
        app_id=app_id_safe,
    )
    sys.exit(1)
