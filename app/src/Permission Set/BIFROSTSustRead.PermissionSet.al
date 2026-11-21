namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Posting;
using Microsoft.Sustainability.Scorecard;
using Microsoft.Sustainability.Setup;

/// <summary>
/// Grants read-only journal validation, account balance and scorecard calculation,
/// plus the native sustainability table reads those types require.
/// </summary>
permissionset 70009203 "BIFROST SustRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Read', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (lestur)';
    IncludedPermissionSets = "BIFROST Sustain ori";
    Permissions = codeunit "Sust Account Bal Impl ori" = X,
        codeunit "Sust Scorecard Get Impl ori" = X,
        codeunit "Sust Journal Check Impl ori" = X,
        codeunit "Sust Journal Check Runner ori" = X,
        codeunit "Sustainability Jnl.-Check" = X,
        table "Sust Journal Check Access ori" = X,
        tabledata "Sust Journal Check Access ori" = R,
        tabledata "Sustainability Jnl. Template" = R,
        tabledata "Sustainability Jnl. Batch" = R,
        tabledata "Sustainability Jnl. Line" = R,
        tabledata "Sustainability Setup" = R,
        tabledata "Sustainability Account" = R,
        tabledata "Sustainability Goal" = R,
        tabledata "Sustainability Scorecard" = R,
        tabledata "Sustainability Ledger Entry" = R,
        tabledata "Sustain. Account Category" = R,
        tabledata "Sustain. Account Subcategory" = R;
}
