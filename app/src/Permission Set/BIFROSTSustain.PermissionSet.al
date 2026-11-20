namespace Origo.Bifrost.Sustainability;

/// <summary>
/// Grants Bifrost Sustainability scaffold execution without access to Microsoft business data.
/// Message types add their own permissions here as they are built.
/// </summary>
permissionset 70009201 "BIFROST Sustain ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni';
    Permissions = codeunit "Sust Registration ori" = X;
}
