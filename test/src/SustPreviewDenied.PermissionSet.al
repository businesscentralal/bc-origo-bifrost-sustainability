namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost.Sustainability;

/// <summary>Allows invoking the preview implementation without its capability read permission.</summary>
permissionset 98051 "Sust Prev Denied ori"
{
    Assignable = false;
    Permissions = codeunit "Sust Preview Post Impl ori" = X;
}
