-----------------------------------------------------------------------------
-- |
-- License     :  BSD-3-Clause
-- Maintainer  :  Oleg Grenrus <oleg.grenrus@iki.fi>
--
-- The organization members API as described on
-- <http://developer.github.com/v3/orgs/members/>.
module GitHub.Endpoints.Organizations.Members (
    membersOfR,
    membersOfWithR,
    isMemberOfR,
    orgInvitationsR,
    addOrUpdateMembership',
    addOrUpdateMembershipR,
    removeMembership',
    removeMembershipR,
    module GitHub.Data,
    ) where

import GitHub.Data
import GitHub.Internal.Prelude
import Prelude ()

-- | All the users who are members of the specified organization.
--
-- See <https://developer.github.com/v3/orgs/members/#members-list>
membersOfR :: Name Organization -> FetchCount -> Request k (Vector SimpleUser)
membersOfR organization =
    pagedQuery ["orgs", toPathPart organization, "members"] []

-- | 'membersOfR' with filters.
--
-- See <https://developer.github.com/v3/orgs/members/#members-list>
membersOfWithR :: Name Organization -> OrgMemberFilter -> OrgMemberRole -> FetchCount -> Request k (Vector SimpleUser)
membersOfWithR org f r =
    pagedQuery ["orgs", toPathPart org, "members"] [("filter", Just f'), ("role", Just r')]
  where
    f' = case f of
        OrgMemberFilter2faDisabled -> "2fa_disabled"
        OrgMemberFilterAll         -> "all"
    r' = case r of
        OrgMemberRoleAll    -> "all"
        OrgMemberRoleAdmin  -> "admin"
        OrgMemberRoleMember -> "member"

-- | Check if a user is a member of an organization.
--
-- See <https://developer.github.com/v3/orgs/members/#check-membership>
isMemberOfR :: Name User -> Name Organization -> GenRequest 'MtStatus rw Bool
isMemberOfR user org =
    Query [ "orgs", toPathPart org, "members", toPathPart user ] []

-- | List pending organization invitations
--
-- See <https://developer.github.com/v3/orgs/members/#list-pending-organization-invitations>
orgInvitationsR :: Name Organization -> FetchCount -> Request 'RA (Vector Invitation)
orgInvitationsR org = pagedQuery ["orgs", toPathPart org, "invitations"] []

-- | Add or update organization membership
--
-- See <https://developer.github.com/v3/orgs/members/#add-or-update-organization-membership>
addOrUpdateMembership' :: Auth -> Name Organization -> Name User -> Bool -> IO (Either Error ())
addOrUpdateMembership' auth org user isAdmin =
    executeRequest auth $ addOrUpdateMembershipR org user isAdmin

addOrUpdateMembershipR :: Name Organization -> Name User -> Bool -> GenRequest 'MtStatus 'RW ()
addOrUpdateMembershipR org user isAdmin =
    Command Put path (if isAdmin then encode adminRole else mempty)
  where
    path = ["org", toPathPart org, "memberships", toPathPart user]
    adminRole = object ["role" .= ("admin" :: String)]

-- | Remove organization membership
--
-- See <https://developer.github.com/v3/orgs/members/#remove-organization-membership>
removeMembership' :: Auth -> Name Organization -> Name User -> IO (Either Error ())
removeMembership' auth org user = executeRequest auth $ removeMembershipR org user

removeMembershipR :: Name Organization -> Name User -> GenRequest 'MtStatus 'RW ()
removeMembershipR org user =
    Command Delete ["org", toPathPart org, "memberships", toPathPart user] mempty
