namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Setup;

/// <summary>
/// Shared visibility check for the Sustainability message types (Gunnar's decision D5, #1).
/// A company uses Sustainability when Sustainability Setup has an Emission Unit of Measure Code
/// or at least one Sustainability Account exists. The setup row Microsoft creates on install does not
/// count while that field is blank. Each call reads the tables again, so a change shows on the next call.
/// Hidden means roster-only: every type returns this from IsEnabled, and a caller that knows the type
/// can still run it. Blocking a type is done with Foundation's group settings.
/// </summary>
codeunit 70009206 "Sust Configured ori"
{
    Access = Internal;
    // Execute is inherent so discovery can always call this. The reads use the caller's own permission
    // (the base set BIFROST Sustain ori grants them); a caller who cannot read a table counts as
    // not configured, so listing the types never raises an error.
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>
    /// True when the current company has set up Sustainability: an Emission Unit of Measure Code on
    /// Sustainability Setup, or at least one Sustainability Account. Never raises an error.
    /// </summary>
    procedure IsConfigured(): Boolean
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
    begin
        // ReadPermission does not throw. A caller without a table skips that part of the rule,
        // so a caller who can read neither table stays "not configured".
        if SustainabilitySetup.ReadPermission() then begin
            SustainabilitySetup.ReadIsolation := IsolationLevel::ReadCommitted;
            SustainabilitySetup.SetLoadFields("Emission Unit of Measure Code");
            if SustainabilitySetup.Get() then
                if SustainabilitySetup."Emission Unit of Measure Code" <> '' then
                    exit(true);
        end;

        if not SustainabilityAccount.ReadPermission() then
            exit(false);
        SustainabilityAccount.ReadIsolation := IsolationLevel::ReadUncommitted;
        exit(not SustainabilityAccount.IsEmpty());
    end;
}
