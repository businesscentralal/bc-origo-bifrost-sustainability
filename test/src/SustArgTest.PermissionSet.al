namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost;

/// <summary>
/// Lets a lowered permission test build a temporary message argument.
/// Foundation Read does not grant this table. It grants no sustainability data.
/// </summary>
permissionset 98023 "Sust Arg Test ori"
{
    Assignable = true;
    Caption = 'Scorecard argument fixture', Locked = true;
    Permissions = tabledata "Message Argument ori" = RIMD;
}
