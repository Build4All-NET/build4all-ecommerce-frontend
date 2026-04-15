"""
Add tester to a specific app in App Store Connect / TestFlight.

Flow:
  1. Find the app by bundle ID.
  2. Check /v1/users — if the email is already an active team member,
     add them directly to the internal TestFlight group → ADDED_TO_INTERNAL.
  2b. /v1/users does NOT return the Account Holder or certain Admins.
     Fallback: attempt a direct betaTester add. If Apple accepts the group
     assignment they are a team member → ADDED_TO_INTERNAL.
  3. If not active, check for a pending /v1/userInvitations entry.
     - If one exists, re-check whether the user is now active (they may
       have just accepted the invite).
         If yes  → internal add flow → ADDED_TO_INTERNAL.
         If still not active → INVITATION_PENDING (no duplicate invite sent).
  4. No pending invite → send a fresh invitation → INVITATION_SENT.
  5. If Apple returns 409 on the invite call:
     a. Re-check /v1/users — if now active → ADDED_TO_INTERNAL.
     b. Try direct betaTester add (handles Account Holder / Admin) →
        if Apple accepts → ADDED_TO_INTERNAL.
     c. Otherwise → INVITATION_PENDING.

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
import traceback

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
    """Return the /v1/users id for `email`, or None.

    Apple stores the Account Holder (and some Admins) under the `username`
    attribute (their Apple ID) rather than `email`. We check both.
    We also try the filter[username] query first as a fast path.
    """
    # Fast path: filter by username (Apple ID) — finds Account Holders
    r = requests.get(
        f"{BASE}/v1/users?filter[username]={email}&limit=10",
        headers=h(),
    )
    if r.status_code == 200:
        for user in r.json().get("data", []):
            attrs = user.get("attributes", {})
            u_email    = (attrs.get("email")    or "").strip().lower()
            u_username = (attrs.get("username") or "").strip().lower()
            if u_email == email or u_username == email:
                print(f"   ✅ Found via username filter: {user['id']}")
                return user["id"]

    # Slow path: paginate all users checking both email and username attributes
    next_url = f"{BASE}/v1/users?limit=200"
    while next_url:
        r = requests.get(next_url, headers=h())
        r.raise_for_status()
        body = r.json()
        for user in body.get("data", []):
            attrs = user.get("attributes", {})
            u_email    = (attrs.get("email")    or "").strip().lower()
            u_username = (attrs.get("username") or "").strip().lower()
            if u_email == email or u_username == email:
                return user["id"]
        next_url = body.get("links", {}).get("next")
    return None


def find_team_member_tester():
    """Return the betaTester id for `email` with inviteType=TEAM_MEMBER, or None.

    TEAM_MEMBER betaTesters are the ones linked to actual App Store Connect team
    members. Only TEAM_MEMBER type can be added to internal TestFlight groups.
    EMAIL type betaTesters (created via POST /v1/betaTesters) give STATE_ERROR
    when added to internal groups.
    """
    r = requests.get(
        f"{BASE}/v1/betaTesters?filter[email]={email}&filter[inviteType]=TEAM_MEMBER",
        headers=h(),
    )
    if r.status_code == 200:
        data = r.json().get("data", [])
        if data:
            tid = data[0]["id"]
            print(f"   ✅ TEAM_MEMBER betaTester found: {tid}")
            return tid
    return None


def find_tester_via_user_relationship(user_id):
    """Return the betaTester ID linked to a /v1/users record (always TEAM_MEMBER type).

    The user relationship endpoint returns the TEAM_MEMBER betaTester regardless
    of whether it appears in filter[email] queries. This is the most reliable way
    to find the betaTester for Account Holders and Admins.
    """
    r = requests.get(f"{BASE}/v1/users/{user_id}/relationships/betaTesters", headers=h())
    print(f"   ℹ️  /v1/users/{user_id}/relationships/betaTesters → HTTP {r.status_code} | {r.text[:300]}")
    if r.status_code == 200:
        data = r.json().get("data", [])
        if data:
            tid = data[0]["id"]
            print(f"   ✅ TEAM_MEMBER betaTester via user relationship: {tid}")
            return tid
    # Non-relationship endpoint as fallback
    r2 = requests.get(f"{BASE}/v1/users/{user_id}/betaTesters", headers=h())
    print(f"   ℹ️  /v1/users/{user_id}/betaTesters → HTTP {r2.status_code} | {r2.text[:300]}")
    if r2.status_code == 200:
        data2 = r2.json().get("data", [])
        if data2:
            tid = data2[0]["id"]
            print(f"   ✅ TEAM_MEMBER betaTester via user betaTesters: {tid}")
            return tid
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

    # 409 means it was created between our GET and POST — re-fetch
    if r.status_code == 409:
        r2 = requests.get(
            f"{BASE}/v1/betaGroups?filter[app]={app_id}&filter[isInternalGroup]=true",
            headers=h(),
        )
        r2.raise_for_status()
        groups2 = r2.json().get("data", [])
        if groups2:
            gid = groups2[0]["id"]
            print(f"   ✅ Internal group (recovered after 409): '{groups2[0]['attributes']['name']}' ({gid})")
            return gid

    print(f"   ❌ Failed to create internal group: HTTP {r.status_code} | {r.text[:300]}")
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
            invite_type = data[0].get("attributes", {}).get("inviteType", "?")
            print(f"   ✅ betaTester found: {tid} (inviteType={invite_type})")
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

    print(f"   ❌ Failed to resolve betaTester: HTTP {r.status_code} | {r.text[:300]}")
    return None


def try_direct_add(app_id, app_name):
    """
    Attempt to add `email` to the internal group using their TEAM_MEMBER
    betaTester record, WITHOUT requiring /v1/users to list them first.

    This is the fallback for Account Holders and Admins omitted from /v1/users.
    IMPORTANT: only TEAM_MEMBER type betaTesters can be in internal groups.
    EMAIL type betaTesters (created via POST /v1/betaTesters) always get
    STATE_ERROR — so we never use them here.

    Returns True and writes ADDED_TO_INTERNAL on success.
    Returns False (writes nothing) so the caller falls through to invitation.
    """
    internal_group_id = ensure_internal_group(app_id)
    if not internal_group_id:
        return False

    # Only look for TEAM_MEMBER type — EMAIL type causes STATE_ERROR on internal groups
    tester_id = find_team_member_tester()
    if not tester_id:
        print("   ℹ️  No TEAM_MEMBER betaTester found — cannot add to internal group directly")
        return False

    r = requests.post(
        f"{BASE}/v1/betaGroups/{internal_group_id}/relationships/betaTesters",
        headers=h(),
        json={"data": [{"type": "betaTesters", "id": tester_id}]},
    )
    print(f"   Direct-add attempt: HTTP {r.status_code} | {r.text[:200]}")

    if r.status_code in (200, 204):
        print("   ✅ Direct add successful — user added to INTERNAL group!")
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} has been added to the internal TestFlight group for '{app_name}'. "
            "They can now test the app directly — no Apple review required.",
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        return True

    if r.status_code == 409 and "STATE_ERROR" not in r.text and "cannot be assigned" not in r.text:
        print("   ✅ User already in INTERNAL group!")
        write_result(
            "ADDED_TO_INTERNAL",
            f"{first_name} {last_name} is already in the internal TestFlight group for '{app_name}'. "
            "They can test the app directly — no Apple review required.",
            apple_beta_tester_id=tester_id,
            internal_group_id=internal_group_id,
            app_id=app_id,
        )
        return True

    print(f"   ℹ️  Direct add declined by Apple (HTTP {r.status_code}) — continuing to invitation flow")
    return False


def add_to_internal_group(user_id, app_id, app_name):
    """
    Full internal-group flow for a confirmed /v1/users active member.
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
    # Prefer TEAM_MEMBER type — required for internal groups, avoids STATE_ERROR
    # Try via user relationship first (most reliable for Account Holders/Admins)
    tester_id = find_tester_via_user_relationship(user_id) or find_team_member_tester() or resolve_beta_tester()
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
                # Fetch the betaTester's inviteType to decide how to handle this.
                r_info = requests.get(f"{BASE}/v1/betaTesters/{tester_id}", headers=h())
                invite_type = ""
                if r_info.status_code == 200:
                    invite_type = (
                        r_info.json()
                        .get("data", {})
                        .get("attributes", {})
                        .get("inviteType", "")
                    )
                print(f"   ℹ️  STATE_ERROR | betaTester inviteType: {invite_type!r}")

                if invite_type == "TEAM_MEMBER":
                    # TEAM_MEMBER type + STATE_ERROR means the user is already
                    # pending in the internal group (waiting to accept TestFlight invite).
                    # Treat as success — they already have access.
                    print("   ✅ TEAM_MEMBER already pending in INTERNAL group — treating as added")
                    added = True
                    break

                # EMAIL type (or unknown) — this betaTester cannot be in an internal group.
                # Delete it and re-resolve using only TEAM_MEMBER sources.
                print("   🗑️  EMAIL-type betaTester is blocked from internal groups — deleting all EMAIL records...")
                r_em = requests.get(
                    f"{BASE}/v1/betaTesters?filter[email]={email}&filter[inviteType]=EMAIL",
                    headers=h(),
                )
                deleted_any = False
                if r_em.status_code == 200:
                    for bt in r_em.json().get("data", []):
                        btid = bt["id"]
                        print(f"   🗑️  Deleting EMAIL betaTester {btid}...")
                        rd = requests.delete(f"{BASE}/v1/betaTesters/{btid}", headers=h())
                        print(f"       DELETE HTTP {rd.status_code}")
                        deleted_any = True
                if deleted_any:
                    print("   ⏳ Waiting 10 s for Apple to process deletion...")
                    time.sleep(10)

                # Re-resolve — try all TEAM_MEMBER sources.
                # Do NOT fall back to resolve_beta_tester() which would recreate EMAIL type.
                new_tid = find_tester_via_user_relationship(user_id) or find_team_member_tester()

                # Last resort: plain filter[email] with no inviteType restriction.
                # A TEAM_MEMBER record may have been shadowed by the now-deleted EMAIL records.
                if not new_tid:
                    r_any = requests.get(
                        f"{BASE}/v1/betaTesters?filter[email]={email}",
                        headers=h(),
                    )
                    print(f"   ℹ️  Plain betaTesters filter[email] → HTTP {r_any.status_code} | {r_any.text[:300]}")
                    if r_any.status_code == 200:
                        remaining = r_any.json().get("data", [])
                        for bt in remaining:
                            bt_type = bt.get("attributes", {}).get("inviteType", "")
                            print(f"   ℹ️  Remaining betaTester {bt['id']} inviteType={bt_type!r}")
                            if bt_type == "TEAM_MEMBER":
                                new_tid = bt["id"]
                                print(f"   ✅ Surfaced TEAM_MEMBER betaTester: {new_tid}")
                                break

                if new_tid:
                    tester_id = new_tid
                    print(f"   ✅ Re-resolved to TEAM_MEMBER betaTester: {tester_id}")
                    # Continue retry loop with the new TEAM_MEMBER ID
                else:
                    # Final fallback: one-shot POST that creates the betaTester AND
                    # assigns it to the internal group in a single API call.
                    # For emails that match active team members Apple may create
                    # TEAM_MEMBER type automatically when the target group is internal.
                    print("   🔄 One-shot: POST /v1/betaTesters with internal group in relationships...")
                    r_shot = requests.post(
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
                                            {"type": "betaGroups", "id": internal_group_id}
                                        ]
                                    }
                                },
                            }
                        },
                    )
                    print(f"   One-shot HTTP {r_shot.status_code} | {r_shot.text[:500]}")

                    shot_new_tid = ""
                    if r_shot.status_code in (200, 201):
                        shot_data = r_shot.json().get("data", {})
                        shot_new_tid = shot_data.get("id", "")
                        shot_type   = shot_data.get("attributes", {}).get("inviteType", "")
                        print(f"   Created betaTester {shot_new_tid!r} inviteType={shot_type!r}")
                        if shot_type == "TEAM_MEMBER" and shot_new_tid:
                            # Apple added them to the group directly — treat as success.
                            added       = True
                            tester_id   = shot_new_tid
                            break
                        elif shot_new_tid:
                            # EMAIL type created — will retry group-add in next iteration.
                            tester_id = shot_new_tid
                    elif r_shot.status_code == 409:
                        # betaTester already exists (possibly TEAM_MEMBER created by Apple).
                        r_rft = requests.get(
                            f"{BASE}/v1/betaTesters?filter[email]={email}", headers=h()
                        )
                        print(f"   Re-fetch after 409 → HTTP {r_rft.status_code} | {r_rft.text[:300]}")
                        if r_rft.status_code == 200:
                            for bt in r_rft.json().get("data", []):
                                bt_type = bt.get("attributes", {}).get("inviteType", "")
                                if bt_type == "TEAM_MEMBER":
                                    shot_new_tid = bt["id"]
                                    tester_id    = shot_new_tid
                                    print(f"   ✅ TEAM_MEMBER surfaced after 409: {tester_id}")
                                    break

                    if not shot_new_tid and not added:
                        print("   ❌ All approaches exhausted — no TEAM_MEMBER betaTester obtainable.")
                        print("      Add this team member to the internal group once via the")
                        print("      App Store Connect portal; subsequent runs will work automatically.")
                        break
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

