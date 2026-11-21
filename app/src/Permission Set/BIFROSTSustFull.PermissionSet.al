namespace Origo.Bifrost.Sustainability;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Location;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Emission;
using Microsoft.Sustainability.Energy;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using System.Automation;
using System.Security.User;

/// <summary>
/// Full Bifrost Sustainability role. Includes the read and preview capabilities and grants write message types and their permission markers.
/// Microsoft Sustainability data rights for scorecards and goals (Sustainability Admin) stay with the Microsoft roles assigned to the user.
/// </summary>
permissionset 70009202 "BIFROST SustFull ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Full', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (fullt)';
    IncludedPermissionSets = "BIFROST Sustain ori", "BIFROST SustRead ori";
    Permissions = codeunit "Sust Goal Set Impl ori" = X,
                  table "Sust Goal Set Access ori" = X,
                  tabledata "Sust Goal Set Access ori" = RIMD,
                  codeunit "Sust Category Set Impl ori" = X,
                  table "Sust Category Access ori" = X,
                  tabledata "Sust Category Access ori" = RIMD,
                  table "Sust Jnl Create Cap ori" = X,
                  tabledata "Sust Jnl Create Cap ori" = R,
                  codeunit "Sust Jnl Create Impl ori" = X,
                  tabledata "Sustainability Jnl. Template" = R,
                  tabledata "Sustainability Jnl. Batch" = RIM,
                  tabledata "Sustainability Jnl. Line" = RIM,
                  tabledata "Sustainability Account" = R,
                  tabledata "Sustain. Account Category" = RIM,
                  tabledata "Sustain. Account Subcategory" = RIM,
                  tabledata "Sustainability Setup" = R,
                  tabledata "Sustainability Ledger Entry" = R,
                  tabledata "Sustainability Energy Source" = R,
                  tabledata "Emission Fee" = R,
                  tabledata "No. Series" = R,
                  tabledata "No. Series Line" = R,
                  tabledata "Country/Region" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Source Code" = R,
                  tabledata "Reason Code" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Value" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Dimension Set Entry" = RI,
                  tabledata "Dimension Set Tree Node" = RI,
                  tabledata "Approval Entry" = R,
                  tabledata "User Setup" = R;
}
