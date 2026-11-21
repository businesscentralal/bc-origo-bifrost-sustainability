namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Posting;

/// <summary>Proves the journal check rolls back side effects of standard validation subscribers.</summary>
codeunit 98047 "Sust Check Mutation Tst ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sustainability Jnl.-Check", 'OnAfterCheckSustainabilityJournalLine', '', false, false)]
    local procedure MutateLine(SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    begin
        SustainabilityJnlLine.Description := 'XROLLBACK';
        SustainabilityJnlLine.Modify();
    end;
}
