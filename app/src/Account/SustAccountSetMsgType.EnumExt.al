namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers Sustainability.Account.Set on the Bifrost message type enum.</summary>
enumextension 70009210 "Sust Account Set Msg Type ori" extends "Message Type ori"
{
    /// <summary>Creates or updates a Sustainability Account with its category and subcategory validated together.</summary>
    value(70009210; "Sustainability.Account.Set")
    {
        Caption = 'Sustainability.Account.Set', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Account Set Impl ori", "Msg Discovery ori" = "Sust Account Set Impl ori", "Msg Contract ori" = "Sust Account Set Impl ori";
    }
}
