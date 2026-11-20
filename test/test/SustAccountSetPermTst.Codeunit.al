namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

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

    /// <summary>Checks Read visibility and refusal under restricted permissions before asserting.</summary>
    [Test]
    procedure Scenario_ACP_ReadUser_IsRefusedAndTypeHidden()
    var
        SustainabilityAccount: Record "Sustainability Account";
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        MessageInterface: Interface "Msg Interface ori";
        IsEnabled: Boolean;
        RequestText: Text;
        ResponseText: Text;
        ResponseCode: Text;
        ResponseContentType: Text[100];
        MessageId: Guid;
        EmptyTaskId: Guid;
        ResponseTime: Duration;
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
    begin
        // [GIVEN] A company with an account, and a user with Foundation's Read role and Microsoft's Sustainability Read set
        Assert.IsTrue(PermissionsMock.IsStarted(), 'The test runner must enable permission mocking.');
        if SustainabilityAccount.IsEmpty() then begin
            SustainabilityAccount.Init();
            SustainabilityAccount."No." := 'TSTPERM';
            SustainabilityAccount.Insert();
        end;
        LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');

        // [WHEN] The user asks for the type and calls it
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Account.Set";
        IsEnabled := MessageInterface.IsEnabled();
        Request.Add('no', 'TSTPERM2');
        Request.Add('name', 'Not allowed');
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(Enum::"Message Type ori"::"Sustainability.Account.Set", Enum::"Message Version ori"::"1.0", '', 'XSUST', 'application/json',
            RequestContent, EmptyTaskId, 1033, MessageId, ResponseContent, ResponseContentType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);

        Response.Get('code', Token);
        ResponseCode := Token.AsValue().AsText();
        LowerPermissions.SetOutsideO365Scope();

        // [THEN] The type is hidden and the call is refused with PermissionDenied
        Assert.IsFalse(IsEnabled, 'The type must be hidden for a Read user.');
        Assert.AreEqual('PermissionDenied', ResponseCode, 'A Read user must be refused.');
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
