namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Self-contained journal fixtures and public-dispatcher calls for issue 7.</summary>
codeunit 98042 "Sust Jnl Create Fixture ori"
{
    var
        Assert: Codeunit "Library Assert";

    /// <summary>Creates isolated X-prefixed demo setup, accounts, a template and a batch.</summary>
    procedure Initialize()
    var
        JournalLine: Record "Sustainability Jnl. Line";
        Batch: Record "Sustainability Jnl. Batch";
        JournalTemplate: Record "Sustainability Jnl. Template";
        Account: Record "Sustainability Account";
        Category: Record "Sustain. Account Category";
        Subcategory: Record "Sustain. Account Subcategory";
        Setup: Record "Sustainability Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        JournalLine.SetRange("Journal Template Name", 'XJ7');
        JournalLine.DeleteAll();
        Batch.SetRange("Journal Template Name", 'XJ7');
        Batch.DeleteAll();
        if not JournalTemplate.Get('XJ7') then begin
            JournalTemplate.Name := 'XJ7';
            JournalTemplate.Insert();
        end;
        if not Setup.Get() then
            Setup.Insert();
        if not Category.Get('XJ7') then begin
            Category.Code := 'XJ7';
            Category.Insert();
        end;
        Category."Emission Scope" := Category."Emission Scope"::"Scope 1";
        Category."Calculation Foundation" := Category."Calculation Foundation"::"Fuel/Electricity";
        Category.CO2 := true;
        Category.CH4 := true;
        Category.N2O := true;
        Category.Modify();
        if not Subcategory.Get('XJ7', 'XJ7') then begin
            Subcategory."Category Code" := 'XJ7';
            Subcategory.Code := 'XJ7';
            Subcategory.Insert();
        end;
        Subcategory."Emission Factor CO2" := 2;
        Subcategory."Emission Factor CH4" := 3;
        Subcategory."Emission Factor N2O" := 4;
        Subcategory.Modify();
        if not Account.Get('XJ7') then begin
            Account."No." := 'XJ7';
            Account.Insert();
        end;
        Account.Name := 'X Journal test';
        Account.Category := 'XJ7';
        Account.Subcategory := 'XJ7';
        Account.Blocked := false;
        Account."Direct Posting" := true;
        Account."Account Type" := Account."Account Type"::Posting;
        Account.Modify();
        if not NoSeries.Get('XJ7') then begin
            NoSeries.Code := 'XJ7';
            NoSeries."Default Nos." := true;
            NoSeries.Insert();
        end;
        NoSeriesLine.SetRange("Series Code", 'XJ7');
        NoSeriesLine.DeleteAll();
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := 'XJ7';
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := 'X00001';
        NoSeriesLine."Ending No." := 'X99999';
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Open := true;
        NoSeriesLine.Insert();
        Batch.Init();
        Batch."Journal Template Name" := 'XJ7';
        Batch.Name := 'XJ7';
        Batch."No Series" := 'XJ7';
        Batch.Insert();
        Commit();
    end;

    /// <summary>Builds a valid request with one manual-emission line.</summary>
    procedure Request() RequestJson: JsonObject
    var
        Lines: JsonArray;
    begin
        Lines.Add(Line());
        RequestJson.Add('templateName', 'XJ7');
        RequestJson.Add('batchName', 'XJ7');
        RequestJson.Add('lines', Lines);
    end;

    /// <summary>Builds an independent valid line.</summary>
    procedure Line() LineJson: JsonObject
    begin
        LineJson.Add('postingDate', '2026-01-15');
        LineJson.Add('documentNo', 'XJ7-001');
        LineJson.Add('accountNo', 'XJ7');
        LineJson.Add('emissionCO2', 10);
        LineJson.Add('emissionCH4', 2);
        LineJson.Add('emissionN2O', 3);
    end;

    /// <summary>Runs the real transaction and language path through Foundation's public dispatcher.</summary>
    procedure Invoke(RequestJson: JsonObject; LanguageId: Integer) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        RequestText: Text;
        ResponseText: Text;
        ContentType: Text[100];
        MessageId: Guid;
        EmptyTaskId: Guid;
        ResponseTime: Duration;
    begin
        RequestJson.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Commit();
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Journal.Create", Enum::"Message Version ori"::"1.0", '', 'XJ7', 'application/json',
            RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseContent, ContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The dispatcher must return JSON: ' + ResponseText);
    end;

    /// <summary>Asserts an exact response string property.</summary>
    procedure AssertText(Response: JsonObject; PropertyName: Text; Expected: Text)
    var
        Token: JsonToken;
        ResponseText: Text;
    begin
        Response.WriteTo(ResponseText);
        Assert.IsTrue(Response.Get(PropertyName, Token), ResponseText);
        Assert.AreEqual(Expected, Token.AsValue().AsText(), ResponseText);
    end;

    /// <summary>Asserts no fixture lines survived a refusal.</summary>
    procedure AssertNoLines()
    var
        JournalLine: Record "Sustainability Jnl. Line";
    begin
        JournalLine.SetRange("Journal Template Name", 'XJ7');
        Assert.IsTrue(JournalLine.IsEmpty(), 'A refused request must retain no journal lines.');
    end;
}
