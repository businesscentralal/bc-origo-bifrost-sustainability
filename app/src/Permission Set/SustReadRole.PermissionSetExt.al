namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>
/// Includes the matching Bifrost Sustainability permissions in the Foundation Read role.
/// </summary>
permissionsetextension 70009205 "Sust Read Role ori" extends "BIFROST Read ori"
{
    IncludedPermissionSets = "BIFROST SustRead ori";
}
