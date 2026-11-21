namespace Origo.Bifrost.Sustainability;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;

/// <summary>
/// Grants account balance reads, journal preview and the native table reads they require.
/// </summary>
permissionset 70009203 "BIFROST SustRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Read', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (lestur)';
    IncludedPermissionSets = "BIFROST Sustain ori";
    Permissions = codeunit "Sust Account Bal Impl ori" = X,
                  codeunit "Sust Preview Post Impl ori" = X,
                  codeunit "Sust Preview Runner ori" = X,
                  table "Sust Preview Access ori" = X,
                  tabledata "Sust Preview Access ori" = R,
                  tabledata "Sustainability Jnl. Template" = R,
                  tabledata "Sustainability Jnl. Batch" = R,
                  tabledata "Sustainability Jnl. Line" = R,
                  tabledata "Sustainability Ledger Entry" = R,
                  tabledata "Sustainability Value Entry" = R,
                  tabledata "Sustainability Account" = R,
                  tabledata "Sustain. Account Category" = R,
                  tabledata "Sustain. Account Subcategory" = R,
                  tabledata "Sustainability Setup" = R,
                  tabledata "Dimension Set Entry" = R,
                  tabledata "No. Series" = R,
                  tabledata "No. Series Line" = R;
}
