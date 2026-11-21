namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;

/// <summary>
/// Full Bifrost Sustainability role. In the scaffold it grants registration only; write message types add their grants here.
/// </summary>
permissionset 70009202 "BIFROST SustFull ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Full', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (fullt)';
    IncludedPermissionSets = "BIFROST SustRead ori";
    Permissions = codeunit "Sust Category Set Impl ori" = X,
                  table "Sust Category Access ori" = X,
                  tabledata "Sust Category Access ori" = RIMD,
                  tabledata "Sustain. Account Category" = RIM,
                  tabledata "Sustain. Account Subcategory" = RIM,
                  tabledata "Sustainability Setup" = R,
                  tabledata "Sustainability Account" = R,
                  tabledata "Sustainability Ledger Entry" = R,
                  tabledata "Sustainability Jnl. Line" = RM;
}
