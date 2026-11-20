namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Hidden means roster-only (#1, AC06). With Sustainability not set up, the test-only type
/// Sustainability.Test.Visibility is left out of Help.MessageTypes.Get with onlyEnabled, yet a caller that
/// knows the type still runs it through Dispatcher ori. Once the company is set up the type is listed.
/// Each case runs in English (1033) and Icelandic (1039).
/// </summary>
codeunit 98005 "Sust Roster Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ProbeTok: Label 'Sustainability.Test.Visibility', Locked = true;

    [Test]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario_AC06_HiddenTypeLeftOutButRuns_English()
    begin
        VerifyHiddenTypeLeftOutButRuns(1033);
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario_AC06_HiddenTypeLeftOutButRuns_Icelandic()
    begin
        VerifyHiddenTypeLeftOutButRuns(1039);
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario_AC06_ConfiguredTypeListed_English()
    begin
        VerifyConfiguredTypeListed(1033);
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure Scenario_AC06_ConfiguredTypeListed_Icelandic()
    begin
        VerifyConfiguredTypeListed(1039);
    end;

    local procedure VerifyHiddenTypeLeftOutButRuns(LanguageId: Integer)
    var
        GroupResolver: Codeunit "Group Resolver ori";
        RosterText: Text;
        RunText: Text;
    begin
        // [GIVEN] Sustainability is not set up: blank setup row and no accounts
        SetUp(false);

        // [WHEN] The roster of usable types is read, and the hidden type is called directly
        RosterText := Dispatch(Enum::"Message Type ori"::"Help.MessageTypes.Get", '{"onlyEnabled":true}', LanguageId);
        RunText := Dispatch(Enum::"Message Type ori"::"Sustainability.Test.Visibility", '{}', LanguageId);

        // [THEN] The type is not enabled and not in the roster, but the direct call runs it
        Assert.IsFalse(GroupResolver.IsMessageTypeEnabled(Enum::"Message Type ori"::"Sustainability.Test.Visibility"), 'An unconfigured company must hide the type.');
        Assert.AreNotEqual(0, StrPos(RosterText, '"Success"'), 'The roster call must succeed: ' + CopyStr(RosterText, 1, 500));
        Assert.AreEqual(0, StrPos(RosterText, ProbeTok), 'A hidden type must be left out of the roster.');
        Assert.AreNotEqual(0, StrPos(RunText, '"Success"'), 'A hidden type must still run when called: ' + CopyStr(RunText, 1, 500));
        Assert.AreNotEqual(0, StrPos(RunText, '"probe":"' + ProbeTok + '"'), 'The direct call must reach the type itself: ' + CopyStr(RunText, 1, 500));
    end;

    local procedure VerifyConfiguredTypeListed(LanguageId: Integer)
    var
        GroupResolver: Codeunit "Group Resolver ori";
        RosterText: Text;
    begin
        // [GIVEN] Sustainability is set up with an Emission Unit of Measure Code
        SetUp(true);

        // [WHEN] The roster of usable types is read
        RosterText := Dispatch(Enum::"Message Type ori"::"Help.MessageTypes.Get", '{"onlyEnabled":true}', LanguageId);

        // [THEN] The type is enabled and listed
        Assert.IsTrue(GroupResolver.IsMessageTypeEnabled(Enum::"Message Type ori"::"Sustainability.Test.Visibility"), 'A configured company must show the type.');
        Assert.AreNotEqual(0, StrPos(RosterText, ProbeTok), 'A visible type must be in the roster.');
    end;

    local procedure SetUp(WithUnit: Boolean)
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
    begin
        SustainabilityAccount.DeleteAll(false);
        if not SustainabilitySetup.Get() then begin
            SustainabilitySetup.Init();
            SustainabilitySetup.Insert(false);
        end;
        if WithUnit then
            SustainabilitySetup."Emission Unit of Measure Code" := 'KG'
        else
            SustainabilitySetup."Emission Unit of Measure Code" := '';
        SustainabilitySetup.Modify(false);
    end;

    local procedure Dispatch(MessageType: Enum "Message Type ori"; RequestText: Text; LanguageId: Integer) ResponseText: Text
    var
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        ResponseContentType: Text[100];
        MessageId: Guid;
        EmptyTaskId: Guid;
        ResponseTime: Duration;
        ResponseStream: InStream;
        Line: Text;
        SavedLanguage: Integer;
    begin
        SavedLanguage := GlobalLanguage();
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(MessageType, Enum::"Message Version ori"::"1.0", '', 'XSUST', 'application/json',
            RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseTempBlob, ResponseContentType, ResponseTime, true);
        GlobalLanguage(SavedLanguage);
        ResponseTempBlob.CreateInStream(ResponseStream, TextEncoding::UTF8);
        while not ResponseStream.EOS() do begin
            ResponseStream.ReadText(Line);
            ResponseText += Line;
        end;
    end;
}
