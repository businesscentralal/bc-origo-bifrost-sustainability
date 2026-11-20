namespace Origo.Bifrost.Sustainability;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Posting;
using Origo.Bifrost;
using System.Utilities;

/// <summary>Checks and previews a sustainability journal with all posting changes rolled back.</summary>
codeunit 70009215 "Sust Preview Post Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    trigger OnRun()
    begin
        PreviewBatch(Rec);
    end;

    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        DescriptionLbl: Label 'Preview the sustainability entries a journal batch would create. All posting changes are rolled back.', MaxLength = 250, Comment = 'is-IS=Forskoða sjálfbærnifærslur sem bókarkeyrsla myndi stofna. Öllum bókunarbreytingum er afturkallað.';
        KeywordsLbl: Label 'preview sustainability journal, simulate emissions posting, check sustainability entries', Comment = 'is-IS=forskoða sjálfbærnibók, herma bókun losunar, athuga sjálfbærnifærslur';
        BatchErr: Label 'Sustainability journal batch %1/%2 does not exist.', Comment = '%1 = template, %2 = batch||is-IS=Keyrsla sjálfbærnibókar %1/%2 er ekki til.';
        BatchFixLbl: Label 'Choose an existing sustainability journal template and batch.', Comment = 'is-IS=Veldu fyrirliggjandi sniðmát og keyrslu sjálfbærnibókar.';
        PermissionErr: Label 'You do not have permission to preview sustainability journals.', Comment = 'is-IS=Þú hefur ekki heimild til að forskoða sjálfbærnibækur.';
        PermissionFixLbl: Label 'Ask an administrator for BIFROST SustRead ori and the required Business Central permissions.', Comment = 'is-IS=Biðjið kerfisstjóra um BIFROST SustRead ori og nauðsynlegar Business Central heimildir.';
        UnknownErr: Label 'Unknown request parameter: %1.', Comment = '%1 = parameter||is-IS=Óþekkt færibreyta beiðni: %1.';
        ParameterErr: Label 'Parameter %1 must be a non-empty string of at most 10 characters.', Comment = '%1 = parameter||is-IS=Færibreytan %1 verður að vera texti með 1 til 10 stöfum.';
        ParameterFixLbl: Label 'Supply only templateName and batchName, using existing journal codes.', Comment = 'is-IS=Tilgreindu aðeins templateName og batchName með fyrirliggjandi bókarkóðum.';
        NotReadyErr: Label 'The sustainability journal is not ready for posting.', Comment = 'is-IS=Sjálfbærnibókin er ekki tilbúin til bókunar.';
        CheckFixLbl: Label 'Run Sustainability.Journal.Check and correct every reported journal error.', Comment = 'is-IS=Keyrðu Sustainability.Journal.Check og leiðréttu allar villur sem koma fram.';
        EmptyErr: Label 'The sustainability journal batch has no lines.', Comment = 'is-IS=Keyrsla sjálfbærnibókar hefur engar línur.';
        PostingErr: Label 'Business Central could not preview this journal. No posting changes were committed.', Comment = 'is-IS=Business Central gat ekki forskoðað þessa bók. Engar bókunarbreytingar voru vistaðar.';

    /// <summary>Executes the public message contract and converts posting failures to a response.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        if not HasPermission() then begin
            Refuse(Argument, 'PermissionDenied', PermissionErr, PermissionFixLbl);
            exit;
        end;
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PreviewBatch(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Sust Preview Post Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    /// <summary>Visibility affects discovery only; a known type still executes when unconfigured.</summary>
    procedure IsEnabled(): Boolean
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        exit(HasPermission() and Configured.IsConfigured());
    end;

    local procedure HasPermission(): Boolean
    var
        Capability: Record "Sust Preview Access ori";
        JournalTemplate: Record "Sustainability Jnl. Template";
        Batch: Record "Sustainability Jnl. Batch";
        Line: Record "Sustainability Jnl. Line";
        Entry: Record "Sustainability Ledger Entry";
    begin
        exit(Capability.ReadPermission() and JournalTemplate.ReadPermission() and Batch.ReadPermission() and Line.ReadPermission() and Entry.ReadPermission());
    end;

    local procedure PreviewBatch(var Argument: Record "Message Argument ori")
    var
        JournalTemplate: Record "Sustainability Jnl. Template";
        Batch: Record "Sustainability Jnl. Batch";
        Line: Record "Sustainability Jnl. Line";
        TempErrors: Record "Error Message" temporary;
        TempEntries: Record "Sustainability Ledger Entry" temporary;
        TempValues: Record "Sustainability Value Entry" temporary;
        Check: Codeunit "Sustainability Jnl.-Check";
        ErrorMgt: Codeunit "Error Message Management";
        ErrorHandler: Codeunit "Error Message Handler";
        Runner: Codeunit "Sust Preview Runner ori";
        Preview: Codeunit "Gen. Jnl.-Post Preview";
        SustPreview: Codeunit "Sust. Preview Posting Handler";
        Instance: Codeunit "Sust. Preview Post Instance";
        SourceRecord: RecordRef;
        Request: JsonObject;
        Response: JsonObject;
        Errors: JsonArray;
        Problem: JsonObject;
        TemplateName: Code[10];
        BatchName: Code[10];
        KeyName: Text;
        ErrorText: Text;
        ParameterToken: JsonToken;
        PreviewSucceeded: Boolean;
        ErrorLineNo: Integer;
    begin
        Request := Argument.GetRequestJson();
        foreach KeyName in Request.Keys() do
            if not (KeyName in ['templateName', 'batchName']) then begin
                Refuse(Argument, 'UnknownParameter', StrSubstNo(UnknownErr, KeyName), ParameterFixLbl);
                exit;
            end;
        if not Request.Get('templateName', ParameterToken) then
            Clear(ParameterToken);
        if not ReadCode(Argument, ParameterToken, 'templateName', TemplateName) then
            exit;
        if not Request.Get('batchName', ParameterToken) then
            Clear(ParameterToken);
        if not ReadCode(Argument, ParameterToken, 'batchName', BatchName) then
            exit;
        if (not JournalTemplate.Get(TemplateName)) or (not Batch.Get(TemplateName, BatchName)) then begin
            Refuse(Argument, 'BatchNotFound', StrSubstNo(BatchErr, TemplateName, BatchName), BatchFixLbl);
            exit;
        end;
        Line.ReadIsolation := IsolationLevel::ReadCommitted;
        Line.SetRange("Journal Template Name", TemplateName);
        Line.SetRange("Journal Batch Name", BatchName);
        if not Line.FindFirst() then begin
            Refuse(Argument, 'JournalNotReady', EmptyErr, CheckFixLbl);
            exit;
        end;
        Check.CheckAllJournalLinesWithErrorCollect(Line, TempErrors);
        if TempErrors.FindSet() then begin
            repeat
                Clear(Problem);
                ErrorLineNo := 0;
                if TempErrors."Record ID".TableNo() = Database::"Sustainability Jnl. Line" then begin
                    SourceRecord := TempErrors."Record ID".GetRecord();
                    ErrorLineNo := SourceRecord.Field(Line.FieldNo("Line No.")).Value();
                end;
                Problem.Add('lineNo', ErrorLineNo);
                TempErrors.CalcFields("Field Name");
                Problem.Add('fieldName', TempErrors."Field Name");
                Problem.Add('message', TempErrors."Message");
                Errors.Add(Problem);
            until TempErrors.Next() = 0;
            Refuse(Argument, 'JournalNotReady', NotReadyErr, CheckFixLbl);
            Response := Argument.GetResponseJson();
            Response.Add('journalErrors', Errors);
            Argument.SetResponseJson(Response);
            exit;
        end;
        Line.FindFirst();
        Instance.Initialize();
        BindSubscription(Runner);
        SustPreview.TryBindPostingPreviewHandler();
        Preview.SetContext(Runner, Line);
        ErrorMgt.Activate(ErrorHandler);
        ClearLastError();
        if Preview.Run() then
            Error(PostingErr);
        ErrorText := GetLastErrorText();
        PreviewSucceeded := Preview.IsSuccess();
        SustPreview.TryUnbindPostingPreviewHandler();
        UnbindSubscription(Runner);
        Runner.GetEntries(TempEntries, TempValues);
        Instance.Initialize();
        if not PreviewSucceeded then begin
            ErrorHandler.AppendTo(TempErrors);
            if ErrorText = '' then
                if TempErrors.FindFirst() then
                    ErrorText := TempErrors.Message;
            if ErrorText = '' then
                ErrorText := PostingErr;
            Refuse(Argument, 'BusinessCentralError', ErrorText, CheckFixLbl);
            exit;
        end;
        BuildResponse(TempEntries, TempValues, Response);
        Argument.SetResponseJson(Response);
    end;

    local procedure ReadCode(var Argument: Record "Message Argument ori"; Token: JsonToken; Name: Text; var Value: Code[10]): Boolean
    var
        Input: Text;
        Serialized: Text;
    begin
        if Token.IsValue() then
            if not Token.AsValue().IsNull() then begin
                Token.WriteTo(Serialized);
                if CopyStr(Serialized, 1, 1) = '"' then
                    Input := Token.AsValue().AsText();
            end;
        if (StrLen(Input) = 0) or (StrLen(Input) > MaxStrLen(Value)) then begin
            Refuse(Argument, 'InvalidParameter', StrSubstNo(ParameterErr, Name), ParameterFixLbl);
            exit(false);
        end;
        Value := CopyStr(Input, 1, MaxStrLen(Value));
        if Value = '' then begin
            Refuse(Argument, 'InvalidParameter', StrSubstNo(ParameterErr, Name), ParameterFixLbl);
            exit(false);
        end;
        exit(true);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; Code: Text; Message: Text; Fix: Text)
    var
        Response: JsonObject;
        Errors: JsonArray;
        Entry: JsonObject;
    begin
        Response.Add('status', 'Error');
        Response.Add('code', Code);
        Response.Add('error', Message);
        Response.Add('nextStep', Fix);
        Response.Add('rollback', true);
        Entry.Add('code', Code);
        Entry.Add('when', Message);
        Entry.Add('fix', Fix);
        Errors.Add(Entry);
        Response.Add('errors', Errors);
        Argument.SetResponseJson(Response);
    end;

    local procedure BuildResponse(var Entries: Record "Sustainability Ledger Entry" temporary; var Values: Record "Sustainability Value Entry" temporary; var Response: JsonObject)
    var
        Entry: JsonObject;
        Rows: JsonArray;
        ValueRows: JsonArray;
        Totals: JsonObject;
        CO2: Decimal;
        CH4: Decimal;
        N2O: Decimal;
        CO2e: Decimal;
        CarbonFee: Decimal;
        Water: Decimal;
        Waste: Decimal;
        Energy: Decimal;
    begin
        if Entries.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('postingDate', Format(Entries."Posting Date", 0, 9));
                Entry.Add('documentNo', Entries."Document No.");
                Entry.Add('accountNo', Entries."Account No.");
                Entry.Add('emissionScope', Entries."Emission Scope".Names().Get(Entries."Emission Scope".Ordinals().IndexOf(Entries."Emission Scope".AsInteger())));
                Entry.Add('CO2', Entries."Emission CO2");
                Entry.Add('CH4', Entries."Emission CH4");
                Entry.Add('N2O', Entries."Emission N2O");
                Entry.Add('CO2e', Entries."CO2e Emission");
                Entry.Add('carbonFee', Entries."Carbon Fee");
                Entry.Add('water', Entries."Water Intensity");
                Entry.Add('dischargedIntoWater', Entries."Discharged Into Water");
                Entry.Add('waste', Entries."Waste Intensity");
                Entry.Add('energy', Entries."Energy Consumption");
                Entry.Add('dimensionSetId', Entries."Dimension Set ID");
                Entry.Add('dimensions', Dimensions(Entries."Dimension Set ID"));
                Rows.Add(Entry);
                CO2 += Entries."Emission CO2";
                CH4 += Entries."Emission CH4";
                N2O += Entries."Emission N2O";
                CO2e += Entries."CO2e Emission";
                CarbonFee += Entries."Carbon Fee";
                Water += Entries."Water Intensity";
                Waste += Entries."Waste Intensity";
                Energy += Entries."Energy Consumption";
            until Entries.Next() = 0;
        if Values.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('postingDate', Format(Values."Posting Date", 0, 9));
                Entry.Add('documentNo', Values."Document No.");
                Entry.Add('accountNo', Values."Account No.");
                Entry.Add('CO2eActual', Values."CO2e Amount (Actual)");
                Entry.Add('CO2eExpected', Values."CO2e Amount (Expected)");
                Entry.Add('dimensionSetId', Values."Dimension Set ID");
                Entry.Add('dimensions', Dimensions(Values."Dimension Set ID"));
                ValueRows.Add(Entry);
            until Values.Next() = 0;
        Totals.Add('CO2', CO2);
        Totals.Add('CH4', CH4);
        Totals.Add('N2O', N2O);
        Totals.Add('CO2e', CO2e);
        Totals.Add('carbonFee', CarbonFee);
        Totals.Add('water', Water);
        Totals.Add('waste', Waste);
        Totals.Add('energy', Energy);
        Response.Add('status', 'Success');
        Response.Add('rollback', true);
        Response.Add('entries', Rows);
        Response.Add('valueEntries', ValueRows);
        Response.Add('entryCount', Rows.Count() + ValueRows.Count());
        Response.Add('totals', Totals);
    end;

    local procedure Dimensions(DimensionSetId: Integer) Result: JsonArray
    var
        Dimension: Record "Dimension Set Entry";
        Entry: JsonObject;
    begin
        Dimension.ReadIsolation := IsolationLevel::ReadCommitted;
        Dimension.SetRange("Dimension Set ID", DimensionSetId);
        Dimension.SetLoadFields("Dimension Code", "Dimension Value Code");
        if Dimension.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('code', Dimension."Dimension Code");
                Entry.Add('value', Dimension."Dimension Value Code");
                Result.Add(Entry);
            until Dimension.Next() = 0;
    end;

    /// <summary>Provides GetDescription for the public preview contract.</summary>
    procedure GetDescription() Description: Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides GetSelectionDescription for the public preview contract.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides GetKeywords for the public preview contract.</summary>
    procedure GetKeywords(): Text
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Provides GetFilterTableNo for the public preview contract.</summary>
    procedure GetFilterTableNo() FilterTableId: Integer
    begin
        exit(Database::"Sustainability Jnl. Batch");
    end;

    /// <summary>Provides GetMessageDirection for the public preview contract.</summary>
    procedure GetMessageDirection() MessageDirection: Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Provides GetEnvelope for the public preview contract.</summary>
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

    /// <summary>Provides GetParameters for the public preview contract.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        TemplateLbl: Label 'Existing sustainability journal template code, up to 10 characters.', Comment = 'is-IS=Fyrirliggjandi sniðmátskóði sjálfbærnibókar, allt að 10 stafir.';
        BatchLbl: Label 'Existing batch in that template, up to 10 characters.', Comment = 'is-IS=Fyrirliggjandi keyrsla í sniðmátinu, allt að 10 stafir.';
    begin
        Parameters.Add(ContractMgt.Parameter('templateName', 'string', true, TemplateLbl));
        Parameters.Add(ContractMgt.Parameter('batchName', 'string', true, BatchLbl));
        exit(true);
    end;

    /// <summary>Provides GetEffect for the public preview contract.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
        ChangesLbl: Label 'Posting runs in the standard preview transaction. Journal deletion, number-series updates and entries are rolled back. No Commit is called by this type; explicit commits inside preview are rejected.', Comment = 'is-IS=Bókun keyrir í staðlaðri forskoðunarfærslu. Eyðingu bókarlína, uppfærslu númeraraða og færslum er afturkallað. Tegundin kallar ekki á Commit; slík vistun innan forskoðunar er ekki leyfð.';
        PreconditionLbl: Label 'An existing journal batch whose lines pass the standard sustainability journal check.', Comment = 'is-IS=Fyrirliggjandi bókarkeyrsla með línum sem standast staðlaða athugun sjálfbærnibókar.';
    begin
        Effect.Add('effect', 'read');
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST SustRead ori');
        Preconditions.Add(PreconditionLbl);
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>Provides GetErrors for the public preview contract.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        AddError(Errors, 'BatchNotFound', BatchErr, BatchFixLbl);
        AddError(Errors, 'JournalNotReady', NotReadyErr, CheckFixLbl);
        AddError(Errors, 'BusinessCentralError', PostingErr, CheckFixLbl);
        AddError(Errors, 'PermissionDenied', PermissionErr, PermissionFixLbl);
        AddError(Errors, 'UnknownParameter', UnknownErr, ParameterFixLbl);
        AddError(Errors, 'InvalidParameter', ParameterErr, ParameterFixLbl);
        exit(true);
    end;

    local procedure AddError(var Errors: JsonArray; Code: Text; When: Text; Fix: Text)
    var
        Entry: JsonObject;
    begin
        Entry.Add('code', Code);
        Entry.Add('when', When);
        Entry.Add('fix', Fix);
        Errors.Add(Entry);
    end;

    /// <summary>Provides GetResponse for the public preview contract.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Fields: JsonArray;
        RollbackLbl: Label 'Always true. No posting changes are committed.', Comment = 'is-IS=Alltaf satt. Engar bókunarbreytingar eru vistaðar.';
        CountLbl: Label 'Count of captured ledger and value entries.', Comment = 'is-IS=Fjöldi sjálfbærni- og virðisfærslna í forskoðun.';
        EntriesLbl: Label 'Posting date, document, account, emission scope, CO2, CH4, N2O, CO2e, carbon fee, water, waste, energy and dimensions from the standard posting engine.', Comment = 'is-IS=Bókunardagur, skjal, reikningur, umfang losunar, CO2, CH4, N2O, CO2e, kolefnisgjald, vatn, úrgangur, orka og víddir frá staðlaðri bókun.';
        ValuesLbl: Label 'Value entries captured during preview; empty when the journal creates none.', Comment = 'is-IS=Virðisfærslur í forskoðun; tómt þegar bókin stofnar engar.';
        TotalsLbl: Label 'Sums of CO2, CH4, N2O, CO2e, carbonFee, water, waste and energy over the ledger entries.', Comment = 'is-IS=Samtölur CO2, CH4, N2O, CO2e, kolefnisgjalds, vatns, úrgangs og orku úr sjálfbærnifærslum.';
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success'));
        Fields.Add(ContractMgt.ResponseField('rollback', 'boolean', RollbackLbl));
        Fields.Add(ContractMgt.ResponseField('entryCount', 'integer', CountLbl));
        Fields.Add(ContractMgt.ResponseField('entries', 'array', EntriesLbl));
        Fields.Add(ContractMgt.ResponseField('valueEntries', 'array', ValuesLbl));
        Fields.Add(ContractMgt.ResponseField('totals', 'object', TotalsLbl));
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Provides GetExamples for the public preview contract.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        TitleLbl: Label 'Preview a demo journal', Comment = 'is-IS=Forskoða sýnibók';
    begin
        Examples.Add(ContractMgt.Example(TitleLbl,
            '{"type":"Sustainability.Journal.PreviewPost","data":{"templateName":"GENERAL","batchName":"DEFAULT"}}',
            '{"status":"Success","rollback":true,"entryCount":1,"entries":[{"postingDate":"2026-01-15","documentNo":"CRONUS-001","accountNo":"1000","CO2":10}],"valueEntries":[],"totals":{"CO2":10}}'));
        exit(true);
    end;

    /// <summary>Provides GetOverview for the public preview contract.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := DescriptionLbl;
        exit(true);
    end;

    /// <summary>Provides GetNotes for the public preview contract.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        NotesLbl: Label 'An empty batch is JournalNotReady. Unknown keys are refused. Hidden types remain callable when Sustainability is unconfigured. The preview never posts a ledger entry or consumes a journal line.', Comment = 'is-IS=Tóm keyrsla skilar JournalNotReady. Óþekktum lyklum er hafnað. Faldar tegundir eru áfram kallanlegar þegar sjálfbærni er óuppsett. Forskoðun bókar aldrei færslu né eyðir bókarlínu.';
    begin
        Notes := NotesLbl;
        exit(true);
    end;

    /// <summary>Provides GetTarget for the public preview contract.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides GetMetering for the public preview contract.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides GetRelated for the public preview contract.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides GetWorkflow for the public preview contract.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;
}
