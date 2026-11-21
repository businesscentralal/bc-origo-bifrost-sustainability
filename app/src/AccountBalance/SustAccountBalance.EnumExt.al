namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers the read-only sustainability account balance message.</summary>
enumextension 70009208 "Sust Account Balance ori" extends "Message Type ori"
{
    /// <summary>Reads native net change and balances by sustainability account.</summary>
    value(70009208; "Sustainability.AccountBalance.Get")
    {
        Caption = 'Sustainability.AccountBalance.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Account Bal Impl ori", "Msg Discovery ori" = "Sust Account Bal Impl ori", "Msg Contract ori" = "Sust Account Bal Impl ori";
    }
}
