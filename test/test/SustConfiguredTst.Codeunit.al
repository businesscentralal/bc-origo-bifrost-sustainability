namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost.Sustainability;
using System.TestLibraries.Utilities;

/// <summary>
/// Shared visibility check Sust Configured ori (#1, Gunnar's decision D5): a company uses Sustainability
/// when Sustainability Setup has an Emission Unit of Measure Code or at least one Sustainability Account exists.
/// The tests own their data; the test runner rolls every change back.
/// </summary>
codeunit 98002 "Sust Configured Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        UnitTok: Label 'KG', Locked = true;
        AccountNoTok: Label 'BFSUST98002', Locked = true;

    [Test]
    procedure Scenario_AC01_UnitOfMeasureOnly_IsConfigured()
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        // [GIVEN] Setup has an Emission Unit of Measure Code and there are no accounts
        SetEmissionUnit(UnitTok);
        DeleteAllAccounts();

        // [WHEN] The visibility check runs
        // [THEN] The company counts as configured
        Assert.IsTrue(Configured.IsConfigured(), 'An Emission Unit of Measure Code alone must make the types visible.');
    end;

    [Test]
    procedure Scenario_AC02_AccountOnly_IsConfigured()
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        // [GIVEN] Setup is blank and one Sustainability Account exists
        SetEmissionUnit('');
        DeleteAllAccounts();
        InsertAccount();

        // [WHEN] The visibility check runs
        // [THEN] The company counts as configured
        Assert.IsTrue(Configured.IsConfigured(), 'One Sustainability Account alone must make the types visible.');
    end;

    [Test]
    procedure Scenario_AC03_BlankSetupNoAccounts_IsNotConfigured()
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        // [GIVEN] The CRONUS default: the setup row exists with every field blank, and there are no accounts
        SetEmissionUnit('');
        DeleteAllAccounts();

        // [WHEN] The visibility check runs
        // [THEN] The company is not configured
        Assert.IsFalse(Configured.IsConfigured(), 'A blank setup row without accounts must keep the types hidden.');
    end;

    [Test]
    procedure Scenario_AC04_NoSetupRow_IsNotConfiguredWithoutError()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        Configured: Codeunit "Sust Configured ori";
    begin
        // [GIVEN] There is no Sustainability Setup row and no accounts
        SustainabilitySetup.DeleteAll(false);
        DeleteAllAccounts();

        // [WHEN] The visibility check runs
        // [THEN] It answers false and raises no error
        Assert.IsFalse(Configured.IsConfigured(), 'A missing setup row must keep the types hidden.');
    end;

    [Test]
    procedure Scenario_AC04_NoSetupRowWithAccount_IsConfigured()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        Configured: Codeunit "Sust Configured ori";
    begin
        // [GIVEN] Edge case: no setup row at all, but an account exists
        SustainabilitySetup.DeleteAll(false);
        DeleteAllAccounts();
        InsertAccount();

        // [WHEN] The visibility check runs
        // [THEN] The account alone still makes the company configured
        Assert.IsTrue(Configured.IsConfigured(), 'An account must count even when the setup row is missing.');
    end;

    [Test]
    procedure Scenario_AC01_ChangeShowsOnNextCall()
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        // [GIVEN] A configured company in this session
        SetEmissionUnit(UnitTok);
        DeleteAllAccounts();
        Assert.IsTrue(Configured.IsConfigured(), 'The unit must make the company configured.');

        // [WHEN] The unit is cleared in the same session
        SetEmissionUnit('');

        // [THEN] The next call answers false without a restart, and true again once an account is added
        Assert.IsFalse(Configured.IsConfigured(), 'Nothing may be cached: clearing the unit must hide the types on the next call.');
        InsertAccount();
        Assert.IsTrue(Configured.IsConfigured(), 'Adding an account must show the types on the next call.');
    end;

    local procedure SetEmissionUnit(UnitCode: Code[10])
    var
        SustainabilitySetup: Record "Sustainability Setup";
    begin
        if not SustainabilitySetup.Get() then begin
            SustainabilitySetup.Init();
            SustainabilitySetup.Insert(false);
        end;
        SustainabilitySetup."Emission Unit of Measure Code" := UnitCode;
        SustainabilitySetup.Modify(false);
    end;

    local procedure DeleteAllAccounts()
    var
        SustainabilityAccount: Record "Sustainability Account";
    begin
        SustainabilityAccount.DeleteAll(false);
    end;

    local procedure InsertAccount()
    var
        SustainabilityAccount: Record "Sustainability Account";
    begin
        SustainabilityAccount.Init();
        SustainabilityAccount."No." := AccountNoTok;
        SustainabilityAccount.Name := 'Bifrost visibility test account';
        SustainabilityAccount.Insert(false);
    end;
}
