namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using Origo.Bifrost.Sustainability;
using System.Utilities;
using System.TestLibraries.Utilities;

/// <summary>Issue 3: dispatcher coverage of balances, refusals, visibility and permissions in both supported languages.</summary>
codeunit 98015 "Sust Account Balance Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Exercises BalancesAndNoPosting through Foundation in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_AC06_BalancesAndNoPosting1033()
    begin
        VerifyBalancesAndNoPosting(1033);
    end;

    /// <summary>Exercises BalancesAndNoPosting through Foundation in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_AC06_BalancesAndNoPosting1039()
    begin
        VerifyBalancesAndNoPosting(1039);
    end;

    /// <summary>Exercises TotalsAndDimensions through Foundation in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_TotalsAndDimensions1033()
    begin
        VerifyTotalsAndDimensions(1033);
    end;

    /// <summary>Exercises TotalsAndDimensions through Foundation in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_TotalsAndDimensions1039()
    begin
        VerifyTotalsAndDimensions(1039);
    end;

    /// <summary>Exercises ZeroAndBoundaryDates through Foundation in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_ZeroAndBoundaryDates1033()
    begin
        VerifyZeroAndBoundaryDates(1033);
    end;

    /// <summary>Exercises ZeroAndBoundaryDates through Foundation in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_ZeroAndBoundaryDates1039()
    begin
        VerifyZeroAndBoundaryDates(1039);
    end;

    /// <summary>Exercises Refusals through Foundation in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_AC05_Refusals1033()
    begin
        VerifyRefusals(1033);
    end;

    /// <summary>Exercises Refusals through Foundation in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_AC05_Refusals1039()
    begin
        VerifyRefusals(1039);
    end;

    /// <summary>Exercises Visibility through Foundation in language 1033.</summary>
    [Test]
    procedure Scenario_ACV_Visibility1033()
    begin
        VerifyVisibility(1033);
    end;

    /// <summary>Exercises Visibility through Foundation in language 1039.</summary>
    [Test]
    procedure Scenario_ACV_Visibility1039()
    begin
        VerifyVisibility(1039);
    end;

    /// <summary>Exercises PermissionDenied through Foundation in language 1033.</summary>
    [Test]
    procedure Scenario_ACP_PermissionDenied1033()
    begin
        VerifyPermissionDenied(1033);
    end;

    /// <summary>Exercises PermissionDenied through Foundation in language 1039.</summary>
    [Test]
    procedure Scenario_ACP_PermissionDenied1039()
    begin
        VerifyPermissionDenied(1039);
    end;

    /// <summary>Verifies Foundation Read alone cannot read native sustainability data in English.</summary>
    [Test]
    procedure Scenario_ACP_ReadRole1033()
    begin
        // Story #3, amended AC-P | Time: fixed fixture dates | Risk: #21 permission boundary.
        VerifyReadRole(1033, false);
    end;

    /// <summary>Verifies Foundation Read alone cannot read native sustainability data in Icelandic.</summary>
    [Test]
    procedure Scenario_ACP_ReadRole1039()
    begin
        // Story #3, amended AC-P | Time: fixed fixture dates | Risk: #21 permission boundary.
        VerifyReadRole(1039, false);
    end;

    /// <summary>Verifies the merged AppSource-compatible permission assignment in English.</summary>
    [Test]
    procedure Scenario_ACP_AssignedReadSets1033()
    begin
        VerifyReadRole(1033, true);
    end;

    /// <summary>Verifies the merged AppSource-compatible permission assignment in Icelandic.</summary>
    [Test]
    procedure Scenario_ACP_AssignedReadSets1039()
    begin
        VerifyReadRole(1039, true);
    end;

    local procedure VerifyBalancesAndNoPosting(LanguageId: Integer)
    var
        Account: Record "Sustainability Account";
        LedgerEntry: Record "Sustainability Ledger Entry";
        Response: JsonObject;
        Row: JsonObject;
        Request: JsonObject;
        BeforeCount: Integer;
        BeforeModifiedAt: DateTime;
    begin
        Initialize(LanguageId);
        SeedAccount(Account, "Sustainability Account Type"::Posting);
        SeedEntry(Account."No.", 20251231D, 2, '', '');
        SeedEntry(Account."No.", 20260101D, 3, '', '');
        SeedEntry(Account."No.", 20260131D, 5, '', '');
        SeedEntry(Account."No.", 20260201D, 7, '', '');
        Account.Get(Account."No.");
        BeforeModifiedAt := Account.SystemModifiedAt;
        BeforeCount := LedgerEntry.Count();
        Request.Add('accountNo', Account."No.");
        Request.Add('fromDate', '2026-01-01');
        Request.Add('toDate', '2026-01-31');
        Request.Add('asOfDate', '2026-02-01');
        Response := Dispatch(Request, LanguageId);
        Row := FirstRow(Response);
        AssertText(Row, 'no', Account."No.");
        AssertText(Row, 'accountType', 'Posting');
        AssertMeasures(Row, 'netChange', 8);
        AssertMeasures(Row, 'balance', 17);
        Assert.AreEqual(BeforeCount, LedgerEntry.Count(), 'Reading must not post or delete ledger entries.');
        Account.Get(Account."No.");
        Assert.AreEqual(BeforeModifiedAt, Account.SystemModifiedAt, 'Reading must not modify the account.');
        AssertMeasures(FirstRow(Dispatch(Request, LanguageId)), 'balance', 17);
    end;

    local procedure VerifyTotalsAndDimensions(LanguageId: Integer)
    var
        FirstAccount: Record "Sustainability Account";
        SecondAccount: Record "Sustainability Account";
        TotalAccount: Record "Sustainability Account";
        Request: JsonObject;
        Row: JsonObject;
    begin
        Initialize(LanguageId);
        SeedAccount(FirstAccount, "Sustainability Account Type"::Posting);
        SeedAccount(SecondAccount, "Sustainability Account Type"::Posting);
        SeedAccount(TotalAccount, "Sustainability Account Type"::Total);
        TotalAccount.Totaling := FirstAccount."No." + '|' + SecondAccount."No.";
        TotalAccount.Indentation := 2;
        TotalAccount.Modify();
        SeedEntry(FirstAccount."No.", 20260101D, 2, 'XDEPT', 'XRC');
        SeedEntry(SecondAccount."No.", 20260101D, 3, 'XDEPT', 'XRC');
        SeedEntry(FirstAccount."No.", 20260101D, 11, 'XOTHER', 'XRC');
        SeedEntry(SecondAccount."No.", 20260101D, 13, 'XDEPT', 'XOTHER');
        Request.Add('accountNo', TotalAccount."No.");
        Request.Add('globalDimension1Filter', 'XDEPT');
        Request.Add('globalDimension2Filter', 'XSECOND');
        Request.Add('responsibilityCenterFilter', 'XRC');
        Row := FirstRow(Dispatch(Request, LanguageId));
        AssertMeasures(Row, 'netChange', 5);
        AssertMeasures(Row, 'balance', 5);
        AssertText(Row, 'accountType', 'Total');
        TotalAccount."Account Type" := "Sustainability Account Type"::"End-Total";
        TotalAccount.Modify();
        Row := FirstRow(Dispatch(Request, LanguageId));
        AssertMeasures(Row, 'balance', 5);
        AssertText(Row, 'accountType', 'End-Total');
    end;

    local procedure VerifyZeroAndBoundaryDates(LanguageId: Integer)
    var
        Account: Record "Sustainability Account";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
    begin
        Initialize(LanguageId);
        SeedAccount(Account, "Sustainability Account Type"::Posting);
        Request.Add('accountFilter', Account."No.");
        Response := Dispatch(Request, LanguageId);
        AssertText(Response, 'status', 'Success');
        Response.Get('accounts', Token);
        Assert.AreEqual(0, Token.AsArray().Count(), 'Zero accounts are excluded by default.');
        Request.Add('includeZero', true);
        AssertMeasures(FirstRow(Dispatch(Request, LanguageId)), 'balance', 0);
        SeedEntry(Account."No.", 20260101D, 4, '', '');
        Request.Add('fromDate', '2026-01-01');
        Request.Add('toDate', '2026-01-01');
        AssertMeasures(FirstRow(Dispatch(Request, LanguageId)), 'netChange', 4);
        Request.Replace('fromDate', '2026-01-02');
        Request.Remove('toDate');
        AssertMeasures(FirstRow(Dispatch(Request, LanguageId)), 'netChange', 0);
        AssertMeasures(FirstRow(Dispatch(Request, LanguageId)), 'balance', 4);
        Account."Account Type" := "Sustainability Account Type"::Heading;
        Account.Modify();
        Clear(Request);
        Request.Add('accountNo', Account."No.");
        Request.Add('includeZero', true);
        AssertText(FirstRow(Dispatch(Request, LanguageId)), 'accountType', 'Heading');
    end;

    local procedure VerifyRefusals(LanguageId: Integer)
    begin
        Initialize(LanguageId);
        AssertRefusal('{"accountNo":"X-MISSING-BALANCE"}', LanguageId, 'AccountNotFound');
        AssertRefusal('{"accountFilter":"A|"}', LanguageId, 'InvalidFilter');
        AssertRefusal('{"globalDimension1Filter":"A|"}', LanguageId, 'InvalidFilter');
        AssertRefusal('{"globalDimension2Filter":"A|"}', LanguageId, 'InvalidFilter');
        AssertRefusal('{"responsibilityCenterFilter":"A|"}', LanguageId, 'InvalidFilter');
        AssertRefusal('{"fromDate":"2026-02-01","toDate":"2026-01-01"}', LanguageId, 'InvalidPeriod');
        AssertRefusal('{"fromDate":"2026-02-30"}', LanguageId, 'InvalidPeriod');
        AssertRefusal('{"asOfDate":"2026-1-1"}', LanguageId, 'InvalidPeriod');
        AssertRefusal('{"toDate":null}', LanguageId, 'InvalidPeriod');
        AssertRefusal('{"accountN0":"1000"}', LanguageId, 'InvalidParameter');
        AssertRefusal('{"includeZero":"true"}', LanguageId, 'InvalidParameter');
        AssertRefusal('{"accountNo":123}', LanguageId, 'InvalidParameter');
        AssertRefusal('{"accountNo":"XXXXXXXXXXXXXXXXXXXXX"}', LanguageId, 'InvalidParameter');
        AssertRefusal('{"accountNo":"1000","accountFilter":"1*"}', LanguageId, 'InvalidParameter');
    end;

    local procedure VerifyVisibility(LanguageId: Integer)
    var
        Account: Record "Sustainability Account";
        Setup: Record "Sustainability Setup";
        Implementation: Codeunit "Sust Account Bal Impl ori";
        Request: JsonObject;
        Response: JsonObject;
        ResponseText: Text;
    begin
        Initialize(LanguageId);
        // The test runner rolls back these company-fixture changes after the test.
        Account.DeleteAll(false);
        Setup.DeleteAll(false);
        Setup.Init();
        Setup.Insert(false);
        Assert.IsFalse(Implementation.IsEnabled(), 'Unconfigured company must hide the type.');
        Request.Add('onlyEnabled', true);
        Response := DispatchType(Request, LanguageId, "Message Type ori"::"Help.MessageTypes.Get");
        Response.WriteTo(ResponseText);
        Assert.IsFalse(ResponseText.Contains('Sustainability.AccountBalance.Get'), 'Hidden type must be absent from the roster.');
        Clear(Request);
        AssertText(Dispatch(Request, LanguageId), 'status', 'Success');
        SeedAccount(Account, "Sustainability Account Type"::Posting);
        Assert.IsTrue(Implementation.IsEnabled(), 'An account configures visibility.');
        Request.Add('onlyEnabled', true);
        Response := DispatchType(Request, LanguageId, "Message Type ori"::"Help.MessageTypes.Get");
        Response.WriteTo(ResponseText);
        Assert.IsTrue(ResponseText.Contains('Sustainability.AccountBalance.Get'), 'Configured type must appear in the roster.');
    end;

    local procedure VerifyPermissionDenied(LanguageId: Integer)
    var
        Account: Record "Sustainability Account";
        Implementation: Codeunit "Sust Account Bal Impl ori";
        Request: JsonObject;
        Response: JsonObject;
    begin
        Initialize(LanguageId);
        SeedAccount(Account, "Sustainability Account Type"::Posting);
        Request.Add('accountNo', Account."No.");
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('Sust Setup Test ori');
        Assert.IsFalse(Account.ReadPermission(), 'Permission fixture must lack native account reads.');
        Assert.IsFalse(Implementation.IsEnabled(), 'A caller without native read access cannot discover the type.');
        Response := Dispatch(Request, LanguageId);
        LowerPermissions.SetOutsideO365Scope();
        AssertText(Response, 'status', 'Error');
        AssertText(Response, 'code', 'PermissionDenied');
    end;

    local procedure VerifyReadRole(LanguageId: Integer; IncludeSustainabilitySet: Boolean)
    var
        Account: Record "Sustainability Account";
        LedgerEntry: Record "Sustainability Ledger Entry";
        Implementation: Codeunit "Sust Account Bal Impl ori";
        Request: JsonObject;
        Response: JsonObject;
    begin
        Initialize(LanguageId);
        SeedAccount(Account, "Sustainability Account Type"::Posting);
        SeedEntry(Account."No.", 20260101D, 1, '', '');
        Request.Add('accountNo', Account."No.");
        LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
        if IncludeSustainabilitySet then
            LowerPermissions.AddPermissionSet('BIFROST SustRead ori');
        LowerPermissions.AddPermissionSet('Sust Setup Test ori');
        // [THEN] Native reads require the separately assigned Sustainability permission set.
        Assert.AreEqual(IncludeSustainabilitySet, Account.ReadPermission(), 'Native account reads require Sustainability Read alongside Foundation Read.');
        Assert.AreEqual(IncludeSustainabilitySet, LedgerEntry.ReadPermission(), 'Native ledger reads require Sustainability Read alongside Foundation Read.');
        Assert.IsFalse(Account.WritePermission() or LedgerEntry.WritePermission(), 'Read role does not grant sustainability writes.');
        Assert.AreEqual(IncludeSustainabilitySet, Implementation.IsEnabled(), 'Discovery requires native sustainability read access.');
        // [WHEN] Foundation dispatches the known message type with the assigned permissions.
        Response := Dispatch(Request, LanguageId);
        LowerPermissions.SetOutsideO365Scope();
        // [THEN] Both sets allow the balance read; Foundation Read alone returns a structured refusal.
        if IncludeSustainabilitySet then
            AssertMeasures(FirstRow(Response), 'balance', 1)
        else begin
            AssertText(Response, 'status', 'Error');
            AssertText(Response, 'code', 'PermissionDenied');
        end;
    end;

    local procedure Initialize(LanguageId: Integer)
    var
        Setup: Record "Setup ori";
    begin
        LowerPermissions.SetOutsideO365Scope();
        Setup.InsertIfNotExists();
        Assert.IsTrue(LanguageId in [1033, 1039], 'Tests use a supported language.');
    end;

    local procedure SeedAccount(var Account: Record "Sustainability Account"; AccountType: Enum "Sustainability Account Type")
    begin
        Clear(Account);
        Account.Init();
        Account."No." := CopyStr('X' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        Account.Name := 'X balance test';
        Account."Account Type" := AccountType;
        Account.Insert(false);
    end;

    local procedure SeedEntry(AccountNo: Code[20]; PostingDate: Date; Amount: Decimal; Dimension1: Code[20]; ResponsibilityCenter: Code[10])
    var
        LedgerEntry: Record "Sustainability Ledger Entry";
        LastEntryNo: Integer;
    begin
        if LedgerEntry.FindLast() then
            LastEntryNo := LedgerEntry."Entry No.";
        LedgerEntry.Init();
        LedgerEntry."Entry No." := LastEntryNo + 1;
        LedgerEntry."Account No." := AccountNo;
        LedgerEntry."Posting Date" := PostingDate;
        LedgerEntry."Global Dimension 1 Code" := Dimension1;
        LedgerEntry."Global Dimension 2 Code" := 'XSECOND';
        LedgerEntry."Responsibility Center" := ResponsibilityCenter;
        LedgerEntry."Emission CO2" := Amount;
        LedgerEntry."Emission CH4" := Amount * 2;
        LedgerEntry."Emission N2O" := Amount * 3;
        LedgerEntry."CO2e Emission" := Amount * 4;
        LedgerEntry."Water Intensity" := Amount * 5;
        LedgerEntry."Discharged Into Water" := Amount * 6;
        LedgerEntry."Waste Intensity" := Amount * 7;
        LedgerEntry.Insert(false);
    end;

    local procedure Dispatch(Request: JsonObject; LanguageId: Integer): JsonObject
    begin
        exit(DispatchType(Request, LanguageId, "Message Type ori"::"Sustainability.AccountBalance.Get"));
    end;

    local procedure DispatchType(Request: JsonObject; LanguageId: Integer; MessageType: Enum "Message Type ori") Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        ResponseContentType: Text[100];
        RequestText: Text;
        ResponseText: Text;
        MessageId: Guid;
        EmptyTaskId: Guid;
        ResponseTime: Duration;
        ResponseStream: InStream;
        Line: Text;
        SavedLanguage: Integer;
    begin
        SavedLanguage := GlobalLanguage();
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(MessageType, "Message Version ori"::"1.0", '', 'XSUSTBALANCE', 'application/json',
            RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseTempBlob, ResponseContentType, ResponseTime, true);
        GlobalLanguage(SavedLanguage);
        ResponseTempBlob.CreateInStream(ResponseStream, TextEncoding::UTF8);
        while not ResponseStream.EOS() do begin
            ResponseStream.ReadText(Line);
            ResponseText += Line;
        end;
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'Dispatcher must return JSON: ' + ResponseText);
    end;

    local procedure FirstRow(Response: JsonObject) Row: JsonObject
    var
        Token: JsonToken;
        Rows: JsonArray;
    begin
        AssertText(Response, 'status', 'Success');
        Response.Get('accounts', Token);
        Rows := Token.AsArray();
        Assert.AreEqual(1, Rows.Count(), 'Exactly one account selected.');
        Rows.Get(0, Token);
        Row := Token.AsObject();
    end;

    local procedure AssertMeasures(Row: JsonObject; PropertyName: Text; Amount: Decimal)
    var
        Token: JsonToken;
        Amounts: JsonObject;
    begin
        Row.Get(PropertyName, Token);
        Amounts := Token.AsObject();
        Amounts.Get('co2', Token);
        Assert.AreEqual(Amount * 1, Token.AsValue().AsDecimal(), PropertyName + ' co2');
        Amounts.Get('ch4', Token);
        Assert.AreEqual(Amount * 2, Token.AsValue().AsDecimal(), PropertyName + ' ch4');
        Amounts.Get('n2o', Token);
        Assert.AreEqual(Amount * 3, Token.AsValue().AsDecimal(), PropertyName + ' n2o');
        Amounts.Get('co2e', Token);
        Assert.AreEqual(Amount * 4, Token.AsValue().AsDecimal(), PropertyName + ' co2e');
        Amounts.Get('water', Token);
        Assert.AreEqual(Amount * 5, Token.AsValue().AsDecimal(), PropertyName + ' water');
        Amounts.Get('dischargedWater', Token);
        Assert.AreEqual(Amount * 6, Token.AsValue().AsDecimal(), PropertyName + ' dischargedWater');
        Amounts.Get('waste', Token);
        Assert.AreEqual(Amount * 7, Token.AsValue().AsDecimal(), PropertyName + ' waste');
    end;

    local procedure AssertRefusal(RequestText: Text; LanguageId: Integer; Refusal: Text)
    var
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
    begin
        Request.ReadFrom(RequestText);
        Response := Dispatch(Request, LanguageId);
        AssertText(Response, 'status', 'Error');
        AssertText(Response, 'refusal', Refusal);
        Assert.IsTrue(Response.Get('code', Token), 'A single refusal must include the Foundation error code.');
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'The error code must be populated.');
        Assert.IsTrue(Response.Get('nextStep', Token), 'A single refusal must include corrective guidance.');
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'Corrective guidance must be populated.');
    end;

    local procedure AssertText(Response: JsonObject; PropertyName: Text; Expected: Text)
    var
        Token: JsonToken;
        ResponseText: Text;
    begin
        Response.WriteTo(ResponseText);
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Missing ' + PropertyName + ': ' + ResponseText);
        Assert.AreEqual(Expected, Token.AsValue().AsText(), ResponseText);
    end;
}
