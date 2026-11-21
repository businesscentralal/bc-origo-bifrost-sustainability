namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>
/// Gives the Foundation Full role execute rights on this app's own objects, including the Sustainability.Goal.Set
/// write marker, so Full users see and run Goal.Set (#6).
/// Microsoft Sustainability table data is not added through this extension (AppSourceCop AS0110/AS0112):
/// role users read it with their own Business Central permissions, and the assignable
/// Bifrost Sustainability sets grant it directly.
/// </summary>
permissionsetextension 70009204 "Sust Full Role ori" extends "BIFROST Full ori"
{
    Permissions = codeunit "Sust Registration ori" = X,
        codeunit "Sust Configured ori" = X,
        codeunit "Sust Goal Set Impl ori" = X,
        table "Sust Goal Set Access ori" = X,
        tabledata "Sust Goal Set Access ori" = RIMD,
        codeunit "Sust Jnl Create Impl ori" = X,
        table "Sust Jnl Create Cap ori" = X,
        tabledata "Sust Jnl Create Cap ori" = R,
        codeunit "Sust Account Bal Impl ori" = X,
        codeunit "Sust Scorecard Get Impl ori" = X,
        codeunit "Sust Journal Check Impl ori" = X,
        codeunit "Sust Journal Check Runner ori" = X,
        table "Sust Journal Check Access ori" = X,
        tabledata "Sust Journal Check Access ori" = R;
}
