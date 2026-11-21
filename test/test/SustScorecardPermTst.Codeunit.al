namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Scorecard;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using Origo.Bifrost.Sustainability;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Amended AC-P for Sustainability.Scorecard.Get (Architect ruling on #18, 20.11.2026).
/// Foundation Read and Full grant execution. Native scorecard, goal and ledger reads come from
/// BIFROST SustRead ori assigned alongside. Without those reads the type is hidden and the call
/// returns PermissionDenied.
/// </summary>
codeunit 98021 "Sust Scorecard Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Foundation Read alone cannot read native sustainability tables, in English.</summary>
    [Test]
    procedure Scenario_ACP_ReadAlone1033()
    begin
        VerifyFoundationRole('BIFROST Read ori', false, 1033);
    end;

    /// <summary>Foundation Read alone cannot read native sustainability tables, in Icelandic.</summary>
    [Test]
    procedure Scenario_ACP_ReadAlone1039()
    begin
        VerifyFoundationRole('BIFROST Read ori', false, 1039);
    end;

    /// <summary>Foundation Full alone does not grant native sustainability reads either.</summary>
    [Test]
    procedure Scenario_ACP_FullAlone1033()
    begin
        VerifyFoundationRole('BIFROST Full ori', false, 1033);
    end;

    /// <summary>Foundation Read plus BIFROST SustRead ori reads a scorecard and grants no writes, in English.</summary>
    [Test]
    procedure Scenario_ACP_ReadPlusSustRead1033()
    begin
        VerifyFoundationRole('BIFROST Read ori', true, 1033);
    end;

    /// <summary>Foundation Read plus BIFROST SustRead ori reads a scorecard and grants no writes, in Icelandic.</summary>
    [Test]
    procedure Scenario_ACP_ReadPlusSustRead1039()
    begin
        VerifyFoundationRole('BIFROST Read ori', true, 1039);
    end;

    /// <summary>Codeunit execute without BIFROST SustRead ori is hidden and returns PermissionDenied.</summary>
    [Test]
    procedure Scenario_ACP_ExecuteOnly_Refuses()
    var
        SustainabilityScorecard: Record "Sustainability Scorecard";
        SustainabilityGoal: Record "Sustainability Goal";
        LedgerEntry: Record "Sustainability Ledger Entry";
        TempArgument: Record "Message Argument ori" temporary;
        Impl: Codeunit "Sust Scorecard Get Impl ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [GIVEN] Permission mocking is on, and the company is configured so a leaked read would show the type
        EnsureMockStarted();
        LowerPermissions.SetOutsideO365Scope();
        EnsureConfigured();
        LowerPermissions.SetExactPermissionSet('Sust Sc Exec ori');
        Assert.IsFalse(SustainabilityScorecard.ReadPermission(), 'Execute only must not read scorecards.');
        Assert.IsFalse(SustainabilityGoal.ReadPermission(), 'Execute only must not read goals.');
        Assert.IsFalse(LedgerEntry.ReadPermission(), 'Execute only must not read ledger entries.');
        Assert.IsFalse(Impl.IsEnabled(), 'The type must be hidden without native read permission.');

        // [WHEN] The caller names the type
        RequestJson.Add('scorecardNo', 'SC-CRONUS');
        TempArgument.Init();
        TempArgument."Version" := Enum::"Message Version ori"::"1.0";
        TempArgument.Insert(true);
        TempArgument.SetRequestJson(RequestJson);
        Impl.ExecuteBifrostTask(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        LowerPermissions.SetOutsideO365Scope();

        // [THEN] The refusal is PermissionDenied and nothing was read
        Assert.IsTrue(ResponseJson.Get('code', Token), 'The refusal must carry a code.');
        Assert.AreEqual('PermissionDenied', Token.AsValue().AsText(), 'code');
        Assert.IsTrue(ResponseJson.Get('status', Token), 'status');
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'status');
    end;

    local procedure VerifyFoundationRole(FoundationSet: Code[20]; IncludeSustainabilitySet: Boolean; LanguageId: Integer)
    var
        SustainabilityScorecard: Record "Sustainability Scorecard";
        SustainabilityGoal: Record "Sustainability Goal";
        LedgerEntry: Record "Sustainability Ledger Entry";
        Impl: Codeunit "Sust Scorecard Get Impl ori";
        ResponseJson: JsonObject;
        ScorecardNo: Code[20];
        BeforeCount: Integer;
    begin
        // [GIVEN] A configured company and one scorecard, created before the permission set is lowered
        EnsureMockStarted();
        LowerPermissions.SetOutsideO365Scope();
        EnsureConfigured();
        ScorecardNo := CreateScorecard();
        CreateGoal(ScorecardNo, 'CO2', 10000, 10, 0);
        BeforeCount := LedgerEntry.Count();

        // [WHEN] Foundation Read or Full is assigned, with BIFROST SustRead ori only when requested
        LowerPermissions.SetExactPermissionSet(FoundationSet);
        if IncludeSustainabilitySet then
            LowerPermissions.AddPermissionSet('BIFROST SustRead ori');
        LowerPermissions.AddPermissionSet('Sust Setup Test ori');

        // [THEN] Native reads and discovery follow the Sustainability set. Neither role grants writes.
        Assert.AreEqual(IncludeSustainabilitySet, SustainabilityScorecard.ReadPermission(), 'Native scorecard reads require BIFROST SustRead ori alongside Foundation.');
        Assert.AreEqual(IncludeSustainabilitySet, SustainabilityGoal.ReadPermission(), 'Native goal reads require BIFROST SustRead ori alongside Foundation.');
        Assert.AreEqual(IncludeSustainabilitySet, LedgerEntry.ReadPermission(), 'Native ledger reads require BIFROST SustRead ori alongside Foundation.');
        Assert.IsFalse(
            SustainabilityScorecard.WritePermission() or SustainabilityGoal.WritePermission() or LedgerEntry.WritePermission(),
            'The read boundary does not grant sustainability writes.');
        Assert.AreEqual(IncludeSustainabilitySet, Impl.IsEnabled(), 'Discovery requires native sustainability read access.');
        LowerPermissions.AddPermissionSet('Sust Arg Test ori');

        // The impl is called directly. Foundation's dispatcher also requires Message Task execute and a
        // Foundation test-app license hook, which Foundation Read does not grant. The scorecard boundary
        // is this codeunit: hidden and PermissionDenied without native reads, and a read with no posting
        // when BIFROST SustRead ori is assigned. OnRun skips the license flag so the success path can run
        // under the lowered set; ExecuteBifrostTask is the refusal path and returns before that flag.
        ResponseJson := InvokeImpl(Impl, ScorecardNo, LanguageId, IncludeSustainabilitySet);
        LowerPermissions.SetOutsideO365Scope();
        Assert.AreEqual(BeforeCount, LedgerEntry.Count(), 'The call must not post or delete ledger entries.');

        if IncludeSustainabilitySet then begin
            AssertText(ResponseJson, 'status', 'Success');
            AssertText(ResponseJson, 'no', ScorecardNo);
        end else begin
            AssertText(ResponseJson, 'status', 'Error');
            AssertText(ResponseJson, 'code', 'PermissionDenied');
            if LanguageId = 1039 then
                Assert.IsTrue(StrPos(TextValue(ResponseJson, 'error'), 'lesheimild') > 0, TextValue(ResponseJson, 'error'))
            else
                Assert.IsTrue(StrPos(TextValue(ResponseJson, 'error'), 'read permission') > 0, TextValue(ResponseJson, 'error'));
        end;
    end;

    local procedure EnsureMockStarted()
    begin
        if not PermissionsMock.IsStarted() then
            PermissionsMock.Start();
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
    end;

    local procedure CreateScorecard() ScorecardNo: Code[20]
    var
        SustainabilityScorecard: Record "Sustainability Scorecard";
    begin
        ScorecardNo := CopyStr('BSC' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20);
        SustainabilityScorecard.Init();
        SustainabilityScorecard."No." := ScorecardNo;
        SustainabilityScorecard.Name := 'CRONUS scorecard';
        SustainabilityScorecard.Insert(true);
    end;

    local procedure CreateGoal(ScorecardNo: Code[20]; GoalNo: Code[20]; LineNo: Integer; TargetCo2: Decimal; TargetCh4: Decimal)
    var
        SustainabilityGoal: Record "Sustainability Goal";
    begin
        SustainabilityGoal.Init();
        SustainabilityGoal."Scorecard No." := ScorecardNo;
        SustainabilityGoal."No." := GoalNo;
        SustainabilityGoal."Line No." := LineNo;
        SustainabilityGoal.Name := GoalNo;
        SustainabilityGoal."Baseline Start Date" := 20240101D;
        SustainabilityGoal."Baseline End Date" := 20240131D;
        SustainabilityGoal."Start Date" := 20240301D;
        SustainabilityGoal."End Date" := 20240331D;
        SustainabilityGoal."Target Value for CO2" := TargetCo2;
        SustainabilityGoal."Target Value for CH4" := TargetCh4;
        SustainabilityGoal.Insert(true);
    end;

    local procedure EnsureConfigured()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
    begin
        // A filled emission unit is copied onto a new goal and must already exist as a unit of
        // measure. Leave a real unit alone. Otherwise one account is enough for IsConfigured,
        // and the goal insert does not depend on a unit code this company may not have.
        if SustainabilitySetup.Get() then
            if SustainabilitySetup."Emission Unit of Measure Code" <> '' then
                exit;
        if not SustainabilityAccount.IsEmpty() then
            exit;
        SustainabilityAccount.Init();
        SustainabilityAccount."No." := 'BFSUST98021';
        SustainabilityAccount.Name := 'Bifrost permission test account';
        SustainabilityAccount.Insert(false);
    end;

    local procedure InvokeImpl(var Impl: Codeunit "Sust Scorecard Get Impl ori"; ScorecardNo: Code[20]; LanguageId: Integer; AllowRead: Boolean) ResponseJson: JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
        RequestJson: JsonObject;
        SavedLanguage: Integer;
    begin
        RequestJson.Add('scorecardNo', ScorecardNo);
        TempArgument.Init();
        TempArgument."Version" := Enum::"Message Version ori"::"1.0";
        TempArgument.Insert(true);
        TempArgument.SetRequestJson(RequestJson);
        SavedLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        if AllowRead then
            Codeunit.Run(Codeunit::"Sust Scorecard Get Impl ori", TempArgument)
        else
            Impl.ExecuteBifrostTask(TempArgument);
        GlobalLanguage(SavedLanguage);
        ResponseJson := TempArgument.GetResponseJson();
    end;

    local procedure AssertText(Parent: JsonObject; Name: Text; Expected: Text)
    begin
        Assert.AreEqual(Expected, TextValue(Parent, Name), Name);
    end;

    local procedure TextValue(Parent: JsonObject; Name: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Parent.Get(Name, Token), Name);
        exit(Token.AsValue().AsText());
    end;
}