try:

    # ── Step 1: Find app ──────────────────────────────────────────────────────
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

    # ── Step 2: Check /v1/users ───────────────────────────────────────────────
    print("👤 Step 2: Checking if user is active in /v1/users...")
    user_id = find_active_user()

    if user_id:
        print(f"   ✅ User found in /v1/users ({user_id}) — skipping invitation")
        add_to_internal_group(user_id, app_id, app_name)   # exits

    # ── Step 2b: /v1/users fallback — handles Account Holder / Admin ──────────
    # Apple does NOT return the Account Holder (and some Admins) via /v1/users.
    # Attempt a direct betaTester add: if Apple accepts, they are a team member.
    print("   ℹ️  Not found in /v1/users — trying direct betaTester add")
    print("       (Account Holders and some Admins are omitted from /v1/users)")
    if try_direct_add(app_id, app_name):
        sys.exit(0)

    # ── Step 3: Not active — check for an existing pending invitation ─────────
    print()
    print("📧 Step 3: Checking for existing pending invitation...")

    pending_id = find_pending_invitation()
    if pending_id:
        print(f"   ⚠️  Pending invitation found ({pending_id})")
        print("   🔄 Re-checking whether user has since become active...")
        recheck_id = find_active_user()
        if recheck_id:
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

    # ── Step 4: No pending invite — send a fresh invitation ───────────────────
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
        sys.exit(0)

    elif r.status_code == 409:
        # Apple knows this address — could be Account Holder, existing team member,
        # or an address with a pending invitation.
        print("   ⚠️  409 from Apple — re-checking /v1/users...")
        recheck_id = find_active_user()
        if recheck_id:
            print("   ✅ User is now active — proceeding to internal add flow")
            add_to_internal_group(recheck_id, app_id, app_name)   # exits

        # Still not in /v1/users — try direct betaTester add
        # (covers Account Holders and Admins Apple knows but doesn't list)
        print("   ℹ️  Still not in /v1/users — trying direct betaTester add after 409...")
        if try_direct_add(app_id, app_name):
            sys.exit(0)

        # Direct add also declined — look up any pending invitation
        pending_id = find_pending_invitation()
        print("   ℹ️  User still not reachable — returning INVITATION_PENDING")
        write_result(
            "INVITATION_PENDING",
            f"An invitation already exists for {email} in App Store Connect. "
            f"Please ask {first_name} {last_name} to check their email and accept the Apple invitation, "
            "then re-run this workflow to add them to the internal testing group.",
            apple_invitation_id=pending_id or "",
            app_id=app_id,
        )
        sys.exit(0)

    else:
        print(f"   ❌ Failed to send invitation (HTTP {r.status_code})")
        write_result(
            "ERROR",
            f"Failed to send App Store Connect invitation to {email} (HTTP {r.status_code}). "
            "Please check the email address and try again.",
            app_id=app_id,
        )
        sys.exit(1)

except SystemExit:
    raise   # preserve intentional exit codes

except Exception as exc:
    traceback.print_exc()
    app_id_safe = ""
    try:
        app_id_safe = app_id  # type: ignore[name-defined]
    except NameError:
        pass
    write_result(
        "ERROR",
        f"Unexpected error: {exc}",
        app_id=app_id_safe,
    )
    sys.exit(1)
