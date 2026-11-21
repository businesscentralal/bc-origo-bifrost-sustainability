namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Exercises category writes and atomic refusals through Foundation's public dispatcher.</summary>
codeunit 98030 "Sust Category Set Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>Verifies happy through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_happy_1033()
    begin
        VerifyScenario('happy', 1033);
    end;

    /// <summary>Verifies happy through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_happy_1039()
    begin
        VerifyScenario('happy', 1039);
    end;

    /// <summary>Verifies retry through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_retry_1033()
    begin
        VerifyScenario('retry', 1033);
    end;

    /// <summary>Verifies retry through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_retry_1039()
    begin
        VerifyScenario('retry', 1039);
    end;

    /// <summary>Verifies omitted through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_omitted_1033()
    begin
        VerifyScenario('omitted', 1033);
    end;

    /// <summary>Verifies omitted through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_omitted_1039()
    begin
        VerifyScenario('omitted', 1039);
    end;

    /// <summary>Verifies missing through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_missing_1033()
    begin
        VerifyScenario('missing', 1033);
    end;

    /// <summary>Verifies missing through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_missing_1039()
    begin
        VerifyScenario('missing', 1039);
    end;

    /// <summary>Verifies empty through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_empty_1033()
    begin
        VerifyScenario('empty', 1033);
    end;

    /// <summary>Verifies empty through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_empty_1039()
    begin
        VerifyScenario('empty', 1039);
    end;

    /// <summary>Verifies scope through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_scope_1033()
    begin
        VerifyScenario('scope', 1033);
    end;

    /// <summary>Verifies scope through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_scope_1039()
    begin
        VerifyScenario('scope', 1039);
    end;

    /// <summary>Verifies foundation through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_foundation_1033()
    begin
        VerifyScenario('foundation', 1033);
    end;

    /// <summary>Verifies foundation through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_foundation_1039()
    begin
        VerifyScenario('foundation', 1039);
    end;

    /// <summary>Verifies unknown through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC05_unknown_1033()
    begin
        VerifyScenario('unknown', 1033);
    end;

    /// <summary>Verifies unknown through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC05_unknown_1039()
    begin
        VerifyScenario('unknown', 1039);
    end;

    /// <summary>Verifies nestedUnknown through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC05_nestedUnknown_1033()
    begin
        VerifyScenario('nestedUnknown', 1033);
    end;

    /// <summary>Verifies nestedUnknown through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC05_nestedUnknown_1039()
    begin
        VerifyScenario('nestedUnknown', 1039);
    end;

    /// <summary>Verifies missingSubcode through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_missingSubcode_1033()
    begin
        VerifyScenario('missingSubcode', 1033);
    end;

    /// <summary>Verifies missingSubcode through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_missingSubcode_1039()
    begin
        VerifyScenario('missingSubcode', 1039);
    end;

    /// <summary>Verifies longCode through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_longCode_1033()
    begin
        VerifyScenario('longCode', 1033);
    end;

    /// <summary>Verifies longCode through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_longCode_1039()
    begin
        VerifyScenario('longCode', 1039);
    end;

    /// <summary>Verifies longDescription through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_longDescription_1033()
    begin
        VerifyScenario('longDescription', 1033);
    end;

    /// <summary>Verifies longDescription through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_longDescription_1039()
    begin
        VerifyScenario('longDescription', 1039);
    end;

    /// <summary>Verifies maxLength through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_maxLength_1033()
    begin
        VerifyScenario('maxLength', 1033);
    end;

    /// <summary>Verifies maxLength through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_maxLength_1039()
    begin
        VerifyScenario('maxLength', 1039);
    end;

    /// <summary>Verifies boolean through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_boolean_1033()
    begin
        VerifyScenario('boolean', 1033);
    end;

    /// <summary>Verifies boolean through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_boolean_1039()
    begin
        VerifyScenario('boolean', 1039);
    end;

    /// <summary>Verifies null through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_null_1033()
    begin
        VerifyScenario('null', 1033);
    end;

    /// <summary>Verifies null through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_null_1039()
    begin
        VerifyScenario('null', 1039);
    end;

    /// <summary>Verifies array through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_array_1033()
    begin
        VerifyScenario('array', 1033);
    end;

    /// <summary>Verifies array through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_array_1039()
    begin
        VerifyScenario('array', 1039);
    end;

    /// <summary>Verifies subObject through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_subObject_1033()
    begin
        VerifyScenario('subObject', 1033);
    end;

    /// <summary>Verifies subObject through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_subObject_1039()
    begin
        VerifyScenario('subObject', 1039);
    end;

    /// <summary>Verifies lateNumber through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_lateNumber_1033()
    begin
        VerifyScenario('lateNumber', 1033);
    end;

    /// <summary>Verifies lateNumber through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_lateNumber_1039()
    begin
        VerifyScenario('lateNumber', 1039);
    end;

    /// <summary>Verifies rollbackUpdate through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_rollbackUpdate_1033()
    begin
        VerifyScenario('rollbackUpdate', 1033);
    end;

    /// <summary>Verifies rollbackUpdate through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_rollbackUpdate_1039()
    begin
        VerifyScenario('rollbackUpdate', 1039);
    end;

    /// <summary>Verifies permission through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_ACP_permission_1033()
    begin
        VerifyScenario('permission', 1033);
    end;

    /// <summary>Verifies permission through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_ACP_permission_1039()
    begin
        VerifyScenario('permission', 1039);
    end;

    /// <summary>Verifies ledger through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC04_ledger_1033()
    begin
        VerifyScenario('ledger', 1033);
    end;

    /// <summary>Verifies ledger through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC04_ledger_1039()
    begin
        VerifyScenario('ledger', 1039);
    end;

    /// <summary>Verifies custom through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_custom_1033()
    begin
        VerifyScenario('custom', 1033);
    end;

    /// <summary>Verifies custom through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_custom_1039()
    begin
        VerifyScenario('custom', 1039);
    end;

    /// <summary>Verifies water through the dispatcher in language 1033.</summary>
    [Test]
    procedure Scenario_AC03_water_1033()
    begin
        VerifyScenario('water', 1033);
    end;

    /// <summary>Verifies water through the dispatcher in language 1039.</summary>
    [Test]
    procedure Scenario_AC03_water_1039()
    begin
        VerifyScenario('water', 1039);
    end;

    local procedure VerifyScenario(Scenario: Text; LanguageId: Integer)
    var
        Category: Record "Sustain. Account Category";
        Subcategory: Record "Sustain. Account Subcategory";
        Ledger: Record "Sustainability Ledger Entry";
        Setup: Record "Sustainability Setup";
        Request: JsonObject;
        Response: JsonObject;
        Entry: JsonObject;
        Entries: JsonArray;
        Token: JsonToken;
        CategoryToken: JsonToken;
        RunCode: Code[20];
        OriginalId: Guid;
        OriginalBlock: Boolean;
        OriginalLedgerCount: Integer;
        LedgerEntryNo: Integer;
        ExpectedCode: Text;
        IsSuccess: Boolean;
    begin
        // #5 AC01-AC06, AC-P, AC-L, AC-T | No date assumptions; synthetic X-prefixed fixtures only.
        LowerPermissions.SetOutsideO365Scope();
        RunCode := CopyStr('XCAT5-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        Request.Add('code', RunCode);
        Request.Add('description', 'Original category');
        Request.Add('emissionScope', 'Scope 1');
        Request.Add('calculationFoundation', 'Fuel/Electricity');
        Request.Add('co2', true);
        Request.Add('ch4', true);
        Request.Add('n2o', true);
        Entry.Add('code', 'XFUEL');
        Entry.Add('description', 'Demo fuel');
        Entry.Add('emissionFactorCO2', 2.68);
        Entry.Add('emissionFactorCH4', 0.01);
        Entry.Add('emissionFactorN2O', 0.02);
        Entry.Add('renewableEnergy', true);
        Entries.Add(Entry);
        Request.Add('subcategories', Entries);
        ExpectedCode := 'InvalidParameter';
        IsSuccess := Scenario in ['happy', 'retry', 'omitted', 'maxLength', 'custom', 'water'];
        case Scenario of
            'missing': begin
                Request.Remove('code');
                ExpectedCode := 'MissingParameter';
            end;
            'empty': begin
                Request.Replace('code', '   ');
                ExpectedCode := 'MissingParameter';
            end;
            'scope': Request.Replace('emissionScope', 'Scope 99');
            'foundation': Request.Replace('calculationFoundation', 'Unknown');
            'unknown': begin
                Request.Add('descripton', 'misspelled');
                ExpectedCode := 'UnknownParameter';
            end;
            'nestedUnknown': begin
                Entry.Add('emissionFactorCo2', 7);
                Clear(Entries);
                Entries.Add(Entry);
                Request.Replace('subcategories', Entries);
                ExpectedCode := 'UnknownParameter';
            end;
            'missingSubcode': begin
                Entry.Remove('code');
                Clear(Entries);
                Entries.Add(Entry);
                Request.Replace('subcategories', Entries);
                ExpectedCode := 'MissingParameter';
            end;
            'longCode': Request.Replace('code', PadStr('X', 21, 'X'));
            'longDescription': Request.Replace('description', PadStr('X', 101, 'X'));
            'maxLength': Request.Replace('description', PadStr('X', 100, 'X'));
            'boolean': Request.Replace('co2', 'true');
            'null': begin
                Clear(Token);
                Token.ReadFrom('null');
                Request.Replace('description', Token);
            end;
            'array': Request.Replace('subcategories', 'invalid');
            'subObject': begin
                Clear(Entries);
                Entries.Add(3);
                Request.Replace('subcategories', Entries);
            end;
            'lateNumber': begin
                Entry.Replace('code', 'XBAD');
                Entry.Replace('emissionFactorCO2', 'invalid');
                Entries.Add(Entry);
                Request.Replace('subcategories', Entries);
            end;
            'custom': begin
                Request.Replace('calculationFoundation', 'Custom');
                Request.Add('customValue', 'Fuel units');
                Request.Add('calculateFromGeneralLedger', true);
                Request.Add('glAccountFilter', '1000..1999');
                Request.Add('globalDimension1Filter', 'ADMIN');
                Request.Add('globalDimension2Filter', 'SMALL');
            end;
            'water': begin
                Request.Replace('emissionScope', 'Water/Waste');
                Request.Replace('co2', false);
                Request.Replace('ch4', false);
                Request.Replace('n2o', false);
                Request.Add('waterIntensity', true);
                Clear(Entries);
                Request.Replace('subcategories', Entries);
            end;
        end;
        if Scenario in ['omitted', 'ledger', 'rollbackUpdate'] then begin
            Category.Init();
            Category.Code := RunCode;
            Category.Description := 'Stored description';
            Category."Emission Scope" := Category."Emission Scope"::"Scope 1";
            Category.CO2 := true;
            Category.Insert(false);
            OriginalId := Category.SystemId;
            Subcategory.Init();
            Subcategory."Category Code" := RunCode;
            Subcategory.Code := 'XKEEP';
            Subcategory.Description := 'Keep me';
            Subcategory.Insert(false);
        end;
        if Scenario = 'omitted' then begin
            Clear(Request);
            Request.Add('code', RunCode);
            Clear(Entries);
            Request.Add('subcategories', Entries);
        end;
        if Scenario = 'rollbackUpdate' then begin
            Entry.Replace('code', 'XBAD');
            Entry.Replace('emissionFactorCO2', 'invalid');
            Entries.Add(Entry);
            Request.Replace('subcategories', Entries);
        end;
        if Scenario = 'ledger' then begin
            if not Setup.Get() then begin
                Setup.Init();
                Setup.Insert(false);
            end;
            OriginalBlock := Setup."Block Change If Entry Exists";
            Setup."Block Change If Entry Exists" := true;
            Setup.Modify(false);
            Ledger.LockTable();
            if Ledger.FindLast() then
                LedgerEntryNo := Ledger."Entry No.";
            Ledger.Init();
            Ledger."Entry No." := LedgerEntryNo + 1;
            Ledger."Account Category" := RunCode;
            Ledger.Insert(false);
            Request.Replace('emissionScope', 'Scope 2');
            ExpectedCode := 'BusinessCentralError';
        end;
        OriginalLedgerCount := Ledger.Count();
        Commit();
        if Scenario = 'permission' then begin
            LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
            ExpectedCode := 'PermissionDenied';
        end else begin
            LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
            LowerPermissions.AddPermissionSet('BIFROST SustFull ori');
        end;
        LowerPermissions.AddPermissionSet('BIFROST API ori');
        // [WHEN] The public dispatcher runs the same write path as an external call.
        Response := Dispatch(Request, LanguageId);
        LowerPermissions.SetOutsideO365Scope();
        // [THEN] Success returns stored values; a refusal preserves every original record.
        Assert.AreEqual(OriginalLedgerCount, Ledger.Count(), 'AC06: category maintenance must not post.');
        if IsSuccess then begin
            Assert.AreEqual('Success', ReadText(Response, 'status'), Format(Response));
            Assert.IsTrue(Category.Get(RunCode), 'The category must be stored.');
            Assert.IsTrue(Response.Get('category', CategoryToken), 'Return the stored category.');
            Assert.AreEqual(RunCode, ReadText(CategoryToken.AsObject(), 'code'), 'Stored code in response.');
            Assert.IsTrue(Response.Get('subcategories', Token), 'Return all stored subcategories.');
            if Scenario in ['happy', 'retry', 'maxLength', 'custom'] then begin
                Subcategory.Get(RunCode, 'XFUEL');
                Assert.AreEqual(2.68, Subcategory."Emission Factor CO2", 'Validate the supplied emission factor.');
                Assert.AreEqual(0.01, Subcategory."Emission Factor CH4", 'CH4 factor.');
                Assert.AreEqual(0.02, Subcategory."Emission Factor N2O", 'N2O factor.');
                Assert.IsTrue(Subcategory."Renewable Energy", 'Renewable energy must be stored.');
                Assert.AreEqual(1, Token.AsArray().Count(), 'One stored subcategory.');
            end;
            if Scenario = 'maxLength' then
                Assert.AreEqual(100, StrLen(Category.Description), 'Exact length boundary is accepted.');
            if Scenario = 'omitted' then begin
                Assert.AreEqual(OriginalId, Category.SystemId, 'An update must retain the record identity.');
                Assert.AreEqual('Stored description', Category.Description, 'Omitted fields are unchanged.');
                Assert.IsTrue(Subcategory.Get(RunCode, 'XKEEP'), 'Unlisted subcategories remain.');
                Assert.AreEqual(1, Token.AsArray().Count(), 'Response includes unlisted subcategories.');
            end;
            if Scenario = 'custom' then begin
                Assert.IsTrue(Category."Calculate from General Ledger", 'General-ledger collection is enabled.');
                Assert.AreEqual('1000..1999', Category."G/L Account Filter", 'G/L collection filter.');
                Assert.AreEqual('ADMIN', Category."Global Dimension 1 Filter", 'First dimension filter.');
                Assert.AreEqual('SMALL', Category."Global Dimension 2 Filter", 'Second dimension filter.');
            end;
            if Scenario = 'water' then
                Assert.IsTrue(Category."Water Intensity", 'Water flag passes Microsoft validation.');
            if Scenario = 'retry' then begin
                OriginalId := Category.SystemId;
                Commit();
                LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
                LowerPermissions.AddPermissionSet('BIFROST SustFull ori');
                LowerPermissions.AddPermissionSet('BIFROST API ori');
                Response := Dispatch(Request, LanguageId);
                LowerPermissions.SetOutsideO365Scope();
                Assert.AreEqual('Success', ReadText(Response, 'status'), Format(Response));
                Category.Get(RunCode);
                Assert.AreEqual(OriginalId, Category.SystemId, 'Retry must update the same category.');
                Subcategory.SetRange("Category Code", RunCode);
                Assert.AreEqual(1, Subcategory.Count(), 'Retry must not duplicate subcategories.');
            end;
        end else begin
            Assert.AreEqual('Error', ReadText(Response, 'status'), Format(Response));
            Assert.AreEqual(ExpectedCode, ReadText(Response, 'code'), Format(Response));
            Assert.IsTrue(StrLen(ReadText(Response, 'error')) > 0, 'A refusal needs a useful message.');
            if Scenario in ['ledger', 'rollbackUpdate'] then begin
                Category.Get(RunCode);
                Assert.AreEqual('Stored description', Category.Description, 'A failed update must be rolled back.');
                Assert.AreEqual(Category."Emission Scope"::"Scope 1", Category."Emission Scope", 'Scope must be unchanged.');
                Assert.IsTrue(Subcategory.Get(RunCode, 'XKEEP'), 'Existing subcategory remains.');
                Assert.IsFalse(Subcategory.Get(RunCode, 'XFUEL'), 'A subcategory written before refusal must roll back.');
            end else
                Assert.IsFalse(Category.Get(RunCode), 'Refusal must not leave a category.');
            if Scenario = 'scope' then
                Assert.IsTrue(StrPos(ReadText(Response, 'error'), 'Scope 1') > 0, 'List allowed scope values.');
            if Scenario = 'foundation' then
                Assert.IsTrue(StrPos(ReadText(Response, 'error'), 'Fuel/Electricity') > 0, 'List allowed calculation values.');
        end;
        if Scenario = 'ledger' then begin
            Ledger.Get(LedgerEntryNo + 1);
            Ledger.Delete(false);
            Setup.Get();
            Setup."Block Change If Entry Exists" := OriginalBlock;
            Setup.Modify(false);
        end;
        Subcategory.Reset();
        Subcategory.SetRange("Category Code", RunCode);
        Subcategory.DeleteAll(false);
        if Category.Get(RunCode) then
            Category.Delete(false);
        Commit();
    end;

    local procedure Dispatch(Request: JsonObject; LanguageId: Integer) Response: JsonObject
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
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Category.Set", Enum::"Message Version ori"::"1.0", '', 'category5-tests', 'application/json', RequestContent, TaskId, LanguageId, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
    end;

    local procedure ReadText(Response: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Response.Get(PropertyName, Token), 'Missing response property: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;
}
