namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Setup;

/// <summary>
/// Grants Bifrost Sustainability execution and the reads the shared visibility check needs
/// (Sustainability Setup and Sustainability Account). Message types add their own permissions here as they are built.
/// </summary>
permissionset 70009201 "BIFROST Sustain ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost Sustainability', MaxLength = 30, Comment = 'is-IS=Bifröst - sjálfbærni';
    Permissions = codeunit "Sust Registration ori" = X,
        codeunit "Sust Configured ori" = X,
        tabledata "Sustainability Setup" = R,
        tabledata "Sustainability Account" = R;
}
