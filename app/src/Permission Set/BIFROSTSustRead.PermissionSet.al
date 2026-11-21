namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Scorecard;

/// <summary>
/// Read-only Bifrost Sustainability role. Grants Sustainability.AccountBalance.Get and
/// Sustainability.Scorecard.Get, plus the native table reads those types calculate from.
/// Setup reads come from BIFROST Sustain ori.
/// </summary>
permissionset 70009203 "BIFROST SustRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Read', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (lestur)';
    IncludedPermissionSets = "BIFROST Sustain ori";
    Permissions = codeunit "Sust Account Bal Impl ori" = X,
        codeunit "Sust Scorecard Get Impl ori" = X,
        tabledata "Sustainability Account" = R,
        tabledata "Sustainability Goal" = R,
        tabledata "Sustainability Ledger Entry" = R,
        tabledata "Sustainability Scorecard" = R;
}
