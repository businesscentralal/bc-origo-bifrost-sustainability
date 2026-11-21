namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Utilities;

/// <summary>
/// Supplies only the platform buffer the dispatcher path needs in the restricted message-type tests.
/// Product permissions must come from the real product roles.
/// </summary>
permissionset 98011 "Sust Msg Test ori"
{
    Assignable = true;
    Caption = 'Message test platform', Locked = true;
    IncludedPermissionSets = "Sust Setup Test ori";
    Permissions = table "Name/Value Buffer" = X;
}
