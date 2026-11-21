namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.Utilities;

/// <summary>Checks a sustainability journal and rolls back all changes from validation.</summary>
codeunit 70009214 "Sust Journal Check Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    trigger OnRun()
    begin
        CheckBatch(Rec);
    end;

    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        DescriptionLbl: Label 'Check every line in a sustainability journal batch and return its validation errors without changing or posting data.', MaxLength = 250, Comment = 'is-IS=Athuga allar línur í keyrslu sjálfbærnibókar og skila villum án þess að breyta eða bóka gögn.';
        KeywordsLbl: Label 'check sustainability journal, validate emission lines, journal errors', Comment = 'is-IS=athuga sjálfbærnibók, sannreyna losunarlínur, villur í bók';
        BatchErr: Label 'Sustainability journal batch %1/%2 does not exist.', Comment = '%1 = template, %2 = batch||is-IS=Keyrsla sjálfbærnibókar %1/%2 er ekki til.';
        BatchFixLbl: Label 'Choose an existing sustainability journal template and batch.', Comment = 'is-IS=Veldu fyrirliggjandi sniðmát og keyrslu sjálfbærnibókar.';
        PermissionErr: Label 'You do not have permission to check sustainability journals.', Comment = 'is-IS=Þú hefur ekki heimild til að athuga sjálfbærnibækur.';
        PermissionFixLbl: Label 'Ask an administrator for BIFROST SustRead ori and the required Business Central permissions.', Comment = 'is-IS=Biðjið kerfisstjóra um BIFROST SustRead ori og nauðsynlegar Business Central heimildir.';
        UnknownErr: Label 'Unknown request parameter: %1.', Comment = '%1 = parameter||is-IS=Óþekkt færibreyta beiðni: %1.';
        ParameterErr: Label 'Parameter %1 must be a non-empty string of at most 10 characters.', Comment = '%1 = parameter||is-IS=Færibreytan %1 verður að vera texti með 1 til 10 stöfum.';
        ParameterFixLbl: Label 'Supply only templateName and batchName, using existing journal codes.', Comment = 'is-IS=Tilgreindu aðeins templateName og batchName með fyrirliggjandi bókarkóðum.';
        CheckErr: Label 'Business Central could not complete the journal check.', Comment = 'is-IS=Business Central gat ekki lokið athugun bókarinnar.';
        CheckFixLbl: Label 'Correct the reported journal errors and run the check again.', Comment = 'is-IS=Leiðréttu villurnar í bókinni og keyrðu athugunina aftur.';
        EmptyErr: Label 'The sustainability journal batch has no lines.', Comment = 'is-IS=Keyrsla sjálfbærnibókar hefur engar línur.';

    /// <summary>Executes the public message contract and converts validation failures to a response.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        if not HasPermission() then begin
            Refuse(Argument, 'PermissionDenied', PermissionErr, PermissionFixLbl);
            exit;
        end;
        Argument.AssertIsLicensed();
        CheckBatch(Argument);
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
        Capability: Record "Sust Journal Check Access ori";
        JournalTemplate: Record "Sustainability Jnl. Template";
        Batch: Record "Sustainability Jnl. Batch";
        Line: Record "Sustainability Jnl. Line";
        Account: Record "Sustainability Account";
        Category: Record "Sustain. Account Category";
        Subcategory: Record "Sustain. Account Subcategory";
        Setup: Record "Sustainability Setup";
    begin
        exit(Capability.ReadPermission() and JournalTemplate.ReadPermission() and Batch.ReadPermission() and Line.ReadPermission() and Account.ReadPermission() and Category.ReadPermission() and Subcategory.ReadPermission() and Setup.ReadPermission());
    end;

    local procedure CheckBatch(var Argument: Record "Message Argument ori")
    var
        JournalTemplate: Record "Sustainability Jnl. Template";
        Batch: Record "Sustainability Jnl. Batch";
        TempErrors: Record "Error Message" temporary;
        Line: Record "Sustainability Jnl. Line";
        Runner: Codeunit "Sust Journal Check Runner ori";
        SourceRecord: RecordRef;
        Request: JsonObject;
        Response: JsonObject;
        Errors: JsonArray;
        Problem: JsonObject;
        ParameterToken: JsonToken;
        TemplateName: Code[10];
        BatchName: Code[10];
        KeyName: Text;
        LineCount: Integer;
        LineNo: Integer;
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
            Refuse(Argument, 'RecordNotFound', StrSubstNo(BatchErr, TemplateName, BatchName), BatchFixLbl);
            Response := Argument.GetResponseJson();
            Response.Add('received', TemplateName + '/' + BatchName);
            Response.Add('expected', BatchFixLbl);
            Argument.SetResponseJson(Response);
            exit;
        end;
        Runner.Initialize(TemplateName, BatchName);
        ClearLastError();
        if Runner.Run() then
            Error(CheckErr);
        if not Runner.GetResult(TempErrors, LineCount) then begin
            Refuse(Argument, 'BusinessCentralError', GetLastErrorText(), CheckFixLbl);
            exit;
        end;
        ClearLastError();
        if TempErrors.FindSet() then
            repeat
                Clear(Problem);
                LineNo := 0;
                if TempErrors."Context Record ID".TableNo() = Database::"Sustainability Jnl. Line" then
                    SourceRecord := TempErrors."Context Record ID".GetRecord()
                else
                    if TempErrors."Record ID".TableNo() = Database::"Sustainability Jnl. Line" then
                        SourceRecord := TempErrors."Record ID".GetRecord();
                if SourceRecord.Number() = Database::"Sustainability Jnl. Line" then
                    LineNo := SourceRecord.Field(Line.FieldNo("Line No.")).Value();
                Problem.Add('lineNo', LineNo);
                TempErrors.CalcFields("Context Field Name", "Field Name");
                if TempErrors."Context Field Name" <> '' then
                    Problem.Add('fieldName', TempErrors."Context Field Name")
                else
                    Problem.Add('fieldName', TempErrors."Field Name");
                Clear(SourceRecord);
                Problem.Add('message', TempErrors.Message);
                Errors.Add(Problem);
            until TempErrors.Next() = 0;
        if LineCount = 0 then begin
            Problem.Add('lineNo', 0);
            Problem.Add('fieldName', '');
            Problem.Add('message', EmptyErr);
            Errors.Add(Problem);
        end;
        Response.Add('status', 'Success');
        Response.Add('ready', Errors.Count() = 0);
        Response.Add('lineCount', LineCount);
        Response.Add('journalErrors', Errors);
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
        Entry.Add('code', Code);
        Entry.Add('when', Message);
        Entry.Add('fix', Fix);
        Errors.Add(Entry);
        Response.Add('errors', Errors);
        Argument.SetResponseJson(Response);
    end;

    /// <summary>Provides GetDescription for the public journal check contract.</summary>
    procedure GetDescription() Description: Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides GetSelectionDescription for the public journal check contract.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides GetKeywords for the public journal check contract.</summary>
    procedure GetKeywords(): Text
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Provides GetFilterTableNo for the public journal check contract.</summary>
    procedure GetFilterTableNo() FilterTableId: Integer
    begin
        exit(Database::"Sustainability Jnl. Batch");
    end;

    /// <summary>Provides GetMessageDirection for the public journal check contract.</summary>
    procedure GetMessageDirection() MessageDirection: Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Provides GetEnvelope for the public journal check contract.</summary>
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

    /// <summary>Provides GetParameters for the public journal check contract.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        TemplateLbl: Label 'Existing sustainability journal template code, up to 10 characters.', Comment = 'is-IS=Fyrirliggjandi sniðmátskóði sjálfbærnibókar, allt að 10 stafir.';
        BatchLbl: Label 'Existing batch in that template, up to 10 characters.', Comment = 'is-IS=Fyrirliggjandi keyrsla í sniðmátinu, allt að 10 stafir.';
    begin
        Parameters.Add(ContractMgt.Parameter('templateName', 'string', true, TemplateLbl));
        Parameters.Add(ContractMgt.Parameter('batchName', 'string', true, BatchLbl));
        exit(true);
    end;

    /// <summary>Provides GetEffect for the public journal check contract.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
        ChangesLbl: Label 'Runs the standard journal check in a rollback transaction. No Commit is called; explicit commits are rejected. Journal lines and ledger entries are unchanged, including on errors.', Comment = 'is-IS=Keyrir staðlaða bókarathugun í afturkallaðri færslu. Ekki er kallað á Commit og bein vistun er bönnuð. Bókarlínur og færslur haldast óbreyttar, einnig við villur.';
        PreconditionLbl: Label 'An existing sustainability journal template and batch.', Comment = 'is-IS=Fyrirliggjandi sniðmát og keyrsla sjálfbærnibókar.';
    begin
        Effect.Add('effect', 'read');
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST SustRead ori');
        Preconditions.Add(PreconditionLbl);
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>Provides GetErrors for the public journal check contract.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        AddError(Errors, 'RecordNotFound', BatchErr, BatchFixLbl);
        AddError(Errors, 'BusinessCentralError', CheckErr, CheckFixLbl);
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

    /// <summary>Describes the batch readiness and collected line errors.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Fields: JsonArray;
        ReadyLbl: Label 'True only when the batch contains lines and the standard check finds no errors.', Comment = 'is-IS=Satt aðeins þegar keyrslan hefur línur og staðlaða athugunin finnur engar villur.';
        CountLbl: Label 'Number of lines checked in this batch.', Comment = 'is-IS=Fjöldi lína sem voru athugaðar í keyrslunni.';
        ErrorsLbl: Label 'Collected errors with lineNo, fieldName and message. An empty batch has one message with lineNo 0.', Comment = 'is-IS=Safnaðar villur með lineNo, fieldName og message. Tóm keyrsla hefur ein skilaboð með lineNo 0.';
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success'));
        Fields.Add(ContractMgt.ResponseField('ready', 'boolean', ReadyLbl));
        Fields.Add(ContractMgt.ResponseField('lineCount', 'integer', CountLbl));
        Fields.Add(ContractMgt.ResponseField('journalErrors', 'array', ErrorsLbl));
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Provides GetExamples for the public journal check contract.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        TitleLbl: Label 'Check a demo journal', Comment = 'is-IS=Athuga sýnibók';
    begin
        Examples.Add(ContractMgt.Example(TitleLbl,
            '{"type":"Sustainability.Journal.Check","data":{"templateName":"GENERAL","batchName":"DEFAULT"}}',
            '{"status":"Success","ready":true,"lineCount":1,"journalErrors":[]}'));
        exit(true);
    end;

    /// <summary>Provides GetOverview for the public journal check contract.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := DescriptionLbl;
        exit(true);
    end;

    /// <summary>Provides GetNotes for the public journal check contract.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        NotesLbl: Label 'Empty and invalid batches return Success with ready false and journalErrors. Unknown batches return RecordNotFound (BatchNotFound). Unknown keys are refused. Unconfigured types are hidden but remain callable.', Comment = 'is-IS=Tómar og ógildar keyrslur skila Success með ready false og journalErrors. Óþekktar keyrslur skila RecordNotFound (BatchNotFound). Óþekktum lyklum er hafnað. Óuppsettar tegundir eru faldar en áfram kallanlegar.';
    begin
        Notes := NotesLbl;
        exit(true);
    end;

    /// <summary>Provides GetTarget for the public journal check contract.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides GetMetering for the public journal check contract.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides GetRelated for the public journal check contract.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides GetWorkflow for the public journal check contract.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;
}
