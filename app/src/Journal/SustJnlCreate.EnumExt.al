namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers the journal creation contract without any posting operation.</summary>
enumextension 70009213 "Sust Jnl Create ori" extends "Message Type ori"
{
    /// <summary>Adds unposted sustainability journal lines atomically.</summary>
    value(70009213; "Sustainability.Journal.Create")
    {
        Caption = 'Sustainability.Journal.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Jnl Create Impl ori",
                         "Msg Discovery ori" = "Sust Jnl Create Impl ori",
                         "Msg Contract ori" = "Sust Jnl Create Impl ori";
    }
}
