namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Scorecard;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Sustainability.Scorecard.Get through Foundation's public dispatcher.
/// Covers the happy path, every refusal, visibility and the no-posting rule, in English and Icelandic.
/// </summary>
codeunit 98020 "Sust Scorecard Get Tst ori"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>A scorecard and two goals come back with progress, and an equal target is null.</summary>
    [Test]
    procedure HappyPath_ReturnsGoalsAndProgress()
    var
        ResponseJson: JsonObject;
        Goals: JsonArray;
        Goal: JsonObject;
        Token: JsonToken;
        Progress: JsonObject;
        ScorecardNo: Code[20];
    begin
        // [GIVEN] A CRONUS-style scorecard with a CO2 target and a CH4 target equal to the baseline
        ScorecardNo := CreateScorecard();
        CreateGoal(ScorecardNo, 'CO2', 10000, 10, 0);

        // [WHEN] The scorecard is read in English
        ResponseJson := ReadScorecard(ScorecardNo, '', 1033);

        // [THEN] The header and the goal are returned, CO2 progress is zero and CH4 progress is null
        AssertStatus(ResponseJson, 'Success');
        Assert.AreEqual(ScorecardNo, TextValue(ResponseJson, 'no'), 'scorecard no');
        Assert.AreEqual('CRONUS scorecard', TextValue(ResponseJson, 'name'), 'scorecard name');
        Goals := ArrayValue(ResponseJson, 'goals');
        Assert.AreEqual(1, Goals.Count(), 'one goal');
        Goals.Get(0, Token);
        Goal := Token.AsObject();
        Assert.AreEqual('CO2', TextValue(Goal, 'no'), 'goal no');
        Assert.AreEqual(10, DecimalValue(ObjectValue(Goal, 'target'), 'co2'), 'target co2');
        Progress := ObjectValue(Goal, 'progressPercent');
        Assert.AreEqual(0, DecimalValue(Progress, 'co2'), 'CO2 has not moved from a zero baseline toward 10.');
        Assert.IsTrue(Progress.Get('ch4', Token), 'ch4 progress');
        Assert.IsTrue(Token.AsValue().IsNull(), 'CH4 progress is null when the target equals the baseline.');
    end;

    /// <summary>goalNo returns only that goal.</summary>
    [Test]
    procedure GoalNo_ReturnsOneGoal()
    var
        ResponseJson: JsonObject;
        ScorecardNo: Code[20];
    begin
        // [GIVEN] Two goals on one scorecard
        ScorecardNo := CreateScorecard();
        CreateGoal(ScorecardNo, 'CO2', 10000, 10, 0);
        CreateGoal(ScorecardNo, 'CH4', 20000, 0, 5);

        // [WHEN] Only CH4 is requested
        ResponseJson := ReadScorecard(ScorecardNo, 'CH4', 1033);

        // [THEN] The answer holds that goal and not the other
        AssertStatus(ResponseJson, 'Success');
        Assert.AreEqual(1, ArrayValue(ResponseJson, 'goals').Count(), 'filtered goals');
        Assert.AreEqual('CH4', TextValue(ObjectAt(ResponseJson, 'goals', 0), 'no'), 'goal no');
    end;

    /// <summary>Missing scorecardNo is MissingParameter in English and Icelandic.</summary>
    [Test]
    procedure MissingScorecardNo_RefusesInBothLanguages()
    var
        English: JsonObject;
        Icelandic: JsonObject;
    begin
        // [GIVEN] An empty request
        // [WHEN] It is sent in each language
        English := Invoke(Enum::"Message Type ori"::"Sustainability.Scorecard.Get", '', '{}', 1033);
        Icelandic := Invoke(Enum::"Message Type ori"::"Sustainability.Scorecard.Get", '', '{}', 1039);

        // [THEN] Both refuse with MissingParameter, and the Icelandic text is translated
        Assert.AreEqual('MissingParameter', TextValue(English, 'code'), 'English code');
        Assert.AreEqual('MissingParameter', TextValue(Icelandic, 'code'), 'Icelandic code');
        Assert.AreEqual('scorecardNo', TextValue(English, 'parameter'), 'parameter');
        Assert.AreNotEqual(TextValue(English, 'error'), TextValue(Icelandic, 'error'), 'The refusal must be translated.');
        Assert.IsTrue(StrPos(TextValue(Icelandic, 'error'), 'vantar') > 0, TextValue(Icelandic, 'error'));
    end;

    /// <summary>An unknown scorecard is RecordNotFound.</summary>
    [Test]
    procedure UnknownScorecard_Refuses()
    var
        ResponseJson: JsonObject;
    begin
        // [WHEN] A scorecard number that does not exist is requested
        ResponseJson := ReadScorecard('NO-SUCH-SCORECARD', '', 1033);

        // [THEN] The refusal names the scorecard parameter
        Assert.AreEqual('RecordNotFound', TextValue(ResponseJson, 'code'), 'code');
        Assert.AreEqual('scorecardNo', TextValue(ResponseJson, 'parameter'), 'parameter');
    end;

    /// <summary>An unknown goal on a real scorecard is RecordNotFound.</summary>
    [Test]
    procedure UnknownGoal_Refuses()
    var
        ResponseJson: JsonObject;
        ScorecardNo: Code[20];
    begin
        // [GIVEN] A scorecard with no matching goal
        ScorecardNo := CreateScorecard();

        // [WHEN] A goal number that is not on it is requested
        ResponseJson := ReadScorecard(ScorecardNo, 'NO-SUCH-GOAL', 1039);

        // [THEN] The refusal names the goal parameter in Icelandic
        Assert.AreEqual('RecordNotFound', TextValue(ResponseJson, 'code'), 'code');
        Assert.AreEqual('goalNo', TextValue(ResponseJson, 'parameter'), 'parameter');
        Assert.IsTrue(StrPos(TextValue(ResponseJson, 'error'), 'ekki til') > 0, TextValue(ResponseJson, 'error'));
    end;

    /// <summary>A from-date after the to-date is InvalidParameter.</summary>
    [Test]
    procedure InvalidPeriod_Refuses()
    var
        ResponseJson: JsonObject;
        RequestJson: JsonObject;
        ScorecardNo: Code[20];
    begin
        // [GIVEN] A scorecard and a baseline period that ends before it starts
        ScorecardNo := CreateScorecard();
        RequestJson.Add('scorecardNo', ScorecardNo);
        RequestJson.Add('baselineFrom', '2024-02-01');
        RequestJson.Add('baselineTo', '2024-01-31');

        // [WHEN] The period is sent
        ResponseJson := InvokeObject(Enum::"Message Type ori"::"Sustainability.Scorecard.Get", RequestJson, 1033);

        // [THEN] The period is refused and nothing is read as success
        Assert.AreEqual('InvalidParameter', TextValue(ResponseJson, 'code'), 'code');
        Assert.AreEqual('baselineFrom', TextValue(ResponseJson, 'parameter'), 'parameter');
    end;

    /// <summary>A misspelled request key is refused before the scorecard is read.</summary>
    [Test]
    procedure UnknownKey_Refuses()
    var
        ResponseJson: JsonObject;
        RequestJson: JsonObject;
        ScorecardNo: Code[20];
    begin
        // [GIVEN] A valid scorecard and an extra key
        ScorecardNo := CreateScorecard();
        RequestJson.Add('scorecardNo', ScorecardNo);
        RequestJson.Add('scorecardNumber', ScorecardNo);

        // [WHEN] The request is sent
        ResponseJson := InvokeObject(Enum::"Message Type ori"::"Sustainability.Scorecard.Get", RequestJson, 1033);

        // [THEN] The unknown key is refused
        Assert.AreEqual('UnknownParameter', TextValue(ResponseJson, 'code'), 'code');
        Assert.AreEqual('scorecardNumber', TextValue(ResponseJson, 'parameter'), 'parameter');
    end;

    /// <summary>The call does not post sustainability ledger entries.</summary>
    [Test]
    procedure LedgerCount_IsUnchanged()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        ScorecardNo: Code[20];
        BeforeCount: Integer;
    begin
        // [GIVEN] The current number of sustainability ledger entries
        ScorecardNo := CreateScorecard();
        CreateGoal(ScorecardNo, 'CO2', 10000, 10, 0);
        BeforeCount := SustainabilityLedgerEntry.Count();

        // [WHEN] The scorecard is read
        ReadScorecard(ScorecardNo, '', 1033);

        // [THEN] The ledger was not posted to
        Assert.AreEqual(BeforeCount, SustainabilityLedgerEntry.Count(), 'The read must not post sustainability ledger entries.');
    end;

    /// <summary>An unconfigured company hides the type, and a direct call still reads.</summary>
    [Test]
    procedure Unconfigured_IsHiddenButStillRuns()
    var
        ResponseJson: JsonObject;
        ScorecardNo: Code[20];
    begin
        // [GIVEN] No emission unit and no sustainability account
        ClearConfiguration();
        ScorecardNo := CreateScorecard();
        CreateGoal(ScorecardNo, 'CO2', 10000, 10, 0);

        // [WHEN] The roster is asked for enabled types, and the type is called by name
        // [THEN] The roster omits it, and the call still succeeds
        Assert.IsFalse(Listed(true), 'An unconfigured company must hide the type.');
        Assert.IsTrue(Listed(false), 'The type stays in the catalogue when the roster is not filtered to enabled types.');
        ResponseJson := ReadScorecard(ScorecardNo, '', 1033);
        AssertStatus(ResponseJson, 'Success');
    end;

    /// <summary>A configured company lists the type.</summary>
    [Test]
    procedure Configured_IsListed()
    begin
        // [GIVEN] An emission unit of measure
        SetEmissionUnit();

        // [THEN] The roster includes the type
        Assert.IsTrue(Listed(true), 'A configured company must show the type.');
    end;

    /// <summary>The contract names a read effect and the scorecard parameter.</summary>
    [Test]
    procedure Contract_MatchesTheRead()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Chapter: JsonToken;
        Effect: JsonToken;
        ContractText: Text;
    begin
        // [WHEN] Foundation builds the contract
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Sustainability.Scorecard.Get", Contract), 'The contract must build.');

        // [THEN] The effect is read and scorecardNo is declared
        Assert.IsTrue(Contract.Get('effect', Chapter), 'effect chapter');
        Assert.IsTrue(Chapter.AsObject().Get('effect', Effect), 'effect');
        Assert.AreEqual('read', Effect.AsValue().AsText(), 'effect');
        Contract.WriteTo(ContractText);
        Assert.IsTrue(StrPos(ContractText, 'scorecardNo') > 0, 'scorecardNo must be in the contract.');
        Assert.IsTrue(StrPos(ContractText, 'ScorecardNotFound') = 0, 'The closed Foundation error enum cannot carry a custom code.');
    end;

    local procedure ReadScorecard(ScorecardNo: Code[20]; GoalNo: Code[20]; LanguageId: Integer) ResponseJson: JsonObject
    var
        RequestJson: JsonObject;
    begin
        RequestJson.Add('scorecardNo', ScorecardNo);
        if GoalNo <> '' then
            RequestJson.Add('goalNo', GoalNo);
        ResponseJson := InvokeObject(Enum::"Message Type ori"::"Sustainability.Scorecard.Get", RequestJson, LanguageId);
    end;

    local procedure InvokeObject(MessageType: Enum "Message Type ori"; RequestJson: JsonObject; LanguageId: Integer) ResponseJson: JsonObject
    var
        RequestText: Text;
    begin
        RequestJson.WriteTo(RequestText);
        ResponseJson := Invoke(MessageType, '', RequestText, LanguageId);
    end;

    local procedure Invoke(MessageType: Enum "Message Type ori"; Subject: Text; RequestText: Text; LanguageId: Integer) ResponseJson: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        ResponseInStream: InStream;
        TaskId: Guid;
        MessageId: Guid;
        ResponseContentType: Text[100];
        ResponseTime: Duration;
        ResponseText: Text;
    begin
        // Public dispatcher path with the caller's language. OmitCommit keeps the test transaction.
        if RequestText <> '' then
            RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(MessageType, Enum::"Message Version ori"::"1.0", CopyStr(Subject, 1, 250), 'BSC', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseTempBlob, ResponseContentType, ResponseTime, true);
        ResponseTempBlob.CreateInStream(ResponseInStream, TextEncoding::UTF8);
        ResponseInStream.ReadText(ResponseText);
        Assert.IsTrue(ResponseJson.ReadFrom(ResponseText), ResponseText);
    end;

    local procedure Listed(OnlyEnabled: Boolean): Boolean
    var
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        RequestText: Text;
    begin
        RequestJson.Add('onlyEnabled', OnlyEnabled);
        RequestJson.WriteTo(RequestText);
        ResponseJson := Invoke(Enum::"Message Type ori"::"Help.MessageTypes.Get", 'Sustainability.Scorecard.Get', RequestText, 1033);
        AssertStatus(ResponseJson, 'Success');
        exit(ArrayValue(ResponseJson, 'result').Count() > 0);
    end;

    local procedure CreateScorecard() ScorecardNo: Code[20]
    var
        SustainabilityScorecard: Record "Sustainability Scorecard";
    begin
        EnsureSetup();
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

    local procedure EnsureSetup()
    var
        SustainabilitySetup: Record "Sustainability Setup";
    begin
        if SustainabilitySetup.Get() then
            exit;
        SustainabilitySetup.Init();
        SustainabilitySetup.Insert(true);
    end;

    local procedure ClearConfiguration()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
    begin
        EnsureSetup();
        SustainabilitySetup.Get();
        // Assign directly. Validate refuses a change while ledger entries still use the old unit.
        SustainabilitySetup."Emission Unit of Measure Code" := '';
        SustainabilitySetup.Modify(true);
        SustainabilityAccount.DeleteAll(false);
    end;

    local procedure SetEmissionUnit()
    var
        SustainabilitySetup: Record "Sustainability Setup";
    begin
        EnsureSetup();
        SustainabilitySetup.Get();
        // The visibility check only cares that the field is filled. Skip Validate so the test
        // does not depend on a unit of measure that exists in this company.
        SustainabilitySetup."Emission Unit of Measure Code" := 'PCS';
        SustainabilitySetup.Modify(true);
    end;

    local procedure AssertStatus(ResponseJson: JsonObject; Expected: Text)
    begin
        Assert.AreEqual(Expected, TextValue(ResponseJson, 'status'), 'status');
    end;

    local procedure TextValue(Parent: JsonObject; Name: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Parent.Get(Name, Token), Name);
        exit(Token.AsValue().AsText());
    end;

    local procedure DecimalValue(Parent: JsonObject; Name: Text): Decimal
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Parent.Get(Name, Token), Name);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure ObjectValue(Parent: JsonObject; Name: Text): JsonObject
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Parent.Get(Name, Token), Name);
        exit(Token.AsObject());
    end;

    local procedure ArrayValue(Parent: JsonObject; Name: Text) Result: JsonArray
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Parent.Get(Name, Token), Name);
        Result := Token.AsArray();
    end;

    local procedure ObjectAt(Parent: JsonObject; Name: Text; Index: Integer): JsonObject
    var
        Token: JsonToken;
        Items: JsonArray;
    begin
        Items := ArrayValue(Parent, Name);
        Items.Get(Index, Token);
        exit(Token.AsObject());
    end;
}
