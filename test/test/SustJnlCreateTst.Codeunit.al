namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Finance.Dimension;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Issue 7: exercises creation, rollback, contracts and visibility in both supported languages.</summary>
codeunit 98040 "Sust Jnl Create Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Fixture: Codeunit "Sust Jnl Create Fixture ori";
        Assert: Codeunit "Library Assert";

    /// <summary>Verifies Manual through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_Manual_1033()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Manual', 1033);
    end;

    /// <summary>Verifies Manual through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_Manual_1039()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Manual', 1039);
    end;

    /// <summary>Verifies Formula through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_Formula_1033()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Formula', 1033);
    end;

    /// <summary>Verifies Formula through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_Formula_1039()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Formula', 1039);
    end;

    /// <summary>Verifies CreateBatch through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_CreateBatch_1033()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('CreateBatch', 1033);
    end;

    /// <summary>Verifies CreateBatch through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_CreateBatch_1039()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('CreateBatch', 1039);
    end;

    /// <summary>Verifies NumberSeries through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_NumberSeries_1033()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('NumberSeries', 1033);
    end;

    /// <summary>Verifies NumberSeries through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_NumberSeries_1039()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('NumberSeries', 1039);
    end;

    /// <summary>Verifies Dimensions through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_Dimensions_1033()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Dimensions', 1033);
    end;

    /// <summary>Verifies Dimensions through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_Dimensions_1039()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Dimensions', 1039);
    end;

    /// <summary>Verifies MissingTemplate through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_MissingTemplate_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('MissingTemplate', 1033);
    end;

    /// <summary>Verifies MissingTemplate through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_MissingTemplate_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('MissingTemplate', 1039);
    end;

    /// <summary>Verifies MissingBatch through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_MissingBatch_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('MissingBatch', 1033);
    end;

    /// <summary>Verifies MissingBatch through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_MissingBatch_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('MissingBatch', 1039);
    end;

    /// <summary>Verifies MissingAccount through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_MissingAccount_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('MissingAccount', 1033);
    end;

    /// <summary>Verifies MissingAccount through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_MissingAccount_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('MissingAccount', 1039);
    end;

    /// <summary>Verifies BlockedAccount through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_BlockedAccount_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('BlockedAccount', 1033);
    end;

    /// <summary>Verifies BlockedAccount through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_BlockedAccount_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('BlockedAccount', 1039);
    end;

    /// <summary>Verifies NonPostingAccount through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_NonPostingAccount_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('NonPostingAccount', 1033);
    end;

    /// <summary>Verifies NonPostingAccount through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_NonPostingAccount_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('NonPostingAccount', 1039);
    end;

    /// <summary>Verifies Ambiguous through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_Ambiguous_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Ambiguous', 1033);
    end;

    /// <summary>Verifies Ambiguous through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_Ambiguous_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Ambiguous', 1039);
    end;

    /// <summary>Verifies ScopeMismatch through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_ScopeMismatch_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('ScopeMismatch', 1033);
    end;

    /// <summary>Verifies ScopeMismatch through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_ScopeMismatch_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('ScopeMismatch', 1039);
    end;

    /// <summary>Verifies NativeRollback through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_NativeRollback_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('NativeRollback', 1033);
    end;

    /// <summary>Verifies NativeRollback through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_NativeRollback_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('NativeRollback', 1039);
    end;

    /// <summary>Verifies BatchRollback through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_BatchRollback_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('BatchRollback', 1033);
    end;

    /// <summary>Verifies BatchRollback through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_BatchRollback_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('BatchRollback', 1039);
    end;

    /// <summary>Verifies UnknownRoot through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC05_UnknownRoot_1033()
    begin
        // Story #7, AC05 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('UnknownRoot', 1033);
    end;

    /// <summary>Verifies UnknownRoot through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC05_UnknownRoot_1039()
    begin
        // Story #7, AC05 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('UnknownRoot', 1039);
    end;

    /// <summary>Verifies UnknownLine through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC05_UnknownLine_1033()
    begin
        // Story #7, AC05 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('UnknownLine', 1033);
    end;

    /// <summary>Verifies UnknownLine through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC05_UnknownLine_1039()
    begin
        // Story #7, AC05 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('UnknownLine', 1039);
    end;

    /// <summary>Verifies RetryAddsLines through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_RetryAddsLines_1033()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('RetryAddsLines', 1033);
    end;

    /// <summary>Verifies RetryAddsLines through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_RetryAddsLines_1039()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('RetryAddsLines', 1039);
    end;

    /// <summary>Verifies ZeroEmission through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_ZeroEmission_1033()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('ZeroEmission', 1033);
    end;

    /// <summary>Verifies ZeroEmission through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_ZeroEmission_1039()
    begin
        // Story #7, AC03 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('ZeroEmission', 1039);
    end;

    /// <summary>Verifies Overlong through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_Overlong_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Overlong', 1033);
    end;

    /// <summary>Verifies Overlong through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_Overlong_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Overlong', 1039);
    end;

    /// <summary>Verifies EmptyLines through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_EmptyLines_1033()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('EmptyLines', 1033);
    end;

    /// <summary>Verifies EmptyLines through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_EmptyLines_1039()
    begin
        // Story #7, AC04 | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('EmptyLines', 1039);
    end;

    /// <summary>Verifies Visibility through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_ACV_Visibility_1033()
    begin
        // Story #7, ACV | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Visibility', 1033);
    end;

    /// <summary>Verifies Visibility through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_ACV_Visibility_1039()
    begin
        // Story #7, ACV | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Visibility', 1039);
    end;

    /// <summary>Verifies Contract through public dispatch in language 1033.</summary>
    [Test]
    procedure Scenario_ACH_Contract_1033()
    begin
        // Story #7, ACH | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Contract', 1033);
    end;

    /// <summary>Verifies Contract through public dispatch in language 1039.</summary>
    [Test]
    procedure Scenario_ACH_Contract_1039()
    begin
        // Story #7, ACH | Time: fixed 2026-01-15; WorkDate ignored | Risk: shared visibility #1
        RunScenario('Contract', 1039);
    end;

    local procedure RunScenario(Scenario: Text; LanguageId: Integer)
    var
        Account: Record "Sustainability Account";
        Batch: Record "Sustainability Jnl. Batch";
        JournalLine: Record "Sustainability Jnl. Line";
        LedgerEntry: Record "Sustainability Ledger Entry";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        RequestJson: JsonObject;
        Response: JsonObject;
        LineJson: JsonObject;
        Dimensions: JsonObject;
        Lines: JsonArray;
        Token: JsonToken;
        OutputLine: JsonObject;
        ExpectedCode: Text;
        LedgerCount: Integer;
        ExpectedCO2: Decimal;
    begin
        // [GIVEN] Independent journal setup and a valid request.
        Fixture.Initialize();
        RequestJson := Fixture.Request();
        LineJson := Fixture.Line();
        LedgerCount := LedgerEntry.Count();
        ExpectedCO2 := 10;
        case Scenario of
            'Formula':
                begin
                    LineJson.Remove('emissionCO2');
                    LineJson.Remove('emissionCH4');
                    LineJson.Remove('emissionN2O');
                    LineJson.Add('fuelOrElectricity', 5);
                end;
            'CreateBatch':
                begin
                    RequestJson.Replace('batchName', 'XNEW');
                    RequestJson.Add('createBatch', true);
                end;
            'NumberSeries':
                LineJson.Remove('documentNo');
            'Dimensions':
                begin
                    if not Dimension.Get('XJ7') then begin
                        Dimension.Code := 'XJ7';
                        Dimension.Insert();
                    end;
                    if not DimensionValue.Get('XJ7', 'XVALUE') then begin
                        DimensionValue."Dimension Code" := 'XJ7';
                        DimensionValue.Code := 'XVALUE';
                        DimensionValue.Insert(true);
                    end;
                    Dimensions.Add('XJ7', 'XVALUE');
                    LineJson.Add('dimensions', Dimensions);
                end;
            'MissingTemplate':
                begin
                    RequestJson.Replace('templateName', 'XMISSING');
                    ExpectedCode := 'BatchNotFound';
                end;
            'MissingBatch':
                begin
                    RequestJson.Replace('batchName', 'XMISSING');
                    ExpectedCode := 'BatchNotFound';
                end;
            'MissingAccount':
                begin
                    LineJson.Replace('accountNo', 'XMISSING');
                    ExpectedCode := 'InvalidAccount';
                end;
            'BlockedAccount', 'NonPostingAccount':
                begin
                    Account.Get('XJ7');
                    if Scenario = 'BlockedAccount' then
                        Account.Blocked := true
                    else
                        Account."Account Type" := Account."Account Type"::Heading;
                    Account.Modify();
                    ExpectedCode := 'InvalidAccount';
                end;
            'Ambiguous':
                begin
                    LineJson.Add('fuelOrElectricity', 0);
                    ExpectedCode := 'AmbiguousInput';
                end;
            'ScopeMismatch':
                begin
                    Batch.Get('XJ7', 'XJ7');
                    Batch."Emission Scope" := Batch."Emission Scope"::"Scope 2";
                    Batch.Modify();
                    ExpectedCode := 'ScopeMismatch';
                end;
            'NativeRollback', 'BatchRollback':
                begin
                    Lines.Add(Fixture.Line());
                    LineJson.Add('countryRegionCode', 'XMISSING');
                    ExpectedCode := 'BusinessCentralError';
                    if Scenario = 'BatchRollback' then begin
                        RequestJson.Replace('batchName', 'XNEW');
                        RequestJson.Add('createBatch', true);
                    end;
                end;
            'UnknownRoot':
                begin
                    RequestJson.Add('creatBatch', true);
                    ExpectedCode := 'UnknownParameter';
                end;
            'UnknownLine':
                begin
                    LineJson.Add('emissionC02', 10);
                    ExpectedCode := 'UnknownParameter';
                end;
            'ZeroEmission':
                begin
                    LineJson.Replace('emissionCO2', 0);
                    ExpectedCO2 := 0;
                end;
            'Overlong':
                begin
                    LineJson.Add('description', PadStr('X', 101, 'X'));
                    ExpectedCode := 'BusinessCentralError';
                end;
            'EmptyLines':
                ExpectedCode := 'BusinessCentralError';
            'Visibility':
                begin
                    VerifyVisibility(LanguageId);
                    exit;
                end;
            'Contract':
                begin
                    VerifyContract(LanguageId);
                    exit;
                end;
        end;
        if Scenario <> 'EmptyLines' then
            Lines.Add(LineJson);
        RequestJson.Replace('lines', Lines);
        // [WHEN] The public dispatcher runs the complete request in an isolated transaction.
        Response := Fixture.Invoke(RequestJson, LanguageId);
        // [THEN] Native ledger posting never occurs; errors retain no partial lines or batches.
        Assert.AreEqual(LedgerCount, LedgerEntry.Count(), 'AC06: no sustainability ledger posting.');
        if ExpectedCode <> '' then begin
            Fixture.AssertText(Response, 'status', 'Error');
            if ExpectedCode in ['BatchNotFound', 'InvalidAccount', 'AmbiguousInput', 'ScopeMismatch'] then begin
                Fixture.AssertText(Response, 'reason', ExpectedCode);
                case ExpectedCode of
                    'BatchNotFound':
                        Fixture.AssertText(Response, 'code', 'RecordNotFound');
                    'InvalidAccount', 'AmbiguousInput':
                        Fixture.AssertText(Response, 'code', 'InvalidParameter');
                    'ScopeMismatch':
                        Fixture.AssertText(Response, 'code', 'PreconditionFailed');
                end;
            end else
                Fixture.AssertText(Response, 'code', ExpectedCode);
            Fixture.AssertNoLines();
            if Scenario = 'BatchRollback' then
                Assert.IsFalse(Batch.Get('XJ7', 'XNEW'), 'A failed request must also roll back the created batch.');
            exit;
        end;
        Fixture.AssertText(Response, 'status', 'Success');
        Response.Get('lines', Token);
        Assert.AreEqual(1, Token.AsArray().Count(), 'One result per line.');
        Token.AsArray().Get(0, Token);
        OutputLine := Token.AsObject();
        OutputLine.Get('CO2', Token);
        Assert.AreEqual(ExpectedCO2, Token.AsValue().AsDecimal(), 'CO2 must reflect manual/native formula validation.');
        Assert.IsTrue(OutputLine.Contains('CO2e'), 'CO2e must be returned.');
        JournalLine.SetRange("Journal Template Name", 'XJ7');
        JournalLine.FindFirst();
        Assert.AreEqual(10000, JournalLine."Line No.", 'Line numbering starts at 10000.');
        if Scenario = 'Formula' then begin
            Assert.AreEqual(15, JournalLine."Emission CH4", 'Native formula must calculate CH4.');
            Assert.AreEqual(20, JournalLine."Emission N2O", 'Native formula must calculate N2O.');
        end;
        if Scenario = 'NumberSeries' then
            Assert.AreEqual('X00001', JournalLine."Document No.", 'Default document number must come from the batch series.');
        if Scenario = 'Dimensions' then
            Assert.IsTrue(JournalLine."Dimension Set ID" <> 0, 'Dimensions must be stored on the created line.');
        if Scenario = 'CreateBatch' then
            Assert.IsTrue(Batch.Get('XJ7', 'XNEW'), 'createBatch must create the missing batch.');
        if Scenario = 'RetryAddsLines' then begin
            Response := Fixture.Invoke(RequestJson, LanguageId);
            Fixture.AssertText(Response, 'status', 'Success');
            Assert.AreEqual(2, JournalLine.Count(), 'A successful retry adds another line.');
            JournalLine.FindLast();
            Assert.AreEqual(20000, JournalLine."Line No.", 'Retry must append after the last line.');
        end;
    end;

    local procedure VerifyVisibility(LanguageId: Integer)
    var
        Setup: Record "Sustainability Setup";
        Account: Record "Sustainability Account";
        Handler: Interface "Msg Interface ori";
        Response: JsonObject;
        RequestJson: JsonObject;
    begin
        Handler := Enum::"Message Type ori"::"Sustainability.Journal.Create";
        Assert.IsTrue(Handler.IsEnabled(), 'An account configures Sustainability.');
        Account.DeleteAll();
        Setup.Get();
        Setup."Emission Unit of Measure Code" := '';
        Setup.Modify();
        Assert.IsFalse(Handler.IsEnabled(), 'An unconfigured company must hide the type.');
        // Knowing a hidden type still reaches the handler, which returns its own account refusal.
        RequestJson := Fixture.Request();
        Response := Fixture.Invoke(RequestJson, LanguageId);
        Fixture.AssertText(Response, 'reason', 'InvalidAccount');
        Fixture.AssertText(Response, 'code', 'InvalidParameter');
        Fixture.AssertText(Response, 'status', 'Error');
    end;

    local procedure VerifyContract(LanguageId: Integer)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Handler: Interface "Msg Contract ori";
        Contract: JsonObject;
        Effect: JsonObject;
        Parameters: JsonArray;
        Errors: JsonArray;
        Token: JsonToken;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Handler := Enum::"Message Type ori"::"Sustainability.Journal.Create";
        Assert.IsTrue(Handler.GetEffect(Effect), 'Effect chapter is required.');
        Effect.Get('idempotent', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'The contract must warn that retries create more lines.');
        Assert.IsTrue(Handler.GetParameters(Parameters), 'Parameter chapter is required.');
        Assert.AreEqual(4, Parameters.Count(), 'All root request keys must be documented.');
        Assert.IsTrue(Handler.GetErrors(Errors), 'Error chapter is required.');
        Assert.AreEqual(6, Errors.Count(), 'Four named refusals, permission and native errors must be documented.');
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Sustainability.Journal.Create", Contract), 'Foundation must assemble the complete contract without an invalid error code.');
        GlobalLanguage(PreviousLanguage);
    end;
}
