namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost.Sustainability;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Permission boundary of the shared visibility check (#1, AC05): a user who cannot read Sustainability Setup
/// or Sustainability Account gets false and no error, and the product base set grants exactly those reads.
/// </summary>
codeunit 98003 "Sust Configured Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    procedure Scenario_AC05_NoReadPermission_IsNotConfiguredWithoutError()
    var
        Configured: Codeunit "Sust Configured ori";
        Result: Boolean;
    begin
        // [GIVEN] A company that is configured both ways: a unit on setup and one account
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
        ConfigureBothWays();

        // [WHEN] A user without read permission on the two tables asks
        LowerPermissions.SetExactPermissionSet('Sust Setup Test ori');
        Result := Configured.IsConfigured();
        LowerPermissions.SetOutsideO365Scope();

        // [THEN] The answer is false and no error was raised
        Assert.IsFalse(Result, 'A user who cannot read the Sustainability tables must not see the types.');
    end;

    [Test]
    procedure Scenario_AC05_BaseSetGrantsTheReads()
    var
        Configured: Codeunit "Sust Configured ori";
        Result: Boolean;
    begin
        // [GIVEN] A configured company
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
        ConfigureBothWays();

        // [WHEN] A user with only the Bifrost Sustainability Read set asks
        LowerPermissions.SetExactPermissionSet('BIFROST SustRead ori');
        Result := Configured.IsConfigured();
        LowerPermissions.SetOutsideO365Scope();

        // [THEN] The product set grants the reads the check needs, so the types are visible
        Assert.IsTrue(Result, 'BIFROST SustRead ori must grant the reads the visibility check needs.');
    end;

    local procedure ConfigureBothWays()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
    begin
        if not SustainabilitySetup.Get() then begin
            SustainabilitySetup.Init();
            SustainabilitySetup.Insert(false);
        end;
        SustainabilitySetup."Emission Unit of Measure Code" := 'KG';
        SustainabilitySetup.Modify(false);
        SustainabilityAccount.Init();
        SustainabilityAccount."No." := 'BFSUST98003';
        SustainabilityAccount.Name := 'Bifrost permission test account';
        if SustainabilityAccount.Insert(false) then;
    end;
}
