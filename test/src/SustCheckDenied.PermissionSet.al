namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost.Sustainability;

/// <summary>Allows invoking the check implementation without its capability read permission.</summary>
permissionset 98046 "Sust Chk Denied ori"
{
    Assignable = false;
    Permissions = codeunit "Sust Journal Check Impl ori" = X;
}
