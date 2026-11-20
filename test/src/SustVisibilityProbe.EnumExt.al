namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost;

/// <summary>
/// Test-only message type that uses the shared visibility check (#1, AC06), so the tests can prove
/// that a hidden Sustainability type is left out of the roster but still runs through Dispatcher ori.
/// It exists only while the test app is installed.
/// </summary>
enumextension 98004 "Sust Visibility Probe ori" extends "Message Type ori"
{
    value(98004; "Sustainability.Test.Visibility")
    {
        Caption = 'Sustainability.Test.Visibility', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Visibility Probe ori", "Msg Contract ori" = "Sust Visibility Probe ori";
    }
}
