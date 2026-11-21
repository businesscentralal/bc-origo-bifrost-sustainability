namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Foundation.UOM;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Checks journal readiness through the public dispatcher in English and Icelandic.</summary>
codeunit 98045 "Sust Journal Check Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        TemplateName: Code[10];
        BatchName: Code[10];
        AccountNo: Code[20];

    /// <summary>Valid batches are ready and repeated checks leave journal and ledger state unchanged.</summary>
    [Test]
    procedure Scenario_AC03_AC06_ReadyAndIdempotent()
    var
        Line: Record "Sustainability Jnl. Line";
        Ledger: Record "Sustainability Ledger Entry";
        Response: JsonObject;
        Token: JsonToken;
        LedgerCount: Integer;
        OriginalId: Guid;
        OriginalModifiedAt: DateTime;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Line.Get(TemplateName, BatchName, 10000);
            OriginalId := Line.SystemId;
            OriginalModifiedAt := Line.SystemModifiedAt;
            LedgerCount := Ledger.Count();
            Response := Dispatch(Request());
            AssertReady(Response, true, 1);
            Response.Get('journalErrors', Token);
            Assert.AreEqual(0, Token.AsArray().Count(), 'Valid batch has no validation errors.');
            Response := Dispatch(Request());
            AssertReady(Response, true, 1);
            Assert.AreEqual(LedgerCount, Ledger.Count(), 'Check must not post ledger entries.');
            Line.Get(TemplateName, BatchName, 10000);
            Assert.AreEqual(OriginalId, Line.SystemId, 'Check must not recreate lines.');
            Assert.AreEqual(OriginalModifiedAt, Line.SystemModifiedAt, 'Check must not modify lines.');
            Assert.AreEqual(10, Line."Emission CO2", 'Check must preserve emissions.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Errors from multiple lines include their line and field, without changing the lines.</summary>
    [Test]
    procedure Scenario_AC03_CollectsEveryLine()
    var
        Line: Record "Sustainability Jnl. Line";
        Response: JsonObject;
        Token: JsonToken;
        Row: JsonToken;
        Field: JsonToken;
        FirstFound: Boolean;
        SecondFound: Boolean;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Line.Get(TemplateName, BatchName, 10000);
            Line."Posting Date" := 0D;
            Line.Description := '';
            Line.Modify();
            Line."Line No." := 20000;
            Line.Insert();
            Commit();
            Response := Dispatch(Request());
            AssertReady(Response, false, 2);
            Response.Get('journalErrors', Token);
            Assert.IsTrue(Token.AsArray().Count() >= 4, 'Both invalid fields on both lines must be reported.');
            FirstFound := false;
            SecondFound := false;
            foreach Row in Token.AsArray() do begin
                Assert.IsTrue(Row.AsObject().Get('fieldName', Field), 'Every error describes its field.');
                Assert.IsTrue(Row.AsObject().Get('message', Field), 'Every error has a message.');
                Assert.AreNotEqual('', Field.AsValue().AsText(), 'Error message must not be blank.');
                Row.AsObject().Get('lineNo', Field);
                FirstFound := FirstFound or (Field.AsValue().AsInteger() = 10000);
                SecondFound := SecondFound or (Field.AsValue().AsInteger() = 20000);
            end;
            Assert.IsTrue(FirstFound and SecondFound, 'Errors must identify both source lines.');
            Line.Get(TemplateName, BatchName, 10000);
            Assert.AreEqual(0D, Line."Posting Date", 'Validation must not repair lines.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>An empty batch is a successful check with one explanatory message.</summary>
    [Test]
    procedure Scenario_AC04_EmptyBatch()
    var
        Line: Record "Sustainability Jnl. Line";
        Response: JsonObject;
        Token: JsonToken;
        Row: JsonObject;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            Line.Get(TemplateName, BatchName, 10000);
            Line.Delete();
            Commit();
            Response := Dispatch(Request());
            AssertReady(Response, false, 0);
            Response.Get('journalErrors', Token);
            Assert.AreEqual(1, Token.AsArray().Count(), 'Empty batch has exactly one message.');
            Token.AsArray().Get(0, Token);
            Row := Token.AsObject();
            if LanguageId = 1039 then
                AssertText(Row, 'message', 'Keyrsla sjálfbærnibókar hefur engar línur.')
            else
                AssertText(Row, 'message', 'The sustainability journal batch has no lines.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Unknown templates and batches use the canonical RecordNotFound refusal.</summary>
    [Test]
    procedure Scenario_AC04_UnknownTemplateAndBatch()
    var
        LanguageId: Integer;
        Response: JsonObject;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            AssertRefusal('{"templateName":"XUNKNOWN","batchName":"XUNKNOWN"}', 'RecordNotFound');
            Response := Dispatch('{"templateName":"XCHECK","batchName":"XUNKNOWN"}');
            AssertText(Response, 'code', 'RecordNotFound');
            AssertText(Response, 'received', 'XCHECK/XUNKNOWN');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Unknown keys, non-string values, empty and overlength codes are refused.</summary>
    [Test]
    procedure Scenario_AC05_RejectInvalidParameters()
    var
        LanguageId: Integer;
        Invalid: Text;
        InvalidValues: List of [Text];
    begin
        InvalidValues.Add('null');
        InvalidValues.Add('123');
        InvalidValues.Add('true');
        InvalidValues.Add('{}');
        InvalidValues.Add('[]');
        InvalidValues.Add('""');
        InvalidValues.Add('"   "');
        InvalidValues.Add('"X1234567890"');
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            AssertRefusal('{"templateName":"XCHECK","batchName":"XDEFAULT","batchNmae":"XDEFAULT"}', 'UnknownParameter');
            AssertRefusal('{}', 'InvalidParameter');
            AssertRefusal('{"templateName":"XCHECK"}', 'InvalidParameter');
            foreach Invalid in InvalidValues do begin
                AssertRefusal('{"templateName":' + Invalid + ',"batchName":"XDEFAULT"}', 'InvalidParameter');
                AssertRefusal('{"templateName":"XCHECK","batchName":' + Invalid + '}', 'InvalidParameter');
            end;
            // Exactly 10 characters is a valid code, even if no matching batch exists.
            AssertRefusal('{"templateName":"X123456789","batchName":"X123456789"}', 'RecordNotFound');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>The read role can check with no direct journal-write permission.</summary>
    [Test]
    procedure Scenario_ACP_ReadRoleCanCheck()
    var
        Line: Record "Sustainability Jnl. Line";
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            LowerPermissions.SetExactPermissionSet('D365 READ');
            LowerPermissions.AddPermissionSet('BIFROST Read ori');
            Assert.IsFalse(Line.WritePermission(), 'The read role must not grant direct journal writes.');
            AssertReady(Dispatch(Request()), true, 1);
            LowerPermissions.SetOutsideO365Scope();
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>Validation subscribers cannot persist changes in a read-only check.</summary>
    [Test]
    procedure Scenario_AC06_RejectsSubscriberWrites()
    var
        Line: Record "Sustainability Jnl. Line";
        Ledger: Record "Sustainability Ledger Entry";
        Subscriber: Codeunit "Sust Check Mutation Tst ori";
        LedgerCount: Integer;
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Seed();
            LedgerCount := Ledger.Count();
            BindSubscription(Subscriber);
            AssertRefusal(Request(), 'BusinessCentralError');
            UnbindSubscription(Subscriber);
            Line.Get(TemplateName, BatchName, 10000);
            Assert.AreEqual('CRONUS check test', Line.Description, 'Subscriber changes must be rolled back.');
            Assert.AreEqual(LedgerCount, Ledger.Count(), 'No ledger changes may survive.');
        end;
        GlobalLanguage(1033);
    end;

    /// <summary>The public help surface validates the closed Foundation error contract.</summary>
    [Test]
    procedure Scenario_ACH_PublicHelpBothLanguages()
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
        LanguageId: Integer;
    begin
        foreach LanguageId in Languages() do begin
            Initialize(LanguageId);
            Clear(Input);
            Clear(Output);
            Input.AddText('{}');
            Commit();
            Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Help.Implementation.Get", Enum::"Message Version ori"::"1.0", 'Sustainability.Journal.Check', 'XSUSTCHECK', 'text/json', Input, TaskId, LanguageId, MessageId, Output, ContentType, ResponseTime);
            Output.GetSubText(ResponseText, 1);
            Assert.IsTrue(Response.ReadFrom(ResponseText), 'Public help must return JSON.');
            AssertText(Response, 'status', 'Success');
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
            MessageType := MessageType::"Sustainability.Journal.Check";
            Discovery := MessageType;
            Assert.IsFalse(Discovery.IsEnabled(), 'Unconfigured type must be hidden.');
            Assert.IsFalse(IsInRoster(), 'The public roster must omit the unconfigured type.');
            AssertRefusal('{"templateName":"XUNKNOWN","batchName":"XUNKNOWN"}', 'RecordNotFound');
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
            LowerPermissions.AddPermissionSet('Sust Chk Denied ori');
            MessageType := MessageType::"Sustainability.Journal.Check";
            Discovery := MessageType;
            Assert.IsFalse(Discovery.IsEnabled(), 'A user without capability permission must not discover the type.');
            AssertRefusal(Request(), 'PermissionDenied');
            LowerPermissions.SetOutsideO365Scope();
        end;
        GlobalLanguage(1033);
    end;

    local procedure AssertReady(Response: JsonObject; Expected: Boolean; ExpectedCount: Integer)
    var
        Token: JsonToken;
    begin
        AssertText(Response, 'status', 'Success');
        Response.Get('ready', Token);
        Assert.AreEqual(Expected, Token.AsValue().AsBoolean(), 'Unexpected batch readiness.');
        Response.Get('lineCount', Token);
        Assert.AreEqual(ExpectedCount, Token.AsValue().AsInteger(), 'Every batch line must be counted.');
    end;

    local procedure Initialize(LanguageId: Integer)
    begin
        // Assumption: Foundation Tests installed and EULA approved on the worker's own tenant.
        LowerPermissions.SetOutsideO365Scope();
        GlobalLanguage(LanguageId);
        TemplateName := 'XCHECK';
        BatchName := 'XDEFAULT';
        AccountNo := 'XCHECK';
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
            Account.Name := 'CRONUS check test';
            Account.Category := AccountNo;
            Account.Subcategory := AccountNo;
            Account."Account Type" := Account."Account Type"::Posting;
            Account."Direct Posting" := true;
            Account.Insert();
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
        Line.SetRange("Journal Template Name", TemplateName);
        Line.SetRange("Journal Batch Name", BatchName);
        Line.DeleteAll();
        Line.Init();
        Line."Journal Template Name" := TemplateName;
        Line."Journal Batch Name" := BatchName;
        Line."Line No." := 10000;
        Line."Posting Date" := DMY2Date(15, 1, 2026);
        Line."Document No." := 'XCHECK-001';
        Line.Description := 'CRONUS check test';
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
        exit('{"templateName":"XCHECK","batchName":"XDEFAULT"}');
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Journal.Check", Enum::"Message Version ori"::"1.0", '', 'XSUSTCHECK', 'text/json', Input, TaskId, GlobalLanguage(), MessageId, Output, ContentType, ResponseTime);
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
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Help.MessageTypes.Get", Enum::"Message Version ori"::"1.0", '', 'XSUSTCHECK', 'text/json', Input, TaskId, GlobalLanguage(), MessageId, Output, ContentType, ResponseTime);
        Output.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
        AssertText(Response, 'status', 'Success');
        Response.Get('result', Token);
        foreach Row in Token.AsArray() do begin
            Row.AsObject().Get('name', Name);
            if Name.AsValue().AsText() = 'Sustainability.Journal.Check' then
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
