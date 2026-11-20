namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests Sustainability.Account.Set (#14) through Foundation's public Dispatcher ori: the happy path and idempotency,
/// every refusal of the story, no ledger posting (D2) and the visibility rule (D5), in languages 1033 and 1039.
/// </summary>
codeunit 98025 "Sust Account Set Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryTok: Label 'TSTCAT', Locked = true;
        OtherCategoryTok: Label 'TSTCAT2', Locked = true;
        SubcategoryTok: Label 'TSTSUB', Locked = true;
        OtherSubcategoryTok: Label 'TSTSUB2', Locked = true;

    [Test]
    procedure Scenario_AC03_CreatesAccountWithCategory_English()
    begin
        VerifyCreatesAccount(1033);
    end;

    [Test]
    procedure Scenario_AC03_CreatesAccountWithCategory_Icelandic()
    begin
        VerifyCreatesAccount(1039);
    end;

    [Test]
    procedure Scenario_AC03_SameRequestTwice_IsIdempotent()
    var
        SustainabilityAccount: Record "Sustainability Account";
        Request: JsonObject;
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] A category with a subcategory
        Initialize();
        AccountNo := NewAccountNo();
        Request := NewRequest(AccountNo, CategoryTok, SubcategoryTok);

        // [WHEN] The same request is sent twice
        Invoke(Request, '', 1033);
        Response := Invoke(Request, '', 1033);

        // [THEN] The second call succeeds as an update and the account is the same
        Assert.AreEqual('Success', GetText(Response, 'status'), 'The second call must succeed.');
        Assert.IsFalse(GetBool(Response, 'created'), 'The second call must update, not create.');
        SustainabilityAccount.Get(AccountNo);
        Assert.AreEqual(SubcategoryTok, SustainabilityAccount.Subcategory, 'The subcategory must be kept.');
        SustainabilityAccount.SetRange("No.", AccountNo);
        Assert.RecordCount(SustainabilityAccount, 1);
    end;

    [Test]
    procedure Scenario_AC03_UpdatesExistingAccountBySubject()
    var
        SustainabilityAccount: Record "Sustainability Account";
        Request: JsonObject;
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] An existing account
        Initialize();
        AccountNo := NewAccountNo();
        Invoke(NewRequest(AccountNo, CategoryTok, SubcategoryTok), '', 1033);

        // [WHEN] Only the name and the blocked flag are sent, with the number as the subject
        Request.Add('name', 'Renamed account');
        Request.Add('blocked', true);
        Response := Invoke(Request, AccountNo, 1033);

        // [THEN] Those fields change and the category stays
        Assert.AreEqual('Success', GetText(Response, 'status'), 'The update must succeed.');
        Assert.IsFalse(GetBool(Response, 'created'), 'An existing account is updated.');
        SustainabilityAccount.Get(AccountNo);
        Assert.AreEqual('Renamed account', SustainabilityAccount.Name, 'The name must be updated.');
        Assert.IsTrue(SustainabilityAccount.Blocked, 'The account must be blocked.');
        Assert.AreEqual(CategoryTok, SustainabilityAccount.Category, 'Fields not sent keep their values.');
    end;

    [Test]
    procedure Scenario_AC04_MissingNo_IsRefused_English()
    begin
        VerifyMissingNo(1033, 'missing the required parameter');
    end;

    [Test]
    procedure Scenario_AC04_MissingNo_IsRefused_Icelandic()
    begin
        VerifyMissingNo(1039, 'vantar nauðsynlega færibreytu');
    end;

    [Test]
    procedure Scenario_AC04_UnknownCategory_IsRefused()
    var
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] A category code that does not exist
        Initialize();
        AccountNo := NewAccountNo();

        // [WHEN] An account is set with it
        Response := Invoke(NewRequest(AccountNo, 'NOSUCHCAT', ''), '', 1033);

        // [THEN] InvalidCategory is refused as InvalidParameter on category and nothing is created
        VerifyRefusal(Response, 'InvalidParameter', 'category');
        VerifyAccountMissing(AccountNo);
    end;

    [Test]
    procedure Scenario_AC04_SubcategoryOfOtherCategory_IsRefused_Icelandic()
    var
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] A subcategory that belongs to another category
        Initialize();
        AccountNo := NewAccountNo();

        // [WHEN] An account is set with the category and the foreign subcategory, in Icelandic
        Response := Invoke(NewRequest(AccountNo, CategoryTok, OtherSubcategoryTok), '', 1039);

        // [THEN] The refusal names the subcategory in Icelandic and nothing is created
        VerifyRefusal(Response, 'InvalidParameter', 'subcategory');
        Assert.IsTrue(GetText(Response, 'error').Contains('tilheyrir ekki'), 'The refusal must be Icelandic: ' + GetText(Response, 'error'));
        VerifyAccountMissing(AccountNo);
    end;

    [Test]
    procedure Scenario_AC04_BlockingAccountInUse_IsRefused()
    var
        SustainabilityAccount: Record "Sustainability Account";
        Request: JsonObject;
        Response: JsonObject;
        AccountNo: Code[20];
        BatchName: Code[10];
    begin
        // [GIVEN] An account with an open journal line
        Initialize();
        AccountNo := NewAccountNo();
        Invoke(NewRequest(AccountNo, CategoryTok, SubcategoryTok), '', 1033);
        BatchName := CreateJournalLine(AccountNo);

        // [WHEN] The account is blocked
        Request.Add('no', AccountNo);
        Request.Add('blocked', true);
        Request.Add('name', 'Must not be saved');
        Response := Invoke(Request, '', 1033);

        // [THEN] AccountInUse is refused as PreconditionFailed with the batch name, and nothing changes
        VerifyRefusal(Response, 'PreconditionFailed', 'blocked');
        Assert.IsTrue(GetText(Response, 'error').Contains(BatchName), 'The refusal must name the batch: ' + GetText(Response, 'error'));
        SustainabilityAccount.Get(AccountNo);
        Assert.IsFalse(SustainabilityAccount.Blocked, 'The account must not be blocked.');
        Assert.AreNotEqual('Must not be saved', SustainabilityAccount.Name, 'A refusal leaves nothing changed.');
    end;

    [Test]
    procedure Scenario_AC04_BusinessCentralValidationError_SavesNothing()
    var
        Request: JsonObject;
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] A new posting account with a totaling filter, which Business Central refuses
        Initialize();
        AccountNo := NewAccountNo();
        Request.Add('no', AccountNo);
        Request.Add('accountType', 'Posting');
        Request.Add('totaling', '10000..19999');

        // [WHEN] The account is set
        Response := Invoke(Request, '', 1033);

        // [THEN] The answer is a BusinessCentralError and the insert is rolled back
        Assert.AreEqual('Error', GetText(Response, 'status'), 'A validation error must answer Error.');
        Assert.AreEqual('BusinessCentralError', GetText(Response, 'code'), 'A Business Central error keeps its code.');
        Assert.AreNotEqual('', GetText(Response, 'error'), 'The Business Central message must be carried.');
        VerifyAccountMissing(AccountNo);
    end;

    [Test]
    procedure Scenario_AC04_InvalidAccountType_IsRefused()
    var
        Request: JsonObject;
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] An account type outside the allowed set
        Initialize();
        AccountNo := NewAccountNo();
        Request.Add('no', AccountNo);
        Request.Add('accountType', 'Sideways');

        // [WHEN] The account is set
        Response := Invoke(Request, '', 1033);

        // [THEN] It is refused before anything is written
        VerifyRefusal(Response, 'InvalidParameter', 'accountType');
        VerifyAccountMissing(AccountNo);
    end;

    [Test]
    procedure Scenario_AC03_TotalAccountNeedsNoCategory()
    var
        SustainabilityAccount: Record "Sustainability Account";
        Request: JsonObject;
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] An End-Total account with a totaling filter and no category
        Initialize();
        AccountNo := NewAccountNo();
        Request.Add('no', AccountNo);
        Request.Add('name', 'Total emissions');
        Request.Add('accountType', 'End-Total');
        Request.Add('totaling', '10000..19999');

        // [WHEN] The account is set
        Response := Invoke(Request, '', 1033);

        // [THEN] It is created with the totaling and no category
        Assert.AreEqual('Success', GetText(Response, 'status'), 'A total account needs no category: ' + GetText(Response, 'error'));
        SustainabilityAccount.Get(AccountNo);
        Assert.AreEqual('10000..19999', SustainabilityAccount.Totaling, 'The totaling must be stored.');
        Assert.AreEqual('', SustainabilityAccount.Category, 'No category is set.');
    end;

    [Test]
    procedure Scenario_AC06_PostsNoLedgerEntry()
    var
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
        Request: JsonObject;
        CountBefore: Integer;
    begin
        // [GIVEN] The current number of sustainability ledger entries
        Initialize();
        CountBefore := SustainabilityLedgerEntry.Count();
        Request := NewRequest(NewAccountNo(), CategoryTok, SubcategoryTok);
        Request.Add('blocked', false);

        // [WHEN] An account is created and updated
        Invoke(Request, '', 1033);
        Invoke(Request, '', 1033);

        // [THEN] No ledger entry is written
        Assert.AreEqual(CountBefore, SustainabilityLedgerEntry.Count(), 'Sustainability.Account.Set must post nothing (D2).');
    end;

    [Test]
    procedure Scenario_ACV_ConfiguredCompany_TypeIsVisible()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
        MessageInterface: Interface "Msg Interface ori";
    begin
        // [GIVEN] No accounts, but the setup names an emission unit of measure
        Initialize();
        SustainabilityAccount.DeleteAll();
        if not SustainabilitySetup.Get() then
            SustainabilitySetup.Insert();
        SustainabilitySetup."Emission Unit of Measure Code" := 'KG';
        SustainabilitySetup.Modify();

        // [WHEN] Foundation asks the type whether it is enabled
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Account.Set";

        // [THEN] It is visible for a user with the Full grant
        Assert.IsTrue(MessageInterface.IsEnabled(), 'The type must be visible in a configured company.');
    end;

    [Test]
    procedure Scenario_ACV_UnconfiguredCompany_TypeIsHiddenButRuns()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
        MessageInterface: Interface "Msg Interface ori";
        Request: JsonObject;
        Response: JsonObject;
        AccountNo: Code[20];
    begin
        // [GIVEN] A company without accounts and with a blank setup
        Initialize();
        SustainabilityAccount.DeleteAll();
        if SustainabilitySetup.Get() then begin
            SustainabilitySetup."Emission Unit of Measure Code" := '';
            SustainabilitySetup.Modify();
        end;

        // [WHEN] Foundation asks the type whether it is enabled
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Account.Set";

        // [THEN] It is hidden, yet a caller that knows the type can still run it
        Assert.IsFalse(MessageInterface.IsEnabled(), 'The type must be hidden in an unconfigured company.');
        AccountNo := NewAccountNo();
        Request.Add('no', AccountNo);
        Request.Add('name', 'First account');
        Response := Invoke(Request, '', 1033);
        Assert.AreEqual('Success', GetText(Response, 'status'), 'Hidden is not blocked: ' + GetText(Response, 'error'));
        Assert.IsTrue(MessageInterface.IsEnabled(), 'The first account makes the type visible.');
    end;

    local procedure VerifyCreatesAccount(LanguageId: Integer)
    var
        SustainabilityAccount: Record "Sustainability Account";
        Response: JsonObject;
        Account: JsonObject;
        Token: JsonToken;
        AccountNo: Code[20];
    begin
        // [GIVEN] A category with a subcategory
        Initialize();
        AccountNo := NewAccountNo();

        // [WHEN] A new account is set with both
        Response := Invoke(NewRequest(AccountNo, CategoryTok, SubcategoryTok), '', LanguageId);

        // [THEN] It is created through Validate and returned as stored
        Assert.AreEqual('Success', GetText(Response, 'status'), 'The call must succeed: ' + GetText(Response, 'error'));
        Assert.IsTrue(GetBool(Response, 'created'), 'A new number creates the account.');
        SustainabilityAccount.Get(AccountNo);
        Assert.AreEqual(CategoryTok, SustainabilityAccount.Category, 'The category must be stored.');
        Assert.AreEqual(SubcategoryTok, SustainabilityAccount.Subcategory, 'The subcategory must be stored.');
        Assert.IsTrue(SustainabilityAccount."Direct Posting", 'Business Central''s default for a posting account must hold.');
        Response.Get('account', Token);
        Account := Token.AsObject();
        Assert.AreEqual(Format(AccountNo), GetText(Account, 'no'), 'The response must carry the account number.');
        Assert.AreEqual('Posting', GetText(Account, 'accountType'), 'The account type is a stable token in every language.');
        Assert.AreEqual(SubcategoryTok, GetText(Account, 'subcategory'), 'The response must carry the subcategory.');
    end;

    local procedure VerifyMissingNo(LanguageId: Integer; ExpectedText: Text)
    var
        SustainabilityAccount: Record "Sustainability Account";
        Request: JsonObject;
        Response: JsonObject;
        CountBefore: Integer;
    begin
        // [GIVEN] A request without a number and without a subject
        Initialize();
        CountBefore := SustainabilityAccount.Count();
        Request.Add('name', 'No number');

        // [WHEN] It is sent
        Response := Invoke(Request, '', LanguageId);

        // [THEN] MissingParameter is refused in the caller's language and nothing is written
        VerifyRefusal(Response, 'MissingParameter', 'no');
        Assert.IsTrue(GetText(Response, 'error').Contains(ExpectedText), 'Unexpected refusal text: ' + GetText(Response, 'error'));
        Assert.AreEqual(CountBefore, SustainabilityAccount.Count(), 'A refusal leaves nothing changed.');
    end;

    local procedure VerifyRefusal(Response: JsonObject; ExpectedCode: Text; ExpectedParameter: Text)
    begin
        Assert.AreEqual('Error', GetText(Response, 'status'), 'A refusal must answer status Error.');
        Assert.AreEqual(ExpectedCode, GetText(Response, 'code'), 'Unexpected error code: ' + GetText(Response, 'error'));
        Assert.AreEqual(ExpectedParameter, GetText(Response, 'parameter'), 'The refusal must name the parameter.');
        Assert.AreNotEqual('', GetText(Response, 'error'), 'The refusal must carry a message.');
    end;

    local procedure VerifyAccountMissing(AccountNo: Code[20])
    var
        SustainabilityAccount: Record "Sustainability Account";
    begin
        Assert.IsFalse(SustainabilityAccount.Get(AccountNo), 'A refused or failed call must not create the account.');
    end;

    local procedure Initialize()
    var
        SustainAccountSubcategory: Record "Sustain. Account Subcategory";
    begin
        CreateCategory(CategoryTok);
        CreateCategory(OtherCategoryTok);
        if not SustainAccountSubcategory.Get(CategoryTok, SubcategoryTok) then begin
            SustainAccountSubcategory.Init();
            SustainAccountSubcategory."Category Code" := CategoryTok;
            SustainAccountSubcategory.Code := SubcategoryTok;
            SustainAccountSubcategory.Insert();
        end;
        if not SustainAccountSubcategory.Get(OtherCategoryTok, OtherSubcategoryTok) then begin
            SustainAccountSubcategory.Init();
            SustainAccountSubcategory."Category Code" := OtherCategoryTok;
            SustainAccountSubcategory.Code := OtherSubcategoryTok;
            SustainAccountSubcategory.Insert();
        end;
    end;

    local procedure CreateCategory(CategoryCode: Code[20])
    var
        SustainAccountCategory: Record "Sustain. Account Category";
    begin
        if SustainAccountCategory.Get(CategoryCode) then
            exit;
        SustainAccountCategory.Init();
        SustainAccountCategory.Code := CategoryCode;
        SustainAccountCategory.Description := 'Test category';
        SustainAccountCategory.Insert();
    end;

    local procedure CreateJournalLine(AccountNo: Code[20]) BatchName: Code[10]
    var
        SustainabilityJnlTemplate: Record "Sustainability Jnl. Template";
        SustainabilityJnlBatch: Record "Sustainability Jnl. Batch";
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
    begin
        BatchName := CopyStr('B' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        if not SustainabilityJnlTemplate.Get('TSTTMPL') then begin
            SustainabilityJnlTemplate.Init();
            SustainabilityJnlTemplate.Name := 'TSTTMPL';
            SustainabilityJnlTemplate.Insert();
        end;
        SustainabilityJnlBatch.Init();
        SustainabilityJnlBatch."Journal Template Name" := 'TSTTMPL';
        SustainabilityJnlBatch.Name := BatchName;
        SustainabilityJnlBatch.Insert();
        SustainabilityJnlLine.Init();
        SustainabilityJnlLine."Journal Template Name" := 'TSTTMPL';
        SustainabilityJnlLine."Journal Batch Name" := BatchName;
        SustainabilityJnlLine."Line No." := 10000;
        SustainabilityJnlLine."Account No." := AccountNo;
        SustainabilityJnlLine.Insert();
    end;

    local procedure NewAccountNo(): Code[20]
    begin
        exit(CopyStr('T' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;

    local procedure NewRequest(AccountNo: Code[20]; CategoryCode: Text; SubcategoryCode: Text) Request: JsonObject
    begin
        Request.Add('no', AccountNo);
        Request.Add('name', 'Test account ' + AccountNo);
        Request.Add('category', CategoryCode);
        if SubcategoryCode <> '' then
            Request.Add('subcategory', SubcategoryCode);
    end;

    /// <summary>Runs Sustainability.Account.Set through the public dispatcher in the given language.</summary>
    procedure Invoke(Request: JsonObject; Subject: Text[250]; LanguageId: Integer) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        RequestText: Text;
        ResponseText: Text;
        ResponseContentType: Text[100];
        MessageId: Guid;
        EmptyTaskId: Guid;
        ResponseTime: Duration;
    begin
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Account.Set", Enum::"Message Version ori"::"1.0", Subject, 'XSUST', 'application/json',
            RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The dispatcher must return JSON: ' + ResponseText);
    end;

    local procedure GetText(Json: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Json.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetBool(Json: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Json.Get(PropertyName, Token) then
            exit(false);
        exit(Token.AsValue().AsBoolean());
    end;
}
