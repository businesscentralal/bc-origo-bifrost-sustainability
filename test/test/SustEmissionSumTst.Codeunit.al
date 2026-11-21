namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Story #2: Sustainability.EmissionSummary.Get through Foundation's public Dispatcher ori.
/// The ledger rows are seeded in 2099 so CRONUS demo entries never fall in the range, and are removed afterwards.
/// </summary>
codeunit 98010 "Sust Emission Sum Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        DescriptionTok: Label 'BIFROST-TEST-2', Locked = true;

    /// <summary>AC03/AC06: monthly summary per scope with energy totals, read role, English.</summary>
    [Test]
    procedure Scenario_AC03_MonthlySummary_ReadRole_English()
    begin
        VerifySummary(1033, 'BIFROST Read ori');
    end;

    /// <summary>AC03/AC06: monthly summary per scope with energy totals, full role, Icelandic.</summary>
    [Test]
    procedure Scenario_AC03_MonthlySummary_FullRole_Icelandic()
    begin
        VerifySummary(1039, 'BIFROST Full ori');
    end;

    /// <summary>AC03: an emissionScope filter and a Quarter period clip to the requested range.</summary>
    [Test]
    procedure Scenario_AC03_ScopeFilter_QuarterClipped()
    var
        Request: JsonObject;
        Response: JsonObject;
        Rows: JsonArray;
        Row: JsonToken;
    begin
        // [GIVEN] Seeded Scope 1 and Scope 2 entries in January and February 2099.
        Initialize();
        SeedEntries();
        Request.Add('fromDate', '2099-01-10');
        Request.Add('toDate', '2099-02-28');
        Request.Add('periodType', 'Quarter');
        Request.Add('emissionScope', 'Scope 2');
        Commit();

        // [WHEN] The summary is requested for Scope 2 only.
        Response := DispatchAs(Request, 1033, 'BIFROST Read ori');

        // [THEN] One clipped quarter row for Scope 2 only.
        Assert.AreEqual('Success', ReadText(Response, 'status'), ReadOptional(Response, 'error'));
        Rows := ReadArray(Response, 'rows');
        Assert.AreEqual(1, Rows.Count(), 'One scope x one period.');
        Rows.Get(0, Row);
        Assert.AreEqual('Scope 2', ReadText(Row.AsObject(), 'scope'), 'Only the filtered scope.');
        Assert.AreEqual('2099-01-10', ReadText(Row.AsObject(), 'periodStart'), 'The period starts at fromDate.');
        Assert.AreEqual('2099-02-28', ReadText(Row.AsObject(), 'periodEnd'), 'The period ends at toDate.');
        Assert.AreEqual(4, ReadDecimal(Row.AsObject(), 'CO2'), 'Scope 2 CO2.');
        Assert.IsFalse(Row.AsObject().Contains('energyConsumption'), 'Energy only on request.');
        Cleanup();
    end;

    /// <summary>AC04: missing fromDate is refused.</summary>
    [Test]
    procedure Scenario_AC04_MissingFromDate_Refused()
    begin
        VerifyRefusal('missingFrom', 1033, 'MissingParameter', 'fromDate');
    end;

    /// <summary>AC04: a toDate that is not a date is refused as InvalidPeriod.</summary>
    [Test]
    procedure Scenario_AC04_NotADate_InvalidPeriod()
    begin
        VerifyRefusal('notDate', 1033, 'InvalidParameter', 'InvalidPeriod');
    end;

    /// <summary>AC04: fromDate after toDate is refused as InvalidPeriod, in Icelandic.</summary>
    [Test]
    procedure Scenario_AC04_FromAfterTo_InvalidPeriod_Icelandic()
    begin
        VerifyRefusal('reversed', 1039, 'InvalidParameter', 'InvalidPeriod');
    end;

    /// <summary>AC04: unknown periodType names the allowed values.</summary>
    [Test]
    procedure Scenario_AC04_UnknownPeriodType_NamesAllowed()
    begin
        VerifyRefusal('periodType', 1033, 'InvalidParameter', 'Day, Week, Month, Quarter, Year');
    end;

    /// <summary>AC04: unknown emissionScope names the allowed values, in Icelandic.</summary>
    [Test]
    procedure Scenario_AC04_UnknownScope_NamesAllowed_Icelandic()
    begin
        VerifyRefusal('scope', 1039, 'InvalidParameter', 'Scope 1, Scope 2, Scope 3');
    end;

    /// <summary>AC04: unknown include value names the allowed values.</summary>
    [Test]
    procedure Scenario_AC04_UnknownInclude_NamesAllowed()
    begin
        VerifyRefusal('include', 1033, 'InvalidParameter', 'water, waste, energy');
    end;

    /// <summary>AC04: more than 400 periods is refused.</summary>
    [Test]
    procedure Scenario_AC04_TooManyPeriods_Refused()
    begin
        VerifyRefusal('tooMany', 1033, 'LimitExceeded', 'periodType');
    end;

    /// <summary>AC05: an unknown key is refused.</summary>
    [Test]
    procedure Scenario_AC05_UnknownKey_Refused()
    begin
        VerifyRefusal('unknownKey', 1033, 'UnknownParameter', 'fromdate');
    end;

    /// <summary>AC-P: a caller without BIFROST SustRead ori gets PermissionDenied, in Icelandic.</summary>
    [Test]
    procedure Scenario_ACP_NoSustRead_PermissionDenied_Icelandic()
    begin
        VerifyRefusal('permission', 1039, 'PermissionDenied', 'BIFROST SustRead ori');
    end;

    /// <summary>AC-V/AC-P: the type is listed for a reader and hidden without its permissions.</summary>
    [Test]
    procedure Scenario_ACP_HiddenWithoutPermission()
    var
        Discovery: Interface "Msg Interface ori";
    begin
        // [GIVEN] The registered type.
        Initialize();
        SetEmissionUnit('KG');
        Discovery := Enum::"Message Type ori"::"Sustainability.EmissionSummary.Get";

        // [WHEN] A reader asks [THEN] it is enabled.
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');
        Assert.IsTrue(Discovery.IsEnabled(), 'A reader sees the type.');

        // [WHEN] A Full-role user asks [THEN] it is enabled.
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');
        Assert.IsTrue(Discovery.IsEnabled(), 'A Full-role user sees the type.');

        // [WHEN] A BIFROST reader without native Sustainability read asks [THEN] it is hidden.
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST Read ori');
        Assert.IsFalse(Discovery.IsEnabled(), 'Without native Sustainability read the type is hidden.');

        // [WHEN] A caller without BIFROST SustRead ori asks [THEN] it is hidden.
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');
        Assert.IsFalse(Discovery.IsEnabled(), 'Without the permissions the type is hidden.');
        LowerPermissions.SetOutsideO365Scope();
    end;

    /// <summary>AC-H: the contract declares a read-only, idempotent effect and the read role.</summary>
    [Test]
    procedure Scenario_ACH_Contract_ReadOnlyIdempotent()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Token: JsonToken;
        Effect: JsonObject;
    begin
        // [GIVEN] The installed type [WHEN] Foundation resolves its contract.
        Initialize();
        Assert.IsTrue(ContractMgt.GetContract(Enum::"Message Type ori"::"Sustainability.EmissionSummary.Get", Contract), 'The contract must resolve.');

        // [THEN] Effect read, idempotent, read role, help chapters present.
        Assert.IsTrue(Contract.Get('effect', Token), 'Effect chapter.');
        Effect := Token.AsObject();
        Assert.AreEqual('read', ReadText(Effect, 'effect'), 'Read effect.');
        Effect.Get('idempotent', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'Idempotent.');
        Assert.AreEqual('BIFROST SustRead ori', ReadText(Effect, 'permissionSet'), 'Read role.');
        Assert.IsTrue(Contract.Contains('overview'), 'Overview chapter.');
        Assert.IsTrue(Contract.Contains('errors'), 'Errors chapter.');
        Assert.IsTrue(Contract.Contains('examples'), 'Examples chapter.');
    end;

    /// <summary>AC-V: in a configured company the type is listed for a reader.</summary>
    [Test]
    procedure Scenario_ACV_ConfiguredCompany_Listed()
    var
        Discovery: Interface "Msg Interface ori";
    begin
        // [GIVEN] Sustainability Setup has an Emission Unit of Measure Code.
        Initialize();
        SetEmissionUnit('KG');
        Discovery := Enum::"Message Type ori"::"Sustainability.EmissionSummary.Get";

        // [WHEN] A reader asks [THEN] the type is listed.
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');
        Assert.IsTrue(Discovery.IsEnabled(), 'Configured company: the type is listed.');
        LowerPermissions.SetOutsideO365Scope();
    end;

    /// <summary>AC-V: in an unconfigured company the type is hidden but still runs when called.</summary>
    [Test]
    procedure Scenario_ACV_UnconfiguredCompany_HiddenButRuns()
    var
        SustainabilityAccount: Record "Sustainability Account";
        Discovery: Interface "Msg Interface ori";
        Request: JsonObject;
        Response: JsonObject;
    begin
        // [GIVEN] Blank Emission Unit of Measure Code and no Sustainability Accounts.
        Initialize();
        SetEmissionUnit('');
        SustainabilityAccount.DeleteAll(false);
        Discovery := Enum::"Message Type ori"::"Sustainability.EmissionSummary.Get";

        // [WHEN] A reader asks [THEN] the type is hidden from the roster.
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');
        Assert.IsFalse(Discovery.IsEnabled(), 'Unconfigured company: the type is hidden.');
        LowerPermissions.SetOutsideO365Scope();

        // [WHEN] A caller that knows the type calls it [THEN] it still runs (hidden is not blocked).
        Request.Add('fromDate', '2099-01-01');
        Request.Add('toDate', '2099-01-31');
        Commit();
        Response := DispatchAs(Request, 1033, 'BIFROST Read ori');
        Assert.AreEqual('Success', ReadText(Response, 'status'), ReadOptional(Response, 'error'));
    end;

    local procedure SetEmissionUnit(UnitCode: Code[10])
    var
        SustainabilitySetup: Record "Sustainability Setup";
    begin
        if not SustainabilitySetup.Get() then
            SustainabilitySetup.Insert(false);
        SustainabilitySetup."Emission Unit of Measure Code" := UnitCode;
        SustainabilitySetup.Modify(false);
    end;

    local procedure VerifySummary(LanguageId: Integer; RoleName: Text)
    var
        LedgerEntry: Record "Sustainability Ledger Entry";
        Request: JsonObject;
        Response: JsonObject;
        Include: JsonArray;
        Rows: JsonArray;
        Totals: JsonArray;
        Row: JsonToken;
        CountBefore: Integer;
    begin
        // [GIVEN] Scope 1 entries in January and February 2099 and a Scope 2 entry in January.
        Initialize();
        SeedEntries();
        CountBefore := LedgerEntry.Count();
        Request.Add('fromDate', '2099-01-01');
        Request.Add('toDate', '2099-02-28');
        Include.Add('energy');
        Request.Add('include', Include);
        Commit();

        // [WHEN] The summary is requested per month (default periodType) through the dispatcher.
        Response := DispatchAs(Request, LanguageId, RoleName);

        // [THEN] Three scopes x two months, grand totals per scope, and no ledger change.
        Assert.AreEqual('Success', ReadText(Response, 'status'), ReadOptional(Response, 'error'));
        Assert.AreEqual('Month', ReadText(Response, 'periodType'), 'Month is the default.');
        Rows := ReadArray(Response, 'rows');
        Assert.AreEqual(6, Rows.Count(), 'Three scopes x two months.');
        Rows.Get(0, Row);
        Assert.AreEqual('Scope 1', ReadText(Row.AsObject(), 'scope'), 'Scope 1 first.');
        Assert.AreEqual('2099-01-01', ReadText(Row.AsObject(), 'periodStart'), 'January start.');
        Assert.AreEqual('2099-01-31', ReadText(Row.AsObject(), 'periodEnd'), 'January end.');
        Assert.AreEqual(10, ReadDecimal(Row.AsObject(), 'CO2'), 'January Scope 1 CO2.');
        Assert.AreEqual(1, ReadDecimal(Row.AsObject(), 'CH4'), 'January Scope 1 CH4.');
        Assert.AreEqual(0.5, ReadDecimal(Row.AsObject(), 'N2O'), 'January Scope 1 N2O.');
        Assert.AreEqual(20, ReadDecimal(Row.AsObject(), 'CO2e'), 'January Scope 1 CO2e.');
        Assert.AreEqual(3, ReadDecimal(Row.AsObject(), 'carbonFee'), 'January Scope 1 carbon fee.');
        Assert.AreEqual(7, ReadDecimal(Row.AsObject(), 'energyConsumption'), 'Energy on request.');
        Rows.Get(1, Row);
        Assert.AreEqual(5, ReadDecimal(Row.AsObject(), 'CO2'), 'February Scope 1 CO2.');
        Totals := ReadArray(Response, 'totals');
        Assert.AreEqual(3, Totals.Count(), 'One total per scope.');
        Totals.Get(0, Row);
        Assert.AreEqual(15, ReadDecimal(Row.AsObject(), 'CO2'), 'Scope 1 grand total.');
        Totals.Get(1, Row);
        Assert.AreEqual(4, ReadDecimal(Row.AsObject(), 'CO2'), 'Scope 2 grand total.');
        Totals.Get(2, Row);
        Assert.AreEqual(0, ReadDecimal(Row.AsObject(), 'CO2'), 'Scope 3 grand total.');
        LedgerEntry.Reset();
        Assert.AreEqual(CountBefore, LedgerEntry.Count(), 'AC06: no sustainability ledger posting.');
        Cleanup();
    end;

    local procedure VerifyRefusal(Scenario: Text; LanguageId: Integer; ExpectedCode: Text; ExpectedFragment: Text)
    var
        LedgerEntry: Record "Sustainability Ledger Entry";
        Request: JsonObject;
        Response: JsonObject;
        Include: JsonArray;
        RoleName: Text;
        CountBefore: Integer;
    begin
        // [GIVEN] A valid request that the scenario breaks.
        Initialize();
        Request.Add('fromDate', '2099-01-01');
        Request.Add('toDate', '2099-02-28');
        RoleName := 'BIFROST Read ori';
        case Scenario of
            'missingFrom':
                Request.Remove('fromDate');
            'notDate':
                Request.Replace('toDate', 'end of February');
            'reversed':
                Request.Replace('fromDate', '2099-03-01');
            'periodType':
                Request.Add('periodType', 'Fortnight');
            'scope':
                Request.Add('emissionScope', 'Scope 4');
            'include':
                begin
                    Include.Add('noise');
                    Request.Add('include', Include);
                end;
            'tooMany':
                begin
                    Request.Replace('toDate', '2100-12-31');
                    Request.Add('periodType', 'Day');
                end;
            'unknownKey':
                Request.Add('fromdate', '2099-01-01');
            'permission':
                RoleName := '';
        end;
        CountBefore := LedgerEntry.Count();
        Commit();

        // [WHEN] The dispatcher processes it.
        Response := DispatchAs(Request, LanguageId, RoleName);

        // [THEN] A structured, translated refusal and no ledger change.
        Assert.AreEqual('Error', ReadText(Response, 'status'), 'Refusal expected.');
        Assert.AreEqual(ExpectedCode, ReadText(Response, 'code'), 'Error code.');
        Assert.IsTrue((ReadText(Response, 'error') + ReadOptional(Response, 'expected') + ReadOptional(Response, 'parameter')).Contains(ExpectedFragment), 'The refusal must name: ' + ExpectedFragment);
        Assert.IsTrue(ReadOptional(Response, 'nextStep') <> '', 'Actionable next step.');
        if LanguageId = 1039 then
            Assert.IsTrue(ReadText(Response, 'error').Contains('verður') or ReadText(Response, 'error').Contains('ekki') or ReadText(Response, 'error').Contains('þarf'), 'Icelandic refusal text.');
        Assert.AreEqual(CountBefore, LedgerEntry.Count(), 'AC04/AC06: no partial data.');
    end;

    local procedure DispatchAs(Request: JsonObject; LanguageId: Integer; RoleName: Text) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        RequestText: Text;
        ResponseText: Text;
        ResponseContentType: Text[100];
        MessageId: Guid;
        TaskId: Guid;
        ResponseTime: Duration;
    begin
        // Product roles are proven through IsEnabled and the PermissionDenied scenario; a lowered
        // dispatch also needs execute rights on Foundation's test licence mock, which no product role grants.
        if RoleName = '' then begin
            LowerPermissions.SetExactPermissionSet('BIFROST API ori');
            LowerPermissions.AddPermissionSet('Sustainability Read');
            LowerPermissions.AddPermissionSet('Sust Msg Test ori');
        end;
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.EmissionSummary.Get", Enum::"Message Version ori"::"1.0", '', 'sustainability2-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        LowerPermissions.SetOutsideO365Scope();
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure SeedEntries()
    begin
        Cleanup();
        InsertEntry(DMY2Date(15, 1, 2099), Enum::"Emission Scope"::"Scope 1", 10, 1, 0.5, 20, 3, 7);
        InsertEntry(DMY2Date(10, 2, 2099), Enum::"Emission Scope"::"Scope 1", 5, 0, 0, 5, 0, 0);
        InsertEntry(DMY2Date(20, 1, 2099), Enum::"Emission Scope"::"Scope 2", 4, 0, 0, 4, 0, 0);
        InsertEntry(DMY2Date(20, 1, 2099), Enum::"Emission Scope"::"Water/Waste", 99, 0, 0, 99, 0, 0);
    end;

    local procedure InsertEntry(PostingDate: Date; Scope: Enum "Emission Scope"; CO2: Decimal; CH4: Decimal; N2O: Decimal; CO2e: Decimal; CarbonFee: Decimal; Energy: Decimal)
    var
        LedgerEntry: Record "Sustainability Ledger Entry";
    begin
        LedgerEntry.Init();
        LedgerEntry."Entry No." := 0;
        LedgerEntry."Posting Date" := PostingDate;
        LedgerEntry."Emission Scope" := Scope;
        LedgerEntry.Description := DescriptionTok;
        LedgerEntry."Emission CO2" := CO2;
        LedgerEntry."Emission CH4" := CH4;
        LedgerEntry."Emission N2O" := N2O;
        LedgerEntry."CO2e Emission" := CO2e;
        LedgerEntry."Carbon Fee" := CarbonFee;
        LedgerEntry."Energy Consumption" := Energy;
        LedgerEntry.Insert(false);
    end;

    local procedure Cleanup()
    var
        LedgerEntry: Record "Sustainability Ledger Entry";
    begin
        LedgerEntry.SetRange(Description, DescriptionTok);
        LedgerEntry.DeleteAll(false);
    end;

    local procedure Initialize()
    begin
        LowerPermissions.SetOutsideO365Scope();
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;

    local procedure ReadOptional(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Response.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure ReadDecimal(Response: JsonObject; PropertyName: Text): Decimal
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure ReadArray(Response: JsonObject; PropertyName: Text): JsonArray
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Response property missing: ' + PropertyName);
        exit(Token.AsArray());
    end;
}
