namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Setup;

/// <summary>
/// The shared visibility check of the Sustainability message types (Gunnar's decision D5, issue #1).
/// Sustainability counts as configured when the setup names an emission unit of measure or at least one
/// Sustainability Account exists. Hidden means roster-only: a caller that knows a type can still run it.
/// </summary>
codeunit 70009206 "Sust Configured ori"
{
    Access = Internal;
    InherentPermissions = X;

    /// <summary>Returns true when the company uses Microsoft Sustainability. Never raises an error.</summary>
    procedure IsConfigured(): Boolean
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
    begin
        if SustainabilitySetup.ReadPermission() then begin
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
