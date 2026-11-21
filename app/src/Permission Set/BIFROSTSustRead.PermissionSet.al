namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;

/// <summary>
/// Grants read-only account balance calculation and native sustainability table reads.
/// </summary>
permissionset 70009203 "BIFROST SustRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Read', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (lestur)';
    IncludedPermissionSets = "BIFROST Sustain ori";
    Permissions = codeunit "Sust Account Bal Impl ori" = X,
        codeunit "Sust Emission Sum Impl ori" = X,
        table "Sust Emission Access ori" = X,
        tabledata "Sust Emission Access ori" = R,
        tabledata "Sustainability Account" = R,
        tabledata "Sustainability Ledger Entry" = R;
}
