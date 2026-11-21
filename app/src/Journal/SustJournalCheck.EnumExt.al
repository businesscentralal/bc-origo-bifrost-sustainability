namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers the non-posting sustainability journal check.</summary>
enumextension 70009214 "Sust Journal Check ori" extends "Message Type ori"
{
    /// <summary>Checks a journal batch with rollback.</summary>
    value(70009214; "Sustainability.Journal.Check")
    {
        Caption = 'Sustainability.Journal.Check', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Journal Check Impl ori", "Msg Discovery ori" = "Sust Journal Check Impl ori", "Msg Contract ori" = "Sust Journal Check Impl ori";
    }
}
