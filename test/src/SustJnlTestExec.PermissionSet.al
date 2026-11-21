namespace Origo.Bifrost.Sustainability.Test;

/// <summary>Test execution only; deliberately grants no business data or capability access.</summary>
permissionset 98043 "Sust Jnl Exec ori"
{
    Assignable = false;
    Permissions = codeunit "Sust Jnl Create Fixture ori" = X,
                  codeunit "Sust Jnl Create Perm Tst ori" = X;
}
