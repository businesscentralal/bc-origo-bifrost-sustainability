namespace Origo.Bifrost.Sustainability;

/// <summary>
/// Full Bifrost Sustainability role. In the scaffold it grants registration only; write message types add their grants here.
/// </summary>
permissionset 70009202 "BIFROST SustFull ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Full', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (fullt)';
    IncludedPermissionSets = "BIFROST Sustain ori", "BIFROST SustRead ori";
}
