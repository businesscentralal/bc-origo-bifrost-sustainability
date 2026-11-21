namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>
/// Registers Sustainability.Scorecard.Get on Foundation's message type enum.
/// </summary>
enumextension 70009209 "Sust Scorecard Msg ori" extends "Message Type ori"
{
    /// <summary>Reads a sustainability scorecard with its goals, values and progress.</summary>
    value(70009209; "Sustainability.Scorecard.Get")
    {
        Caption = 'Sustainability.Scorecard.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Scorecard Get Impl ori",
                      "Msg Discovery ori" = "Sust Scorecard Get Impl ori",
                      "Msg Contract ori" = "Sust Scorecard Get Impl ori";
    }
}
