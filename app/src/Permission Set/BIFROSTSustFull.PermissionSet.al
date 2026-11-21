namespace Origo.Bifrost.Sustainability;

/// <summary>
/// Full Bifrost Sustainability role. Grants the write message types and their permission markers.
/// Microsoft Sustainability data rights (for scorecards and goals: Sustainability Admin) stay with the Microsoft roles assigned to the user.
/// </summary>
permissionset 70009202 "BIFROST SustFull ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Full', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (fullt)';
    IncludedPermissionSets = "BIFROST SustRead ori";
    Permissions = codeunit "Sust Goal Set Impl ori" = X,
        table "Sust Goal Set Access ori" = X,
        tabledata "Sust Goal Set Access ori" = RIMD;
}
