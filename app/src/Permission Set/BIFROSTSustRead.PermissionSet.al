namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Posting;
using Microsoft.Sustainability.Setup;

/// <summary>
/// Read-only Bifrost Sustainability role. In the scaffold it grants registration only; read message types add their grants here.
/// </summary>
permissionset 70009203 "BIFROST SustRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Read', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (lestur)';
    IncludedPermissionSets = "BIFROST Sustain ori";
    Permissions = codeunit "Sust Journal Check Impl ori" = X,
        codeunit "Sust Journal Check Runner ori" = X,
        codeunit "Sustainability Jnl.-Check" = X,
        table "Sust Journal Check Access ori" = X,
        tabledata "Sust Journal Check Access ori" = R,
        tabledata "Sustainability Jnl. Template" = R,
        tabledata "Sustainability Jnl. Batch" = R,
        tabledata "Sustainability Jnl. Line" = R,
        tabledata "Sustainability Setup" = R,
        tabledata "Sustainability Account" = R,
        tabledata "Sustain. Account Category" = R,
        tabledata "Sustain. Account Subcategory" = R;
}
