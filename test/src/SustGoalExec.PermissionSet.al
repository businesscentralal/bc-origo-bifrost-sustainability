namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost.Sustainability;

/// <summary>Lets the visibility test enter Goal.Set without granting its write marker or business data.</summary>
permissionset 98037 "Sust Goal Exec ori"
{
    Assignable = false;
    Permissions = codeunit "Sust Goal Set Impl ori" = X;
}
