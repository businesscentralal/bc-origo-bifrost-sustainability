namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost;
using Origo.Bifrost.Sustainability;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Proves Sustainability.Scorecard.Get is hidden and refused without read permission.
/// </summary>
codeunit 98021 "Sust Scorecard Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>A caller who can run the codeunit but cannot read the tables is hidden and gets PermissionDenied.</summary>
    [Test]
    procedure WithoutReadPermission_IsHiddenAndRefused()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Impl: Codeunit "Sust Scorecard Get Impl ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [GIVEN] Execute permission only, with no read permission on scorecards, goals or ledger entries.
        // The AL test host used here does not start permission mocking, so this test starts it.
        PermissionsMock.Start();
        LowerPermissions.SetExactPermissionSet('Sust Sc Exec ori');
        RequestJson.Add('scorecardNo', 'SC-CRONUS');
        TempArgument.Init();
        TempArgument."Version" := Enum::"Message Version ori"::"1.0";
        TempArgument.Insert(true);
        TempArgument.SetRequestJson(RequestJson);

        // [WHEN] The catalogue asks whether the type is enabled, and the type is run
        // [THEN] It is hidden, and the call is PermissionDenied without reading a scorecard
        Assert.IsFalse(Impl.IsEnabled(), 'The type must be hidden without read permission.');
        Impl.ExecuteBifrostTask(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('code', Token), 'The refusal must carry a code.');
        Assert.AreEqual('PermissionDenied', Token.AsValue().AsText(), 'code');
        Assert.IsTrue(ResponseJson.Get('status', Token), 'status');
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'status');
    end;
}
