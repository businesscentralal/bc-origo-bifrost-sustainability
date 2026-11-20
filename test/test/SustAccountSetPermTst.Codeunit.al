namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests the permission rule of Sustainability.Account.Set (#14 AC-P): only BIFROST SustFull ori grants the type.
/// A user with the Read role is refused through the public dispatcher, and the type is hidden for that user.
/// </summary>
codeunit 98026 "Sust Account Set Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        AccountSetTest: Codeunit "Sust Account Set Tst ori";

    [Test]
    procedure Scenario_ACP_ReadUser_IsRefusedAndTypeHidden()
    var
        SustainabilityAccount: Record "Sustainability Account";
        MessageInterface: Interface "Msg Interface ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
    begin
        // [GIVEN] A company with an account, and a user with Foundation's Read role and Microsoft's Sustainability Read set
        if SustainabilityAccount.IsEmpty() then begin
            SustainabilityAccount.Init();
            SustainabilityAccount."No." := 'TSTPERM';
            SustainabilityAccount.Insert();
        end;
        LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');

        // [WHEN] The user asks for the type and calls it
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Account.Set";
        Assert.IsFalse(MessageInterface.IsEnabled(), 'The type must be hidden for a Read user.');
        Request.Add('no', 'TSTPERM2');
        Request.Add('name', 'Not allowed');
        Response := AccountSetTest.Invoke(Request, '', 1033);

        // [THEN] The call is refused with PermissionDenied
        Response.Get('code', Token);
        Assert.AreEqual('PermissionDenied', Token.AsValue().AsText(), 'A Read user must be refused.');
    end;

    [Test]
    procedure Scenario_ACP_FullUser_SeesType()
    var
        SustainabilityAccount: Record "Sustainability Account";
        MessageInterface: Interface "Msg Interface ori";
    begin
        // [GIVEN] A company with an account, and a user with Foundation's Full role and Microsoft's Sustainability Read set
        if SustainabilityAccount.IsEmpty() then begin
            SustainabilityAccount.Init();
            SustainabilityAccount."No." := 'TSTPERM';
            SustainabilityAccount.Insert();
        end;
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');

        // [WHEN] Foundation asks the type whether it is enabled
        MessageInterface := Enum::"Message Type ori"::"Sustainability.Account.Set";

        // [THEN] It is visible through the Full grant
        Assert.IsTrue(MessageInterface.IsEnabled(), 'The Full role must make the type visible.');
    end;
}
