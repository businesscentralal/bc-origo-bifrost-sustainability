namespace Origo.Bifrost.Sustainability;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Posting;
using Origo.Bifrost;

/// <summary>Creates journal lines with native field validation in one transaction, without posting.</summary>
codeunit 70009213 "Sust Jnl Create Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    TableNo = "Message Argument ori";
    InherentPermissions = X;

    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        BatchErr: Label 'The sustainability template or batch does not exist.', Comment = 'is-IS=Sniðmát eða keyrsla sjálfbærnibókar er ekki til.';
        AccountErr: Label 'The sustainability account does not exist, is blocked, or is not a posting account.', Comment = 'is-IS=Sjálfbærnireikningurinn er ekki til, er lokaður eða er ekki bókunarreikningur.';
        AmbiguousErr: Label 'A line cannot contain both manual emissions and formula inputs.', Comment = 'is-IS=Lína má ekki innihalda bæði handvirka losun og inntak fyrir formúlu.';
        ScopeErr: Label 'The account emission scope does not match the journal batch.', Comment = 'is-IS=Losunarumfang reikningsins samræmist ekki keyrslu bókarinnar.';
        PermissionErr: Label 'The Full sustainability role and journal write permissions are required.', Comment = 'is-IS=Fullt sjálfbærnihlutverk og skrifheimildir fyrir bók eru nauðsynleg.';
        InputErr: Label 'Invalid or missing value for %1.', Comment = '%1 = request key||is-IS=Ógilt gildi eða gildi vantar fyrir %1.';
        FixLbl: Label 'Correct the request using the contract and retry. No lines were created.', Comment = 'is-IS=Leiðréttu beiðnina samkvæmt samningnum og reyndu aftur. Engar línur voru stofnaðar.';
        NativeFixLbl: Label 'Correct the value reported by Business Central and retry the complete request.', Comment = 'is-IS=Leiðréttu gildið sem Business Central tilgreinir og sendu alla beiðnina aftur.';
        DescriptionLbl: Label 'Creates unposted sustainability journal lines from manual emissions or formula inputs. A retry adds more lines.', MaxLength = 250, Comment = 'is-IS=Stofnar óbókaðar sjálfbærnibókarlínur með handvirkri losun eða inntaki fyrir formúlur. Endurtekning bætir við fleiri línum.';

    trigger OnRun()
    begin
        PerformWrite(Rec);
    end;

    /// <summary>Visibility is configuration plus the caller capability; hidden is not blocked.</summary>
    procedure IsEnabled(): Boolean
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        exit(CanWrite() and Configured.IsConfigured());
    end;

    /// <summary>Identifies the journal line table for discovery.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Sustainability Jnl. Line");
    end;

    /// <summary>Describes journal creation.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Returns bilingual discovery keywords.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'Sustainability.Journal.Create, sustainability, journal, emissions, formula, create', Comment = 'is-IS=Sustainability.Journal.Create, sjálfbærni, bók, losun, formúla, stofna';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Describes the selection in the roster.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Declares a reversible write.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Checks permissions and uses Foundation's isolated write boundary.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not CanWrite() then begin
            Argument.RespondWithError(Enum::"Bifrost Error Code ori"::PermissionDenied, PermissionErr, '', '', '', PermissionErr);
            exit;
        end;
        if Argument."Omit Commit" then begin
            PerformWrite(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Sust Jnl Create Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    local procedure CanWrite(): Boolean
    var
        Capability: Record "Sust Jnl Create Cap ori";
        JournalLine: Record "Sustainability Jnl. Line";
        JournalBatch: Record "Sustainability Jnl. Batch";
    begin
        exit(Capability.ReadPermission() and JournalLine.WritePermission() and JournalBatch.WritePermission());
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformWrite(var Argument: Record "Message Argument ori")
    var
        JournalTemplate: Record "Sustainability Jnl. Template";
        Batch: Record "Sustainability Jnl. Batch";
        PreviousLine: Record "Sustainability Jnl. Line";
        JournalLine: Record "Sustainability Jnl. Line";
        RequestJson: JsonObject;
        Response: JsonObject;
        Lines: JsonArray;
        Results: JsonArray;
        Token: JsonToken;
        TemplateName: Code[10];
        BatchName: Code[10];
        CreateBatch: Boolean;
        BatchExists: Boolean;
        NextLineNo: Integer;
    begin
        if not CanWrite() then
            Error(PermissionErr);
        RequestJson := Argument.GetRequestJson();
        TemplateName := CopyStr(ReadText(RequestJson, 'templateName', 10, true), 1, 10);
        BatchName := CopyStr(ReadText(RequestJson, 'batchName', 10, true), 1, 10);
        if RequestJson.Get('createBatch', Token) then
            CreateBatch := Token.AsValue().AsBoolean();
        if not RequestJson.Get('lines', Token) then
            Error(InputErr, 'lines');
        Lines := Token.AsArray();
        if Lines.Count() = 0 then
            Error(InputErr, 'lines');
        if not JournalTemplate.Get(TemplateName) then begin
            Refuse(Argument, 'BatchNotFound', BatchErr);
            exit;
        end;
        BatchExists := Batch.Get(TemplateName, BatchName);
        if not BatchExists then begin
            if not CreateBatch then begin
                Refuse(Argument, 'BatchNotFound', BatchErr);
                exit;
            end;
            Batch.Init();
            Batch.Validate("Journal Template Name", TemplateName);
            Batch.Validate(Name, BatchName);
            Batch.Validate(Description, JournalTemplate.Description);
        end;
        // Refusals below are read-only and precede ALL writes, including batch/dimension creation.
        foreach Token in Lines do
            if not CheckLine(Token.AsObject(), Batch, Argument) then
                exit;
        if not BatchExists then
            Batch.Insert(true);
        PreviousLine.LockTable();
        PreviousLine.SetRange("Journal Template Name", TemplateName);
        PreviousLine.SetRange("Journal Batch Name", BatchName);
        if PreviousLine.FindLast() then
            NextLineNo := PreviousLine."Line No.";
        foreach Token in Lines do begin
            NextLineNo += 10000;
            Argument.SetErrorContext('lines', DescriptionLbl, NativeFixLbl);
            CreateLine(Token.AsObject(), Batch, PreviousLine, NextLineNo, JournalLine);
            Results.Add(LineResult(JournalLine));
            PreviousLine := JournalLine;
        end;
        Argument.ClearErrorContext();
        Response.Add('status', 'Success');
        Response.Add('lines', Results);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := 'text/json';
    end;

    local procedure CheckLine(LineJson: JsonObject; Batch: Record "Sustainability Jnl. Batch"; var Argument: Record "Message Argument ori"): Boolean
    var
        Account: Record "Sustainability Account";
        Category: Record "Sustain. Account Category";
        AccountNo: Code[20];
    begin
        if HasManual(LineJson) and HasFormula(LineJson) then begin
            Refuse(Argument, 'AmbiguousInput', AmbiguousErr);
            exit(false);
        end;
        AccountNo := CopyStr(ReadText(LineJson, 'accountNo', 20, true), 1, 20);
        if not Account.Get(AccountNo) then begin
            Refuse(Argument, 'InvalidAccount', AccountErr);
            exit(false);
        end;
        if Account.Blocked or (Account."Account Type" <> Account."Account Type"::Posting) then begin
            Refuse(Argument, 'InvalidAccount', AccountErr);
            exit(false);
        end;
        if Category.Get(Account.Category) then
            if (Batch."Emission Scope" <> Batch."Emission Scope"::" ") and (Batch."Emission Scope" <> Category."Emission Scope") then begin
                Refuse(Argument, 'ScopeMismatch', ScopeErr);
                exit(false);
            end;
        exit(true);
    end;

    local procedure HasManual(LineJson: JsonObject): Boolean
    begin
        exit(LineJson.Contains('emissionCO2') or LineJson.Contains('emissionCH4') or LineJson.Contains('emissionN2O'));
    end;

    local procedure HasFormula(LineJson: JsonObject): Boolean
    begin
        exit(LineJson.Contains('fuelOrElectricity') or LineJson.Contains('distance') or LineJson.Contains('customAmount') or LineJson.Contains('installationMultiplier') or LineJson.Contains('timeFactor'));
    end;

    local procedure CreateLine(LineJson: JsonObject; Batch: Record "Sustainability Jnl. Batch"; PreviousLine: Record "Sustainability Jnl. Line"; LineNo: Integer; var JournalLine: Record "Sustainability Jnl. Line")
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Token: JsonToken;
        PostingDate: Date;
        DocumentNo: Code[20];
    begin
        Clear(JournalLine);
        JournalLine.Init();
        JournalLine.Validate("Journal Template Name", Batch."Journal Template Name");
        JournalLine.Validate("Journal Batch Name", Batch.Name);
        JournalLine.Validate("Line No.", LineNo);
        if not LineJson.Get('postingDate', Token) then
            Error(InputErr, 'postingDate');
        PostingDate := Token.AsValue().AsDate();
        JournalLine.Validate("Posting Date", PostingDate);
        JournalLine.TestField("Posting Date");
        DocumentNo := CopyStr(ReadText(LineJson, 'documentNo', 20, false), 1, 20);
        if DocumentNo = '' then
            if Batch."No Series" <> '' then
                if PreviousLine."Document No." = '' then
                    DocumentNo := NoSeriesBatch.PeekNextNo(Batch."No Series", PostingDate)
                else
                    DocumentNo := NoSeriesBatch.SimulateGetNextNo(Batch."No Series", PostingDate, PreviousLine."Document No.");
        JournalLine.Validate("Document No.", DocumentNo);
        JournalLine.TestField("Document No.");
        JournalLine.Validate("Source Code", Batch."Source Code");
        JournalLine.Validate("Reason Code", Batch."Reason Code");
        JournalLine.Validate("Account No.", CopyStr(ReadText(LineJson, 'accountNo', 20, true), 1, 20));
        if LineJson.Contains('description') then
            JournalLine.Validate(Description, CopyStr(ReadText(LineJson, 'description', 100, false), 1, 100));
        JournalLine.Validate("Manual Input", HasManual(LineJson));
        if LineJson.Contains('unitOfMeasure') then
            JournalLine.Validate("Unit of Measure", CopyStr(ReadText(LineJson, 'unitOfMeasure', 10, false), 1, 10));
        if LineJson.Get('fuelOrElectricity', Token) then
            JournalLine.Validate("Fuel/Electricity", Token.AsValue().AsDecimal());
        if LineJson.Get('distance', Token) then
            JournalLine.Validate("Distance", Token.AsValue().AsDecimal());
        if LineJson.Get('customAmount', Token) then
            JournalLine.Validate("Custom Amount", Token.AsValue().AsDecimal());
        if LineJson.Get('installationMultiplier', Token) then
            JournalLine.Validate("Installation Multiplier", Token.AsValue().AsDecimal());
        if LineJson.Get('timeFactor', Token) then
            JournalLine.Validate("Time Factor", Token.AsValue().AsDecimal());
        if LineJson.Get('emissionCO2', Token) then
            JournalLine.Validate("Emission CO2", Token.AsValue().AsDecimal());
        if LineJson.Get('emissionCH4', Token) then
            JournalLine.Validate("Emission CH4", Token.AsValue().AsDecimal());
        if LineJson.Get('emissionN2O', Token) then
            JournalLine.Validate("Emission N2O", Token.AsValue().AsDecimal());
        if LineJson.Contains('energySourceCode') then
            JournalLine.Validate("Energy Source Code", CopyStr(ReadText(LineJson, 'energySourceCode', 20, false), 1, 20));
        if LineJson.Contains('countryRegionCode') then
            JournalLine.Validate("Country/Region Code", CopyStr(ReadText(LineJson, 'countryRegionCode', 10, false), 1, 10));
        if LineJson.Contains('responsibilityCenter') then
            JournalLine.Validate("Responsibility Center", CopyStr(ReadText(LineJson, 'responsibilityCenter', 10, false), 1, 10));
        if LineJson.Get('dimensions', Token) then
            ApplyDimensions(Token.AsObject(), JournalLine);
        JournalLine.Insert(true);
    end;

    local procedure ApplyDimensions(Dimensions: JsonObject; var JournalLine: Record "Sustainability Jnl. Line")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        DimMgt: Codeunit DimensionManagement;
        DimensionCode: Text;
        ValueCode: Code[20];
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, JournalLine."Dimension Set ID");
        foreach DimensionCode in Dimensions.Keys() do begin
            if (DimensionCode = '') or (StrLen(DimensionCode) > 20) then
                Error(InputErr, 'dimensions');
            Dimension.Get(DimensionCode);
            Dimension.TestField(Blocked, false);
            ValueCode := CopyStr(ReadText(Dimensions, DimensionCode, 20, true), 1, 20);
            DimensionValue.Get(DimensionCode, ValueCode);
            DimensionValue.TestField(Blocked, false);
            DimensionValue.TestField("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
            if TempDimSetEntry.Get(JournalLine."Dimension Set ID", DimensionCode) then
                TempDimSetEntry.Delete();
            TempDimSetEntry.Init();
            TempDimSetEntry."Dimension Set ID" := JournalLine."Dimension Set ID";
            TempDimSetEntry.Validate("Dimension Code", CopyStr(DimensionCode, 1, 20));
            TempDimSetEntry.Validate("Dimension Value Code", ValueCode);
            TempDimSetEntry.Insert();
        end;
        JournalLine.Validate("Dimension Set ID", DimMgt.GetDimensionSetID(TempDimSetEntry));
        if not DimMgt.CheckDimIDComb(JournalLine."Dimension Set ID") then
            Error(DimMgt.GetDimCombErr());
    end;

    local procedure LineResult(JournalLine: Record "Sustainability Jnl. Line") Result: JsonObject
    var
        Category: Record "Sustain. Account Category";
        PostMgt: Codeunit "Sustainability Post Mgt";
        CO2e: Decimal;
        CarbonFee: Decimal;
    begin
        Category.Get(JournalLine."Account Category");
        // This public Microsoft procedure only reads emission factors; it does not post or write a ledger entry.
        PostMgt.UpdateCarbonFeeEmissionValues(Category."Emission Scope", JournalLine."Posting Date", JournalLine."Country/Region Code",
            JournalLine."Emission CO2", JournalLine."Emission N2O", JournalLine."Emission CH4", CO2e, CarbonFee);
        Result.Add('lineNo', JournalLine."Line No.");
        Result.Add('CO2', JournalLine."Emission CO2");
        Result.Add('CH4', JournalLine."Emission CH4");
        Result.Add('N2O', JournalLine."Emission N2O");
        Result.Add('CO2e', CO2e);
    end;

    local procedure ReadText(ObjectJson: JsonObject; ParameterName: Text; MaxLength: Integer; Required: Boolean) Value: Text
    var
        Token: JsonToken;
    begin
        if ObjectJson.Get(ParameterName, Token) then begin
            if not Token.IsValue() then
                Error(InputErr, ParameterName);
            if Token.AsValue().IsNull() then
                Error(InputErr, ParameterName);
            Value := Token.AsValue().AsText();
        end;
        if (StrLen(Value) > MaxLength) or (Required and (Value = '')) then
            Error(InputErr, ParameterName);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; Code: Text; Message: Text)
    var
        Response: JsonObject;
    begin
        Response.Add('status', 'Error');
        Response.Add('code', Code);
        Response.Add('error', Message);
        Response.Add('nextStep', FixLbl);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := 'text/json';
    end;

    /// <summary>Declares the JSON envelope.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    /// <summary>Identifies the template and batch by exact key.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Target.Add(ContractMgt.TargetEntry('data.templateName + data.batchName', 'code', DescriptionLbl));
        exit(true);
    end;

    /// <summary>Declares every supported request key, including nested line keys.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Children: JsonArray;
        LinesParameter: JsonObject;
        P0Lbl: Label 'Existing journal template, maximum 10 characters.', Comment = 'is-IS=Fyrirliggjandi bókarsniðmát, mest 10 stafir.';
        P1Lbl: Label 'Journal batch, maximum 10 characters.', Comment = 'is-IS=Bókarkeyrsla, mest 10 stafir.';
        P2Lbl: Label 'Create a missing batch under the existing template. Defaults to false.', Comment = 'is-IS=Stofna keyrslu sem vantar undir fyrirliggjandi sniðmáti. Sjálfgefið false.';
        P3Lbl: Label 'Nonempty array of lines. The complete request succeeds or rolls back.', Comment = 'is-IS=Listi lína sem má ekki vera tómur. Öll beiðnin tekst eða er afturkölluð.';
        P4Lbl: Label 'Posting date in YYYY-MM-DD format.', Comment = 'is-IS=Bókunardagur á sniðinu YYYY-MM-DD.';
        P5Lbl: Label 'Document number, maximum 20 characters. Defaults from the batch number series at the posting date. Required when there is no series.', Comment = 'is-IS=Skjalanúmer, mest 20 stafir. Sjálfgefið úr númeraröð keyrslu á bókunardegi. Skylda ef engin númeraröð er til.';
        P6Lbl: Label 'Unblocked posting account with direct posting enabled. Maximum 20 characters.', Comment = 'is-IS=Ólokaður bókunarreikningur með beina bókun virka. Mest 20 stafir.';
        P7Lbl: Label 'Description, maximum 100 characters; defaults from the account.', Comment = 'is-IS=Lýsing, mest 100 stafir; sjálfgefið úr reikningi.';
        P8Lbl: Label 'Manual CO2 emission. Cannot be combined with formula inputs.', Comment = 'is-IS=Handvirk CO2-losun. Má ekki blanda við inntak fyrir formúlur.';
        P9Lbl: Label 'Manual CH4 emission. Cannot be combined with formula inputs.', Comment = 'is-IS=Handvirk CH4-losun. Má ekki blanda við inntak fyrir formúlur.';
        P10Lbl: Label 'Manual N2O emission. Cannot be combined with formula inputs.', Comment = 'is-IS=Handvirk N2O-losun. Má ekki blanda við inntak fyrir formúlur.';
        P11Lbl: Label 'Fuel or electricity input for the account category formula.', Comment = 'is-IS=Eldsneyti eða rafmagn fyrir formúlu reikningsflokks.';
        P12Lbl: Label 'Distance input for the account category formula.', Comment = 'is-IS=Vegalengd fyrir formúlu reikningsflokks.';
        P13Lbl: Label 'Custom amount for the account category formula.', Comment = 'is-IS=Sérsniðin fjárhæð fyrir formúlu reikningsflokks.';
        P14Lbl: Label 'Installation multiplier; defaults to 1.', Comment = 'is-IS=Margfaldari uppsetningar; sjálfgefið 1.';
        P15Lbl: Label 'Time factor, at most 1; defaults to zero.', Comment = 'is-IS=Tímastuðull, mest 1; sjálfgefið núll.';
        P16Lbl: Label 'Existing unit of measure, maximum 10 characters. Valid for manual and formula lines.', Comment = 'is-IS=Fyrirliggjandi mælieining, mest 10 stafir. Gildir fyrir handvirkar línur og formúlur.';
        P17Lbl: Label 'Existing energy source code, maximum 20 characters.', Comment = 'is-IS=Fyrirliggjandi orkugjafakóði, mest 20 stafir.';
        P18Lbl: Label 'Existing country or region code, maximum 10 characters.', Comment = 'is-IS=Fyrirliggjandi lands- eða svæðiskóði, mest 10 stafir.';
        P19Lbl: Label 'Existing responsibility center, maximum 10 characters.', Comment = 'is-IS=Fyrirliggjandi ábyrgðarstöð, mest 10 stafir.';
        P20Lbl: Label 'Dimension code to dimension value code map; both at most 20 characters. Merges with account defaults.', Comment = 'is-IS=Vörpun víddarkóða á víddargildiskóða; báðir mest 20 stafir. Bætist við sjálfgefnar víddir reiknings.';
    begin
        Children.Add(ContractMgt.Parameter('postingDate', 'string', true, P4Lbl));
        Children.Add(ContractMgt.Parameter('documentNo', 'string', false, P5Lbl));
        Children.Add(ContractMgt.Parameter('accountNo', 'string', true, P6Lbl));
        Children.Add(ContractMgt.Parameter('description', 'string', false, P7Lbl));
        Children.Add(ContractMgt.Parameter('emissionCO2', 'number', false, P8Lbl));
        Children.Add(ContractMgt.Parameter('emissionCH4', 'number', false, P9Lbl));
        Children.Add(ContractMgt.Parameter('emissionN2O', 'number', false, P10Lbl));
        Children.Add(ContractMgt.Parameter('fuelOrElectricity', 'number', false, P11Lbl));
        Children.Add(ContractMgt.Parameter('distance', 'number', false, P12Lbl));
        Children.Add(ContractMgt.Parameter('customAmount', 'number', false, P13Lbl));
        Children.Add(ContractMgt.Parameter('installationMultiplier', 'number', false, P14Lbl));
        Children.Add(ContractMgt.Parameter('timeFactor', 'number', false, P15Lbl));
        Children.Add(ContractMgt.Parameter('unitOfMeasure', 'string', false, P16Lbl));
        Children.Add(ContractMgt.Parameter('energySourceCode', 'string', false, P17Lbl));
        Children.Add(ContractMgt.Parameter('countryRegionCode', 'string', false, P18Lbl));
        Children.Add(ContractMgt.Parameter('responsibilityCenter', 'string', false, P19Lbl));
        Children.Add(ContractMgt.Parameter('dimensions', 'object', false, P20Lbl));
        Parameters.Add(ContractMgt.Parameter('templateName', 'string', true, P0Lbl));
        Parameters.Add(ContractMgt.Parameter('batchName', 'string', true, P1Lbl));
        Parameters.Add(ContractMgt.Parameter('createBatch', 'boolean', false, P2Lbl));
        LinesParameter := ContractMgt.Parameter('lines', 'array', true, P3Lbl);
        LinesParameter.Add('children', Children);
        Parameters.Add(LinesParameter);
        exit(true);
    end;

    /// <summary>Describes returned line numbers and native emission calculations.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Fields: JsonArray;
        Children: JsonArray;
        LinesField: JsonObject;
        LinesLbl: Label 'Created lines in request order.', Comment = 'is-IS=Stofnaðar línur í röð beiðninnar.';
        NumberLbl: Label 'Assigned journal line number.', Comment = 'is-IS=Úthlutað númer bókarlínu.';
        EmissionLbl: Label 'Validated emission amount.', Comment = 'is-IS=Staðfest losunarmagn.';
        EquivalentLbl: Label 'CO2 equivalent from native emission factors for date, scope and country; zero when no factor exists. No posting.', Comment = 'is-IS=CO2-ígildi úr innbyggðum losunarstuðlum fyrir dagsetningu, umfang og land; núll ef enginn stuðull er til. Engin bókun.';
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success'));
        Children.Add(ContractMgt.ResponseField('lineNo', 'integer', NumberLbl));
        Children.Add(ContractMgt.ResponseField('CO2', 'number', EmissionLbl));
        Children.Add(ContractMgt.ResponseField('CH4', 'number', EmissionLbl));
        Children.Add(ContractMgt.ResponseField('N2O', 'number', EmissionLbl));
        Children.Add(ContractMgt.ResponseField('CO2e', 'number', EquivalentLbl));
        LinesField := ContractMgt.ResponseField('lines', 'array', LinesLbl);
        LinesField.Add('children', Children);
        Fields.Add(LinesField);
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Declares named refusals and native errors with recovery instructions.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        AddContractError(Errors, 'BatchNotFound', BatchErr);
        AddContractError(Errors, 'InvalidAccount', AccountErr);
        AddContractError(Errors, 'AmbiguousInput', AmbiguousErr);
        AddContractError(Errors, 'ScopeMismatch', ScopeErr);
        Errors.Add(ContractMgt.ErrorEntry(Enum::"Bifrost Error Code ori"::PermissionDenied, PermissionErr, PermissionErr));
        Errors.Add(ContractMgt.ErrorEntry(Enum::"Bifrost Error Code ori"::BusinessCentralError, DescriptionLbl, NativeFixLbl));
        exit(true);
    end;

    local procedure AddContractError(var Errors: JsonArray; Code: Text; WhenText: Text)
    var
        Entry: JsonObject;
    begin
        Entry.Add('code', Code);
        Entry.Add('when', WhenText);
        Entry.Add('fix', FixLbl);
        Errors.Add(Entry);
    end;

    /// <summary>Declares atomic writes, permissions, prerequisites and retry semantics.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
        ChangesLbl: Label 'Inserts journal lines and, with createBatch, a missing batch. Standard validation can create dimension sets. No ledger posting.', Comment = 'is-IS=Stofnar bókarlínur og keyrslu sem vantar ef createBatch er virkt. Stöðluð staðfesting getur stofnað víddarsamstæður. Engin fjárhagsbókun.';
        PrerequisiteLbl: Label 'Existing template, valid accounts with category and subcategory, and native journal setup.', Comment = 'is-IS=Fyrirliggjandi sniðmát, gildir reikningar með flokki og undirflokki og innbyggð bókaruppsetning.';
    begin
        Preconditions.Add(PrerequisiteLbl);
        Effect.Add('effect', 'write');
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST SustFull ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>Uses Foundation metering without an override.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional related type chapter is needed.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No automated workflow or posting follows creation.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides a demo request with manual emissions.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.Add(ContractMgt.Example(DescriptionLbl,
            '{"type":"Sustainability.Journal.Create","data":{"templateName":"GENERAL","batchName":"DEFAULT","lines":[{"postingDate":"2026-01-15","documentNo":"SUST0001","accountNo":"1000","emissionCO2":10}]}}',
            '{"status":"Success","lines":[{"lineNo":10000,"CO2":10,"CH4":0,"N2O":0,"CO2e":10}]}'));
        exit(true);
    end;

    /// <summary>Provides the translated overview.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := DescriptionLbl;
        exit(true);
    end;

    /// <summary>Documents transaction boundaries and non-idempotency.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        NotesLbl: Label 'Not idempotent: every successful retry adds lines. All lines and an optional batch form one transaction. The isolated Codeunit.Run commits only on success; the handler calls no Commit. Omit Commit participates in the caller transaction and lets native errors propagate for rollback. Visibility is not an execution block. Unknown keys are refused. Unit of measure is valid in both modes.', Comment = 'is-IS=Ekki ítrekunaröruggt: hver heppnuð endurtekning bætir við línum. Allar línur og valfrjáls keyrsla mynda eina færsluheild. Einangrað Codeunit.Run vistar aðeins þegar aðgerð tekst; meðhöndlarinn kallar ekki á Commit. Omit Commit tekur þátt í færsluheild kallanda og lætur innbyggðar villur berast áfram til afturköllunar. Sýnileiki lokar ekki fyrir framkvæmd. Óþekktum lyklum er hafnað. Mælieining gildir í báðum hamum.';
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
