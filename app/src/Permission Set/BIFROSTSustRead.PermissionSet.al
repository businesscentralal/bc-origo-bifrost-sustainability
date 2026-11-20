namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Scorecard;

/// <summary>
/// Read-only Bifrost Sustainability role. Grants Sustainability.Scorecard.Get and read access
/// to the scorecard, its goals and the ledger entries those goals calculate from.
/// Setup and account reads come from BIFROST Sustain ori.
/// </summary>
permissionset 70009203 "BIFROST SustRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Read', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (lestur)';
    IncludedPermissionSets = "BIFROST Sustain ori";
    Permissions = codeunit "Sust Scorecard Get Impl ori" = X,
        tabledata "Sustainability Scorecard" = R,
        tabledata "Sustainability Goal" = R,
        tabledata "Sustainability Ledger Entry" = R;
}
