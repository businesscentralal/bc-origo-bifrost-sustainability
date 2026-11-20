namespace Origo.Bifrost.Sustainability;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Posting;
using System.Automation;

/// <summary>Runs the standard sustainability posting engine inside Microsoft's preview rollback boundary.</summary>
codeunit 70009227 "Sust Preview Runner ori"
{
    Access = Internal;
    TableNo = "Sustainability Jnl. Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        Preview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        // A direct invocation must never become a real post.
        if (not Preview.IsActive()) or (not Rec.IsTemporary()) then
            Error(PreviewRequiredErr);
        Codeunit.Run(Codeunit::"Sustainability Jnl.-Post", Rec);
        Preview.ThrowError();
    end;

    var
        TempEntries: Record "Sustainability Ledger Entry" temporary;
        TempValues: Record "Sustainability Value Entry" temporary;
        PreviewRequiredErr: Label 'This operation requires an active posting preview.', Comment = 'is-IS=Þessi aðgerð krefst virkrar forskoðunar bókunar.';

    /// <summary>Returns copied temporary entries; none of these records was committed.</summary>
    procedure GetEntries(var Entries: Record "Sustainability Ledger Entry" temporary; var Values: Record "Sustainability Value Entry" temporary)
    begin
        Entries.Copy(TempEntries, true);
        Values.Copy(TempValues, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure RunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        TempLine: Record "Sustainability Jnl. Line" temporary;
        Runner: Codeunit "Sust Preview Runner ori";
    begin
        Runner := Subscriber;
        TempLine.Copy(RecVar, true);
        Result := Runner.Run(TempLine);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Sustainability Jnl. Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure FinishBeforeDeleting(var Rec: Record "Sustainability Jnl. Line"; RunTrigger: Boolean)
    var
        Batch: Record "Sustainability Jnl. Batch";
        Preview: Codeunit "Gen. Jnl.-Post Preview";
        Approvals: Codeunit "Approvals Mgmt.";
    begin
        if not Rec.IsTemporary() then
            exit;
        if not Preview.IsActive() then
            Error(PreviewRequiredErr);
        // Posting has processed every line and saved its simulated number-series state.
        // Preserve the standard last-line deletion approval check, then roll back before
        // the table trigger would delete persistent collected-G/L links or display completion UI.
        Batch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        Approvals.PreventDeletingRecordWithOpenApprovalEntry(Batch);
        Preview.ThrowError();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sustainability Jnl.-Post", 'OnBeforeConfirmDialog', '', false, false)]
    local procedure SuppressConfirmation(var ShowConfirmDialog: Boolean)
    begin
        ShowConfirmDialog := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sustainability Post Mgt", 'OnBeforeInsertSustainabilityLedgerEntry', '', false, false)]
    local procedure CaptureEntry(var SustainabilityLedgerEntry: Record "Sustainability Ledger Entry"; SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    begin
        // Microsoft captures this prepared entry immediately afterwards through its internal preview event.
        TempEntries := SustainabilityLedgerEntry;
        TempEntries."Entry No." := TempEntries.Count() + 1;
        TempEntries.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sustainability Value Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure CaptureValue(var Rec: Record "Sustainability Value Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        TempValues := Rec;
        TempValues.Insert();
    end;
}
