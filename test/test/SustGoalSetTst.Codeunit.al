namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Scorecard;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.Security.User;
using System.TestLibraries.Utilities;

/// <summary>Issue 6: Sustainability.Goal.Set creates and updates scorecards and goals through the public dispatcher.</summary>
codeunit 98035 "Sust Goal Set Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>A new scorecard with one main goal is created with the standard rules and nothing is posted.</summary>
    [Test]
    procedure Scenario_AC03_NewScorecardAndGoal_Created()
    var
        Scorecard: Record "Sustainability Scorecard";
        Goal: Record "Sustainability Goal";
        LedgerEntry: Record "Sustainability Ledger Entry";
        Response: JsonObject;
        ScorecardNo: Code[20];
        OwnerId: Code[50];
        LedgerCount: Integer;
    begin
        // Story #6, AC03/AC06 | Time: fixed dates | Risk: owned fixture deleted before asserts
        Initialize(ScorecardNo, OwnerId);
        LedgerCount := LedgerEntry.Count();
        Response := Invoke(FullRequest(ScorecardNo, OwnerId, true), 0);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Assert.IsTrue(Scorecard.Get(ScorecardNo), 'The scorecard must be created.');
        Goal.SetRange("Scorecard No.", ScorecardNo);
        Assert.AreEqual(1, Goal.Count(), 'One goal must be created.');
        Goal.FindFirst();
        Assert.AreEqual('Cut CO2', Goal.Name, 'Goal name');
        Assert.AreEqual(OwnerId, Goal.Owner, 'Goal owner');
        Assert.AreEqual(500, Goal."Target Value for CO2", 'CO2 target');
        Assert.AreEqual(12.5, Goal."Target Value for Water Int.", 'Water intensity target');
        Assert.AreEqual(DMY2Date(1, 1, 2030), Goal."Start Date", 'Start date');
        Assert.AreEqual(DMY2Date(31, 12, 2024), Goal."Baseline End Date", 'Baseline end date');
        Assert.IsTrue(Goal."Main Goal", 'Main goal');
        Assert.AreEqual(OwnerId, Scorecard.Owner, 'Scorecard owner');
        Assert.AreEqual(LedgerCount, LedgerEntry.Count(), 'Goal.Set must not post sustainability ledger entries.');
        Assert.IsTrue(Serialize(Response).Contains('"goals":[{"no":"G-CO2"'), Serialize(Response));
        Cleanup(ScorecardNo, OwnerId);
    end;

    /// <summary>The same request again (here in Icelandic) succeeds and changes nothing, also for the main goal.</summary>
    [Test]
    procedure Scenario_AC03_Icelandic_SecondCall_IsIdempotent()
    var
        Goal: Record "Sustainability Goal";
        Response: JsonObject;
        ScorecardNo: Code[20];
        OwnerId: Code[50];
        RequestText: Text;
        MainGoal: Boolean;
    begin
        // Story #6, AC03/AC-L | Time: fixed dates | Risk: owned fixture deleted before asserts
        Initialize(ScorecardNo, OwnerId);
        RequestText := FullRequest(ScorecardNo, OwnerId, true);
        Response := Invoke(RequestText, 1039);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Goal.SetRange("Scorecard No.", ScorecardNo);
        Goal.FindFirst();
        MainGoal := Goal."Main Goal";
        Response := Invoke(RequestText, 1039);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Goal.SetRange("Scorecard No.", ScorecardNo);
        Assert.AreEqual(1, Goal.Count(), 'A second call must update the same goal, not add one.');
        Goal.FindFirst();
        Assert.AreEqual(MainGoal, Goal."Main Goal", 'The main goal flag must not change on a repeated call.');
        Cleanup(ScorecardNo, OwnerId);
    end;

    /// <summary>A goal that is not listed is left as it is when another goal is updated.</summary>
    [Test]
    procedure Scenario_AC03_UnlistedGoal_IsUnchanged()
    var
        Goal: Record "Sustainability Goal";
        Response: JsonObject;
        ScorecardNo: Code[20];
        OwnerId: Code[50];
    begin
        // Story #6, AC03 | Time: fixed dates | Risk: owned fixture deleted before asserts
        Initialize(ScorecardNo, OwnerId);
        Response := Invoke(FullRequest(ScorecardNo, OwnerId, false), 0);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Response := Invoke(StrSubstNo('{"scorecardNo":"%1","goals":[{"no":"G-CH4","name":"Methane","targetCH4":7}]}', ScorecardNo), 0);
        Assert.AreEqual('Success', Response.GetText('status'), Serialize(Response));
        Goal.SetRange("Scorecard No.", ScorecardNo);
        Assert.AreEqual(2, Goal.Count(), 'The second goal is added.');
        Goal.SetRange("No.", 'G-CO2');
        Goal.FindFirst();
        Assert.AreEqual(500, Goal."Target Value for CO2", 'The goal that is not listed keeps its target.');
        Cleanup(ScorecardNo, OwnerId);
    end;

    /// <summary>A missing scorecardNo is refused with MissingParameter in English and Icelandic.</summary>
    [Test]
    procedure Scenario_AC04_MissingScorecardNo_Refused()
    var
        Scorecard: Record "Sustainability Scorecard";
        Response: JsonObject;
        ScorecardCount: Integer;
    begin
        // Story #6, AC04/AC-L | Time: no date-dependent inputs | Risk: read-only refusal
        EnsureSetup();
        ScorecardCount := Scorecard.Count();
        Response := Invoke('{"name":"No number"}', 0);
        AssertRefusal(Response, 'MissingParameter');
        Response := Invoke('{"name":"No number"}', 1039);
        AssertRefusal(Response, 'MissingParameter');
        Assert.IsTrue(Response.GetText('error').Contains('Engu var breytt'), 'The refusal must be translated: ' + Serialize(Response));
        Assert.AreEqual(ScorecardCount, Scorecard.Count(), 'A refusal must not create a scorecard.');
    end;

    /// <summary>An end date before the start date is refused as an invalid period and nothing is written.</summary>
    [Test]
    procedure Scenario_AC04_EndBeforeStart_Refused()
    var
        Scorecard: Record "Sustainability Scorecard";
        Response: JsonObject;
        ScorecardNo: Code[20];
        OwnerId: Code[50];
    begin
        // Story #6, AC04 | Time: fixed dates | Risk: refusal leaves no data
        Initialize(ScorecardNo, OwnerId);
        Response := Invoke(StrSubstNo('{"scorecardNo":"%1","goals":[{"no":"G1","baselineStartDate":"2024-01-01","baselineEndDate":"2024-12-31","startDate":"2030-12-31","endDate":"2030-01-01"}]}', ScorecardNo), 0);
        AssertRefusal(Response, 'InvalidParameter');
        Assert.IsTrue(Response.GetText('error').StartsWith('InvalidPeriod'), Serialize(Response));
        Assert.IsFalse(Scorecard.Get(ScorecardNo), 'A refusal must not create the scorecard.');
        Cleanup(ScorecardNo, OwnerId);
    end;

    /// <summary>A baseline period after the goal period is refused as an invalid period.</summary>
    [Test]
    procedure Scenario_AC04_BaselineAfterGoal_Refused()
    var
        Scorecard: Record "Sustainability Scorecard";
        Response: JsonObject;
        ScorecardNo: Code[20];
        OwnerId: Code[50];
    begin
        // Story #6, AC04 | Time: fixed dates | Risk: refusal leaves no data
        Initialize(ScorecardNo, OwnerId);
        Response := Invoke(StrSubstNo('{"scorecardNo":"%1","goals":[{"no":"G1","baselineStartDate":"2031-01-01","baselineEndDate":"2031-12-31","startDate":"2030-01-01","endDate":"2030-12-31"}]}', ScorecardNo), 1039);
        AssertRefusal(Response, 'InvalidParameter');
        Assert.IsTrue(Response.GetText('error').StartsWith('InvalidPeriod'), Serialize(Response));
        Assert.IsFalse(Scorecard.Get(ScorecardNo), 'A refusal must not create the scorecard.');
        Cleanup(ScorecardNo, OwnerId);
    end;

    /// <summary>An unknown owner is refused with the Business Central message and the scorecard insert is rolled back.</summary>
    [Test]
    procedure Scenario_AC04_UnknownOwner_RolledBack()
    var
        Scorecard: Record "Sustainability Scorecard";
        Response: JsonObject;
        ScorecardNo: Code[20];
        OwnerId: Code[50];
    begin
        // Story #6, AC04 | Time: no date-dependent inputs | Risk: refusal leaves no partial data
        Initialize(ScorecardNo, OwnerId);
        Response := Invoke(StrSubstNo('{"scorecardNo":"%1","name":"Owner test","owner":"NOSUCHUSER-%2"}', ScorecardNo, CopyStr(ScorecardNo, 3, 8)), 0);
        AssertRefusal(Response, 'BusinessCentralError');
        Assert.AreNotEqual('', Response.GetText('error'), 'The Business Central message must be returned.');
        Assert.IsFalse(Scorecard.Get(ScorecardNo), 'The scorecard insert must be rolled back.');
        Cleanup(ScorecardNo, OwnerId);
    end;

    /// <summary>Unknown keys at the top level and inside a goal are refused before anything is written.</summary>
    [Test]
    procedure Scenario_AC05_UnknownKeys_Refused()
    var
        Scorecard: Record "Sustainability Scorecard";
        Response: JsonObject;
        ScorecardNo: Code[20];
        OwnerId: Code[50];
    begin
        // Story #6, AC05 | Time: no date-dependent inputs | Risk: refusal leaves no data
        Initialize(ScorecardNo, OwnerId);
        Response := Invoke(StrSubstNo('{"scorecardNo":"%1","nmae":"Typo"}', ScorecardNo), 0);
        AssertRefusal(Response, 'UnknownParameter');
        Response := Invoke(StrSubstNo('{"scorecardNo":"%1","goals":[{"no":"G1","targetC02":1}]}', ScorecardNo), 0);
        AssertRefusal(Response, 'UnknownParameter');
        Assert.IsFalse(Scorecard.Get(ScorecardNo), 'A refusal must not create the scorecard.');
        Cleanup(ScorecardNo, OwnerId);
    end;

    local procedure Initialize(var ScorecardNo: Code[20]; var OwnerId: Code[50])
    var
        UserSetup: Record "User Setup";
        Suffix: Text;
    begin
        EnsureSetup();
        Suffix := DelChr(Format(CreateGuid(), 0, 4), '=', '-');
        ScorecardNo := CopyStr('SC6-' + Suffix, 1, MaxStrLen(ScorecardNo));
        OwnerId := CopyStr('SUST6-' + Suffix, 1, 20);
        UserSetup.Init();
        UserSetup."User ID" := OwnerId;
        UserSetup."Sustainability Manager" := true;
        UserSetup.Insert();
        Commit();
    end;

    local procedure EnsureSetup()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        BifrostSetup: Record "Setup ori";
    begin
        BifrostSetup.InsertIfNotExists();
        if not SustainabilitySetup.Get() then begin
            SustainabilitySetup.Init();
            SustainabilitySetup.Insert();
        end;
        Commit();
    end;

    local procedure Cleanup(ScorecardNo: Code[20]; OwnerId: Code[50])
    var
        Goal: Record "Sustainability Goal";
        Scorecard: Record "Sustainability Scorecard";
        UserSetup: Record "User Setup";
    begin
        Goal.SetRange("Scorecard No.", ScorecardNo);
        Goal.DeleteAll();
        if Scorecard.Get(ScorecardNo) then
            Scorecard.Delete();
        if UserSetup.Get(OwnerId) then
            UserSetup.Delete();
        Commit();
    end;

    local procedure FullRequest(ScorecardNo: Code[20]; OwnerId: Code[50]; MainGoal: Boolean): Text
    var
        Request: JsonObject;
        Goal: JsonObject;
        Goals: JsonArray;
    begin
        Request.Add('scorecardNo', ScorecardNo);
        Request.Add('name', 'Net zero test');
        Request.Add('owner', OwnerId);
        Goal.Add('no', 'G-CO2');
        Goal.Add('name', 'Cut CO2');
        Goal.Add('baselineStartDate', '2024-01-01');
        Goal.Add('baselineEndDate', '2024-12-31');
        Goal.Add('startDate', '2030-01-01');
        Goal.Add('endDate', '2030-12-31');
        Goal.Add('targetCO2', 500);
        Goal.Add('targetWaterIntensity', 12.5);
        if MainGoal then
            Goal.Add('mainGoal', not AnotherMainGoalExists());
        Goals.Add(Goal);
        Request.Add('goals', Goals);
        exit(Serialize(Request));
    end;

    local procedure AnotherMainGoalExists(): Boolean
    var
        Goal: Record "Sustainability Goal";
    begin
        Goal.SetRange("Main Goal", true);
        exit(not Goal.IsEmpty());
    end;

    local procedure AssertRefusal(Response: JsonObject; ExpectedCode: Text)
    begin
        Assert.AreEqual('Error', Response.GetText('status'), Serialize(Response));
        Assert.AreEqual(ExpectedCode, Response.GetText('code'), Serialize(Response));
    end;

    local procedure Serialize(Value: JsonObject) Result: Text
    begin
        Value.WriteTo(Result);
    end;

    local procedure Invoke(RequestText: Text; LanguageId: Integer) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        ResponseContentType: Text[100];
        ResponseText: Text;
        EmptyTaskId: Guid;
        MessageId: Guid;
        ResponseTime: Duration;
    begin
        RequestContent.AddText(RequestText);
        if LanguageId = 0 then
            Dispatcher.Execute(Enum::"Message Type ori"::"Sustainability.Goal.Set", Enum::"Message Version ori"::"1.0", '', 'issue6-tests', 'application/json', RequestContent, ResponseContent, ResponseContentType, false)
        else
            Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Goal.Set", Enum::"Message Version ori"::"1.0", '', 'issue6-tests', 'application/json', RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;
}
