namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers the emission summary read with Bifrost Foundation.</summary>
enumextension 70009207 "Sust Emission Types ori" extends "Message Type ori"
{
    /// <summary>Summarises sustainability ledger emissions by scope, period and gas.</summary>
    value(70009207; "Sustainability.EmissionSummary.Get")
    {
        Caption = 'Sustainability.EmissionSummary.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Emission Sum Impl ori", "Msg Discovery ori" = "Sust Emission Sum Impl ori", "Msg Contract ori" = "Sust Emission Sum Impl ori";
    }
}
