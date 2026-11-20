namespace Origo.Bifrost.Sustainability;

/// <summary>
/// Read-only Bifrost Sustainability role. In the scaffold it grants registration only; read message types add their grants here.
/// </summary>
permissionset 70009203 "BIFROST SustRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability Read', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni (lestur)';
    IncludedPermissionSets = "BIFROST Sustain ori";
}
