namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.Automation;
using System.Security.User;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Exercises journal preview through the public dispatcher in English and Icelandic.</summary>
codeunit 98050 "Sust Preview Post Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        TemplateName: Code[10];
        BatchName: Code[10];
        AccountNo: Code[20];

    /// <summary>Valid preview returns standard emissions and preserves all persisted inputs.</summary>
    [Test]
    procedure Scenario_AC03_AC06_PreviewRollsBackBothLanguages()
    var
        Line: Record "Sustainability Jnl. Line";
        Ledger: Record "Sustainability Ledger Entry";
        Values: Record "Sustainability Value Entry";
        Series: Record "No. Series Line";
        Response: JsonObject;
        Row: JsonObject;
        Token: JsonToken;
        LedgerCount: Integer;
        ValueCount: Integer;
        OriginalSystemId: Guid;
        OriginalModifiedAt: DateTime;
        LanguageId: Integer;
    begin
        // [SCENARIO] AC03/AC06: real posting logic is captured, then rolled back.
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Line.Get(TemplateName, BatchName, 10000);
            OriginalSystemId := Line.SystemId;
            OriginalModifiedAt := Line.SystemModifiedAt;
            LedgerCount := Ledger.Count();
            ValueCount := Values.Count();
            Commit();
            // [WHEN] Preview is called twice with the same batch.
            Response := Dispatch(Request());
            AssertText(Response, 'status', 'Success');
            Response.Get('entries', Token);
            Assert.AreEqual(1, Token.AsArray().Count(), 'One ledger entry should be previewed.');
            Token.AsArray().Get(0, Token);
            Row := Token.AsObject();
            AssertText(Row, 'documentNo', 'XPREVIEW-001');
            AssertText(Row, 'accountNo', AccountNo);
            Row.Get('CO2', Token);
            Assert.AreEqual(10, Token.AsValue().AsDecimal(), 'Preview must use the standard CO2 value.');
            Row.Get('CH4', Token);
            Assert.AreEqual(2, Token.AsValue().AsDecimal(), 'Preview must preserve CH4.');
            Response := Dispatch(Request());
            AssertText(Response, 'status', 'Success');
            // [THEN] Neither entries, lines, system fields nor number-series state changed.
            Assert.AreEqual(LedgerCount, Ledger.Count(), 'Preview must not post ledger entries.');
            Assert.AreEqual(ValueCount, Values.Count(), 'Preview must not post value entries.');
            Line.Get(TemplateName, BatchName, 10000);
            Assert.AreEqual(OriginalSystemId, Line.SystemId, 'Preview must not recreate journal lines.');
            Assert.AreEqual(OriginalModifiedAt, Line.SystemModifiedAt, 'Preview must not modify journal lines.');
            Assert.AreEqual(10, Line."Emission CO2", 'The journal emissions must remain unchanged.');
            Series.Get(TemplateName, 10000);
            Assert.AreEqual('', Series."Last No. Used", 'Preview must not consume a number.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>The read role can preview without receiving direct journal-write permission.</summary>
    [Test]
    procedure Scenario_ACP_ReadRoleCanPreview()
    var
        Line: Record "Sustainability Jnl. Line";
        Response: JsonObject;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            LowerPermissions.SetExactPermissionSet('D365 READ');
            LowerPermissions.AddPermissionSet('BIFROST Read ori');
            Assert.IsFalse(Line.WritePermission(), 'The read role must not grant direct journal writes.');
            Response := Dispatch(Request());
            AssertText(Response, 'status', 'Success');
            LowerPermissions.SetOutsideO365Scope();
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>All lines are processed before the preview stops at deletion.</summary>
    [Test]
    procedure Scenario_AC06_MultipleLinesPreviewWithoutDeletion()
    var
        Line: Record "Sustainability Jnl. Line";
        Ledger: Record "Sustainability Ledger Entry";
        Response: JsonObject;
        Token: JsonToken;
        TotalCO2: JsonToken;
        LedgerCount: Integer;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Line.Get(TemplateName, BatchName, 10000);
            Line."Line No." := 20000;
            Line."Document No." := 'XPREVIEW-002';
            Line."Emission CO2" := 5;
            Line.Insert();
            LedgerCount := Ledger.Count();
            Commit();
            Response := Dispatch(Request());
            AssertText(Response, 'status', 'Success');
            Response.Get('entries', Token);
            Assert.AreEqual(2, Token.AsArray().Count(), 'Every line must be previewed before rollback.');
            Response.Get('totals', Token);
            Token.AsObject().Get('CO2', TotalCO2);
            Assert.AreEqual(15, TotalCO2.AsValue().AsDecimal(), 'Totals must include both lines.');
            Assert.AreEqual(LedgerCount, Ledger.Count(), 'No ledger entry may be committed.');
            Line.SetRange("Journal Template Name", TemplateName);
            Line.SetRange("Journal Batch Name", BatchName);
            Assert.AreEqual(2, Line.Count(), 'Both persisted journal lines must remain.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>A late approval refusal rolls back number-series updates and captured entries.</summary>
    [Test]
    procedure Scenario_AC04_OpenApprovalRollsBackLateFailure()
    var
        Approval: Record "Approval Entry";
        UserSetup: Record "User Setup";
        Batch: Record "Sustainability Jnl. Batch";
        Line: Record "Sustainability Jnl. Line";
        Ledger: Record "Sustainability Ledger Entry";
        Series: Record "No. Series Line";
        EntryNo: Integer;
        LedgerCount: Integer;
        LanguageId: Integer;
        CreatedUserSetup: Boolean;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Batch.Get(TemplateName, BatchName);
            CreatedUserSetup := not UserSetup.Get(UserId());
            if CreatedUserSetup then begin
                UserSetup.Init();
                UserSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID"));
                UserSetup.Insert();
            end;
            EntryNo := 1;
            if Approval.FindLast() then
                EntryNo := Approval."Entry No." + 1;
            Approval.Init();
            Approval."Entry No." := EntryNo;
            Approval."Table ID" := Database::"Sustainability Jnl. Batch";
            Approval."Record ID to Approve" := Batch.RecordId();
            Approval.Status := Approval.Status::Open;
            Approval."Sender ID" := CopyStr(UserId(), 1, MaxStrLen(Approval."Sender ID"));
            Approval."Approver ID" := CopyStr(UserId(), 1, MaxStrLen(Approval."Approver ID"));
            Approval.Insert();
            LedgerCount := Ledger.Count();
            Commit();
            AssertRefusal(Request(), 'BusinessCentralError');
            Assert.AreEqual(LedgerCount, Ledger.Count(), 'A late refusal must not commit a ledger entry.');
            Assert.IsTrue(Line.Get(TemplateName, BatchName, 10000), 'Approval refusal must preserve the journal line.');
            Series.Get(TemplateName, 10000);
            Assert.AreEqual('', Series."Last No. Used", 'Approval refusal must roll back number-series updates.');
            Approval.Get(EntryNo);
            Assert.AreEqual(Approval.Status::Open, Approval.Status, 'Preview must not cancel approvals.');
            Approval.Delete();
            if CreatedUserSetup then
                UserSetup.Delete();
            Commit();
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Unknown templates and batches are explicit refusals.</summary>
    [Test]
    procedure Scenario_AC04_UnknownTemplateAndBatch()
    var
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            AssertRefusal('{"templateName":"XUNKNOWN","batchName":"XUNKNOWN"}', 'BatchNotFound');
            AssertRefusal('{"templateName":"XPREVIEW","batchName":"XUNKNOWN"}', 'BatchNotFound');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Empty journals return JournalNotReady without posting.</summary>
    [Test]
    procedure Scenario_AC04_EmptyBatch()
    var
        Line: Record "Sustainability Jnl. Line";
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Line.Get(TemplateName, BatchName, 10000);
            Line.Delete();
            Commit();
            AssertRefusal(Request(), 'JournalNotReady');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Standard line validation errors are returned as a translated error list.</summary>
    [Test]
    procedure Scenario_AC04_InvalidJournalLine()
    var
        Line: Record "Sustainability Jnl. Line";
        Response: JsonObject;
        Token: JsonToken;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Line.Get(TemplateName, BatchName, 10000);
            Line."Posting Date" := 0D;
            Line.Description := '';
            Line.Modify();
            Commit();
            Response := Dispatch(Request());
            AssertText(Response, 'code', 'JournalNotReady');
            Assert.IsTrue(Response.Get('journalErrors', Token), 'Standard errors must be included.');
            Assert.IsTrue(Token.AsArray().Count() >= 2, 'Both invalid fields must be reported.');
            Assert.IsTrue(Line.Get(TemplateName, BatchName, 10000), 'Refusal must preserve the line.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>A posting-only number-series failure is caught and rolled back.</summary>
    [Test]
    procedure Scenario_AC04_PostingError()
    var
        Batch: Record "Sustainability Jnl. Batch";
        Ledger: Record "Sustainability Ledger Entry";
        Line: Record "Sustainability Jnl. Line";
        LedgerCount: Integer;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Batch.Get(TemplateName, BatchName);
            Batch."No Series" := 'XMISSING';
            Batch.Modify();
            LedgerCount := Ledger.Count();
            Commit();
            AssertRefusal(Request(), 'BusinessCentralError');
            Assert.AreEqual(LedgerCount, Ledger.Count(), 'Posting error must roll back ledger entries.');
            Assert.IsTrue(Line.Get(TemplateName, BatchName, 10000), 'Posting error must preserve the line.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Unknown keys and invalid values never reach posting.</summary>
    [Test]
    procedure Scenario_AC05_RejectUnknownAndInvalidParameters()
    var
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            AssertRefusal('{"templateName":"XPREVIEW","batchName":"XDEFAULT","batchNmae":"XDEFAULT"}', 'UnknownParameter');
            AssertRefusal('{"templateName":"XPREVIEW"}', 'InvalidParameter');
            AssertRefusal('{"templateName":123,"batchName":"XDEFAULT"}', 'InvalidParameter');
            AssertRefusal('{"templateName":"TOO-LONG-CODE","batchName":"XDEFAULT"}', 'InvalidParameter');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Hiding an unconfigured type does not block a known invocation.</summary>
    [Test]
    procedure Scenario_ACV_UnconfiguredHiddenButCallable()
    var
        Account: Record "Sustainability Account";
        Setup: Record "Sustainability Setup";
        Discovery: Interface "Msg Interface ori";
        MessageType: Enum "Message Type ori";
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Account.DeleteAll();
            if not Setup.Get() then
                Setup.Insert();
            Setup."Emission Unit of Measure Code" := '';
            Setup.Modify();
            Commit();
            MessageType := MessageType::"Sustainability.Journal.PreviewPost";
            Discovery := MessageType;
            Assert.IsFalse(Discovery.IsEnabled(), 'Unconfigured type must be hidden.');
            Assert.IsFalse(IsInRoster(), 'The public roster must omit the unconfigured type.');
            AssertRefusal('{"templateName":"XUNKNOWN","batchName":"XUNKNOWN"}', 'BatchNotFound');
            Seed();
            Assert.IsTrue(Discovery.IsEnabled(), 'A configured company must expose the type.');
            Assert.IsTrue(IsInRoster(), 'The public roster must include the configured type.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Missing capability permission hides the type and refuses dispatcher execution.</summary>
    [Test]
    procedure Scenario_ACP_NoCapabilityPermission()
    var
        Discovery: Interface "Msg Interface ori";
        MessageType: Enum "Message Type ori";
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            LowerPermissions.SetExactPermissionSet('BIFROST LicAdm ori');
            LowerPermissions.AddPermissionSet('Sust Prev Denied ori');
            MessageType := MessageType::"Sustainability.Journal.PreviewPost";
            Discovery := MessageType;
            Assert.IsFalse(Discovery.IsEnabled(), 'A user without capability permission must not discover the type.');
            AssertRefusal(Request(), 'PermissionDenied');
            LowerPermissions.SetOutsideO365Scope();
        end;
        GlobalLanguage(1033);
    end;

    local procedure Initialize(LanguageId: Integer)
    begin
        // Assumption: Foundation Tests installed and EULA approved on the worker's own tenant.
        LowerPermissions.SetOutsideO365Scope();
        GlobalLanguage(LanguageId);
        TemplateName := 'XPREVIEW';
        BatchName := 'XDEFAULT';
        AccountNo := 'XPREVIEW';
    end;

    local procedure Languages() Result: List of [Integer]
    begin
        Result.Add(1033);
        Result.Add(1039);
    end;

    local procedure Seed()
    var
        Setup: Record "Sustainability Setup";
        Category: Record "Sustain. Account Category";
        Subcategory: Record "Sustain. Account Subcategory";
        Account: Record "Sustainability Account";
        JournalTemplate: Record "Sustainability Jnl. Template";
        Batch: Record "Sustainability Jnl. Batch";
        Line: Record "Sustainability Jnl. Line";
        UOM: Record "Unit of Measure";
        NoSeries: Record "No. Series";
        SeriesLine: Record "No. Series Line";
    begin
        if not Setup.Get() then
            Setup.Insert();
        Setup."Country/Region Mandatory" := false;
        Setup."Resp. Center Mandatory" := false;
        Setup.Modify();
        if not UOM.Get('XKG') then begin
            UOM.Code := 'XKG';
            UOM.Insert();
        end;
        if not Category.Get(AccountNo) then begin
            Category.Code := AccountNo;
            Category."Emission Scope" := Category."Emission Scope"::"Scope 1";
            Category.CO2 := true;
            Category.CH4 := true;
            Category.N2O := true;
            Category.Insert();
        end;
        if not Subcategory.Get(AccountNo, AccountNo) then begin
            Subcategory."Category Code" := AccountNo;
            Subcategory.Code := AccountNo;
            Subcategory.Insert();
        end;
        if not Account.Get(AccountNo) then begin
            Account."No." := AccountNo;
            Account.Name := 'CRONUS preview test';
            Account.Category := AccountNo;
            Account.Subcategory := AccountNo;
            Account."Account Type" := Account."Account Type"::Posting;
            Account."Direct Posting" := true;
            Account.Insert();
        end;
        if not NoSeries.Get(TemplateName) then begin
            NoSeries.Code := TemplateName;
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := true;
            NoSeries.Insert();
            SeriesLine."Series Code" := TemplateName;
            SeriesLine."Line No." := 10000;
            SeriesLine."Starting No." := 'XPREVIEW-001';
            SeriesLine."Ending No." := 'XPREVIEW-999';
            SeriesLine."Increment-by No." := 1;
            SeriesLine.Open := true;
            SeriesLine.Insert();
        end;
        if not JournalTemplate.Get(TemplateName) then begin
            JournalTemplate.Name := TemplateName;
            JournalTemplate.Insert();
        end;
        if not Batch.Get(TemplateName, BatchName) then begin
            Batch."Journal Template Name" := TemplateName;
            Batch.Name := BatchName;
            Batch.Insert();
        end;
        Batch."No Series" := TemplateName;
        Batch.Modify();
        Line.SetRange("Journal Template Name", TemplateName);
        Line.SetRange("Journal Batch Name", BatchName);
        Line.DeleteAll();
        Line.Init();
        Line."Journal Template Name" := TemplateName;
        Line."Journal Batch Name" := BatchName;
        Line."Line No." := 10000;
        Line."Posting Date" := DMY2Date(15, 1, 2026);
        Line."Document No." := 'XPREVIEW-001';
        Line.Description := 'CRONUS preview test';
        Line."Account No." := AccountNo;
        Line."Account Category" := AccountNo;
        Line."Account Subcategory" := AccountNo;
        Line."Unit of Measure" := 'XKG';
        Line."Manual Input" := true;
        Line."Emission CO2" := 10;
        Line."Emission CH4" := 2;
        Line."Emission N2O" := 1;
        Line.Insert();
        Commit();
    end;

    local procedure Request(): Text
    begin
        exit('{"templateName":"XPREVIEW","batchName":"XDEFAULT"}');
    end;

    local procedure Dispatch(RequestText: Text) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        Input: BigText;
        Output: BigText;
        ContentType: Text[100];
        ResponseText: Text;
        MessageId: Guid;
        TaskId: Guid;
        ResponseTime: Duration;
    begin
        Input.AddText(RequestText);
        Commit();
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Journal.PreviewPost", Enum::"Message Version ori"::"1.0", '', 'XSUSTPREVIEW', 'text/json', Input, TaskId, GlobalLanguage(), MessageId, Output, ContentType, ResponseTime);
        Output.GetSubText(ResponseText, 1);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'Dispatcher must return JSON: ' + ResponseText);
    end;

    local procedure IsInRoster(): Boolean
    var
        Dispatcher: Codeunit "Dispatcher ori";
        Input: BigText;
        Output: BigText;
        ContentType: Text[100];
        ResponseText: Text;
        MessageId: Guid;
        TaskId: Guid;
        ResponseTime: Duration;
        Response: JsonObject;
        Token: JsonToken;
        Row: JsonToken;
        Name: JsonToken;
    begin
        Input.AddText('{"onlyEnabled":true}');
        Commit();
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Help.MessageTypes.Get", Enum::"Message Version ori"::"1.0", '', 'XSUSTPREVIEW', 'text/json', Input, TaskId, GlobalLanguage(), MessageId, Output, ContentType, ResponseTime);
        Output.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
        AssertText(Response, 'status', 'Success');
        Response.Get('result', Token);
        foreach Row in Token.AsArray() do begin
            Row.AsObject().Get('name', Name);
            if Name.AsValue().AsText() = 'Sustainability.Journal.PreviewPost' then
                exit(true);
        end;
        exit(false);
    end;

    local procedure AssertRefusal(RequestText: Text; ExpectedCode: Text)
    var
        Response: JsonObject;
    begin
        Response := Dispatch(RequestText);
        AssertText(Response, 'status', 'Error');
        AssertText(Response, 'code', ExpectedCode);
    end;

    local procedure AssertText(Response: JsonObject; Name: Text; Expected: Text)
    var
        Token: JsonToken;
        ActualResponse: Text;
    begin
        Response.WriteTo(ActualResponse);
        Assert.IsTrue(Response.Get(Name, Token), 'Missing ' + Name + ': ' + ActualResponse);
        Assert.AreEqual(Expected, Token.AsValue().AsText(), ActualResponse);
    end;
}
