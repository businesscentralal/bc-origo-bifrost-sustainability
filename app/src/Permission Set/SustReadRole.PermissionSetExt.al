namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>
/// Gives the Foundation Read role execute rights on this app's own objects.
/// Microsoft Sustainability table data is not added through this extension (AppSourceCop AS0110/AS0112):
/// role users read it with their own Business Central permissions, and the assignable
/// Bifrost Sustainability sets grant it directly.
/// </summary>
permissionsetextension 70009205 "Sust Read Role ori" extends "BIFROST Read ori"
{
    Permissions = codeunit "Sust Registration ori" = X,
        codeunit "Sust Configured ori" = X,
        codeunit "Sust Account Bal Impl ori" = X,
        codeunit "Sust Scorecard Get Impl ori" = X;
}
