namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Posting;
using System.Utilities;

/// <summary>Collects standard validation errors in memory and always rolls back the validation transaction.</summary>
codeunit 70009228 "Sust Journal Check Runner ori"
{
    Access = Internal;

    trigger OnRun()
    begin
        CheckAndRollback();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure CheckAndRollback()
    var
        Line: Record "Sustainability Jnl. Line";
        Check: Codeunit "Sustainability Jnl.-Check";
    begin
        Line.SetRange("Journal Template Name", TemplateName);
        Line.SetRange("Journal Batch Name", BatchName);
        LineCount := Line.Count();
        Check.CheckAllJournalLinesWithErrorCollect(Line, TempErrors);
        Completed := true;
        Error('');
    end;

    var
        TempErrors: Record "Error Message" temporary;
        TemplateName: Code[10];
        BatchName: Code[10];
        LineCount: Integer;
        Completed: Boolean;

    /// <summary>Sets the batch to check and clears any prior result.</summary>
    procedure Initialize(NewTemplateName: Code[10]; NewBatchName: Code[10])
    begin
        TemplateName := NewTemplateName;
        BatchName := NewBatchName;
        TempErrors.Reset();
        TempErrors.DeleteAll();
        LineCount := 0;
        Completed := false;
    end;

    /// <summary>Returns the in-memory result after rollback; false means an unexpected validation failure.</summary>
    procedure GetResult(var Errors: Record "Error Message" temporary; var Count: Integer): Boolean
    begin
        Errors.Copy(TempErrors, true);
        Count := LineCount;
        exit(Completed);
    end;
}
