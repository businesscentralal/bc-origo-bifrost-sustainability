namespace Origo.Bifrost.Sustainability;

/// <summary>
/// Full Bifrost Sustainability role. Includes the read set. Write message types add their grants here.
/// </summary>
permissionset 70009202 "BIFROST SustFull ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Full', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (fullt)';
    IncludedPermissionSets = "BIFROST SustRead ori";
}
