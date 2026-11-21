namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Tests the permission rule of Sustainability.Account.Set (#14 AC-P): the Sustainability and Foundation Full roles grant the type.
/// A user with the Read role is refused through the public dispatcher, and the type is hidden for that user.
/// </summary>
codeunit 98026 "Sust Account Set Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        PermissionsMock: Codeunit "Permissions Mock";

    /// <summary>Checks Read visibility and refusal with the PR #18 Read permission setup before asserting.</summary>
    [Test]
    procedure Scenario_ACP_ReadUser_IsRefusedAndTypeHidden()
    var
        SustainabilityAccount: Record "Sustainability Account";
        Setup: Record "Setup ori";
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        MessageInterface: Interface "Msg Interface ori";
        IsEnabled: Boolean;
        RequestText: Text;
        ResponseText: Text;
        ResponseCode: Text;
        Line: Text;
        ResponseContentType: Text[100];
        MessageId: Guid;
        EmptyTaskId: Guid;
        ResponseTime: Duration;
        ResponseStream: InStream;
        SavedLanguage: Integer;
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
    begin
        // [GIVEN] A company with an account, and a user with Foundation Read plus BIFROST SustRead ori (the PR #18 setup)
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
        LowerPermissions.SetOutsideO365Scope();
        Setup.InsertIfNotExists();
        if SustainabilityAccount.IsEmpty() then begin
            SustainabilityAccount.Init();
            SustainabilityAccount."No." := 'TSTPERM';
            SustainabilityAccount.Insert();
        end;
        Request.Add('no', 'TSTPERM2');
        Request.Add('name', 'Not allowed');
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('BIFROST SustRead ori');
        LowerPermissions.AddPermissionSet('Sust Setup Test ori');

        // [WHEN] The user asks for the type and calls it through the public dispatcher
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Account.Set";
        IsEnabled := MessageInterface.IsEnabled();
        SavedLanguage := GlobalLanguage();
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Account.Set", Enum::"Message Version ori"::"1.0", '', 'XSUST', 'application/json',
            RequestContent, EmptyTaskId, 1033, MessageId, ResponseTempBlob, ResponseContentType, ResponseTime, true);
        GlobalLanguage(SavedLanguage);
        LowerPermissions.SetOutsideO365Scope();
        ResponseTempBlob.CreateInStream(ResponseStream, TextEncoding::UTF8);
        while not ResponseStream.EOS() do begin
            ResponseStream.ReadText(Line);
            ResponseText += Line;
        end;
        if Response.ReadFrom(ResponseText) then
            if Response.Get('code', Token) then
                ResponseCode := Token.AsValue().AsText();

        // [THEN] The type is hidden and the call is refused with PermissionDenied
        Assert.IsFalse(IsEnabled, 'The type must be hidden for a Read user.');
        Assert.AreEqual('PermissionDenied', ResponseCode, 'A Read user must be refused: ' + ResponseText);
        SustainabilityAccount.SetRange("No.", 'TSTPERM2');
        Assert.IsTrue(SustainabilityAccount.IsEmpty(), 'A refused call must not create the account.');
    end;

    /// <summary>Checks Full visibility under restricted permissions before asserting.</summary>
    [Test]
    procedure Scenario_ACP_FullUser_SeesType()
    var
        SustainabilityAccount: Record "Sustainability Account";
        MessageInterface: Interface "Msg Interface ori";
        IsEnabled: Boolean;
    begin
        // [GIVEN] A company with an account, and a user with Foundation's Full role and Microsoft's Sustainability Read set
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
        if SustainabilityAccount.IsEmpty() then begin
            SustainabilityAccount.Init();
            SustainabilityAccount."No." := 'TSTPERM';
            SustainabilityAccount.Insert();
        end;
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');

        // [WHEN] Foundation asks the type whether it is enabled
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Account.Set";
        IsEnabled := MessageInterface.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();

        // [THEN] It is visible through the Full grant
        Assert.IsTrue(IsEnabled, 'The Full role must make the type visible.');
    end;
}
