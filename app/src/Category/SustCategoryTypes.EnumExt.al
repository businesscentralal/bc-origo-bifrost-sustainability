namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers atomic sustainability category maintenance.</summary>
enumextension 70009211 "Sust Category Types ori" extends "Message Type ori"
{
    /// <summary>Creates or updates a category and its listed subcategories.</summary>
    value(70009211; "Sustainability.Category.Set")
    {
        Caption = 'Sustainability.Category.Set', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Category Set Impl ori", "Msg Discovery ori" = "Sust Category Set Impl ori", "Msg Contract ori" = "Sust Category Set Impl ori";
    }
}
