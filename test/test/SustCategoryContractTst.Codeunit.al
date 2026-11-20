namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>Checks the shared visibility gate, permission capability and complete bilingual contracts.</summary>
codeunit 98031 "Sust Category Contract Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Verifies setup discovery and contract behavior in language 1033.</summary>
    [Test]
    procedure Scenario_AC_setup_1033()
    begin
        VerifyVisibility('setup', 1033);
    end;

    /// <summary>Verifies setup discovery and contract behavior in language 1039.</summary>
    [Test]
    procedure Scenario_AC_setup_1039()
    begin
        VerifyVisibility('setup', 1039);
    end;

    /// <summary>Verifies account discovery and contract behavior in language 1033.</summary>
    [Test]
    procedure Scenario_AC_account_1033()
    begin
        VerifyVisibility('account', 1033);
    end;

    /// <summary>Verifies account discovery and contract behavior in language 1039.</summary>
    [Test]
    procedure Scenario_AC_account_1039()
    begin
        VerifyVisibility('account', 1039);
    end;

    /// <summary>Verifies empty discovery and contract behavior in language 1033.</summary>
    [Test]
    procedure Scenario_AC_empty_1033()
    begin
        VerifyVisibility('empty', 1033);
    end;

    /// <summary>Verifies empty discovery and contract behavior in language 1039.</summary>
    [Test]
    procedure Scenario_AC_empty_1039()
    begin
        VerifyVisibility('empty', 1039);
    end;

    /// <summary>Verifies read discovery and contract behavior in language 1033.</summary>
    [Test]
    procedure Scenario_AC_read_1033()
    begin
        VerifyVisibility('read', 1033);
    end;

    /// <summary>Verifies read discovery and contract behavior in language 1039.</summary>
    [Test]
    procedure Scenario_AC_read_1039()
    begin
        VerifyVisibility('read', 1039);
    end;

    /// <summary>Verifies contract discovery and contract behavior in language 1033.</summary>
    [Test]
    procedure Scenario_AC_contract_1033()
    begin
        VerifyContract(1033);
    end;

    /// <summary>Verifies contract discovery and contract behavior in language 1039.</summary>
    [Test]
    procedure Scenario_AC_contract_1039()
    begin
        VerifyContract(1039);
    end;

    local procedure VerifyVisibility(Mode: Text; LanguageId: Integer)
    var
        Setup: Record "Sustainability Setup";
        Account: Record "Sustainability Account";
        Category: Record "Sustain. Account Category";
        MessageInterface: Interface "Msg Interface ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        IsVisible: Boolean;
    begin
        // #5 AC-V and AC-P | Test-runner rollback only: no explicit Commit in this codeunit.
        LowerPermissions.SetOutsideO365Scope();
        // Temporarily isolate configuration inside the test runner's rollback transaction.
        Account.DeleteAll(false);
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(false);
        end;
        Setup."Emission Unit of Measure Code" := '';
        if Mode in ['setup', 'read'] then
            Setup."Emission Unit of Measure Code" := 'XCAT5';
        Setup.Modify(false);
        if Mode = 'account' then begin
            Account.Init();
            Account."No." := 'XCAT5-VISIBILITY';
            Account.Insert(false);
        end;
        if Mode = 'read' then
            LowerPermissions.SetExactPermissionSet('BIFROST Read ori')
        else begin
            LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
            LowerPermissions.AddPermissionSet('BIFROST SustFull ori');
        end;
        LowerPermissions.AddPermissionSet('BIFROST API ori');
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Category.Set";
        IsVisible := MessageInterface.IsEnabled();
        Assert.AreEqual(Mode in ['setup', 'account'], IsVisible, 'Visibility combines the shared gate and write capability.');
        Request.Add('onlyEnabled', true);
        Response := DispatchWithoutCommit(Enum::"Message Type ori"::"Help.MessageTypes.Get", 'Sustainability.Category.Set', Request, LanguageId);
        Assert.IsTrue(Response.Get('result', Token), 'Discovery must return a roster.');
        if IsVisible then
            Assert.AreEqual(1, Token.AsArray().Count(), 'A configured Full user sees the type.')
        else
            Assert.AreEqual(0, Token.AsArray().Count(), 'Hidden types must not appear in the enabled roster.');
        if Mode = 'empty' then begin
            Clear(Request);
            Request.Add('code', 'XCAT5-HIDDEN');
            Response := DispatchWithoutCommit(Enum::"Message Type ori"::"Sustainability.Category.Set", '', Request, LanguageId);
            Assert.IsTrue(Response.Get('status', Token), 'Known hidden type must return a response.');
            Assert.AreEqual('Success', Token.AsValue().AsText(), 'Hidden is discovery-only and does not block a permitted caller.');
            LowerPermissions.SetOutsideO365Scope();
            Assert.IsTrue(Category.Get('XCAT5-HIDDEN'), 'Known hidden type performs its write.');
        end;
        LowerPermissions.SetOutsideO365Scope();
        // RequiredTestIsolation=Codeunit restores setup, demo accounts and every synthetic record.
    end;

    local procedure VerifyContract(LanguageId: Integer)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        ContractInterface: Interface "Msg Contract ori";
        Contract: JsonObject;
        Token: JsonToken;
        Effect: JsonObject;
        Errors: JsonArray;
        ErrorToken: JsonToken;
        ErrorEntry: JsonObject;
        PreviousLanguage: Integer;
        ChapterName: Text;
        EnglishOverview: Text;
        LocalizedOverview: Text;
        EnglishRefusal: Text;
        LocalizedRefusal: Text;
        ChapterNames: List of [Text];
        ErrorNames: List of [Text];
    begin
        // #5 AC01, AC02, AC-H and AC-L | Public help uses demo inputs and complete Foundation chapters.
        LowerPermissions.SetOutsideO365Scope();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Sustainability.Category.Set", Contract), 'The registered type must provide its contract.');
        ChapterNames.AddRange('envelope', 'target', 'parameters', 'response', 'errors', 'effect', 'examples');
        foreach ChapterName in ChapterNames do
            Assert.IsTrue(Contract.Get(ChapterName, Token), 'Missing contract chapter: ' + ChapterName);
        Contract.Get('effect', Token);
        Effect := Token.AsObject();
        Effect.Get('idempotent', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'Category updates are idempotent.');
        Effect.Get('permissionSet', Token);
        Assert.AreEqual('BIFROST SustFull ori', Token.AsValue().AsText(), 'Only Full grants this write.');
        Contract.Get('errors', Token);
        Errors := Token.AsArray();
        Assert.IsTrue(Errors.Count() >= 5, 'Document every error class.');
        ErrorNames.AddRange('code', 'when', 'fix');
        foreach ErrorToken in Errors do begin
            ErrorEntry := ErrorToken.AsObject();
            foreach ChapterName in ErrorNames do
                Assert.IsTrue(ErrorEntry.Get(ChapterName, Token), 'Every error needs code, when and fix.');
        end;
        // Foundation deliberately serves GetContract chapters in English (#777). The implementation
        // still supplies localized contract labels when its public interface is read in that language.
        ContractInterface := Enum::"Message Type ori"::"Sustainability.Category.Set";
        GlobalLanguage(1033);
        Assert.IsTrue(ContractInterface.GetOverview(EnglishOverview), 'English overview exists.');
        ContractInterface.GetErrors(Errors);
        Errors.Get(0, ErrorToken);
        ErrorToken.AsObject().Get('when', Token);
        EnglishRefusal := Token.AsValue().AsText();
        GlobalLanguage(LanguageId);
        Assert.IsTrue(ContractInterface.GetOverview(LocalizedOverview), 'Localized overview exists.');
        ContractInterface.GetErrors(Errors);
        Errors.Get(0, ErrorToken);
        ErrorToken.AsObject().Get('when', Token);
        LocalizedRefusal := Token.AsValue().AsText();
        if LanguageId = 1039 then begin
            Assert.AreNotEqual(EnglishOverview, LocalizedOverview, 'Icelandic contract overview must be translated.');
            Assert.AreNotEqual(EnglishRefusal, LocalizedRefusal, 'Icelandic refusal contract text must be translated.');
        end;
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure DispatchWithoutCommit(MessageType: Enum "Message Type ori"; SubjectText: Text[250]; Request: JsonObject; LanguageId: Integer) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        RequestText: Text;
        ResponseText: Text;
        ContentType: Text[100];
        MessageId: Guid;
        TaskId: Guid;
        ResponseTime: Duration;
        ResponseStream: InStream;
    begin
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(MessageType, Enum::"Message Version ori"::"1.0", SubjectText, 'category5-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseBlob, ContentType, ResponseTime, true);
        ResponseBlob.CreateInStream(ResponseStream, TextEncoding::UTF8);
        ResponseStream.ReadText(ResponseText);
        Response.ReadFrom(ResponseText);
    end;
}
