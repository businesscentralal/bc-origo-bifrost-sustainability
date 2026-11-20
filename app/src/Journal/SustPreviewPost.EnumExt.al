namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers the non-posting sustainability journal preview.</summary>
enumextension 70009215 "Sust Preview Post ori" extends "Message Type ori"
{
    /// <summary>Simulates a journal batch with rollback.</summary>
    value(70009215; "Sustainability.Journal.PreviewPost")
    {
        Caption = 'Sustainability.Journal.PreviewPost', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Preview Post Impl ori", "Msg Discovery ori" = "Sust Preview Post Impl ori", "Msg Contract ori" = "Sust Preview Post Impl ori";
    }
}
