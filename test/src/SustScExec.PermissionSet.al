namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost;
using Origo.Bifrost.Sustainability;

/// <summary>
/// Execute permission on the scorecard reader without read permission on sustainability tables.
/// Used to prove a caller without BIFROST SustRead ori is hidden and refused.
/// </summary>
permissionset 98022 "Sust Sc Exec ori"
{
    Assignable = true;
    Caption = 'Scorecard execute only', Locked = true;
    Permissions =
        codeunit "Sust Scorecard Get Impl ori" = X,
        tabledata "Message Argument ori" = RIMD;
}
