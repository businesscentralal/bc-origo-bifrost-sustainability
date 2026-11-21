namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>Registers Sustainability.Goal.Set with Foundation.</summary>
enumextension 70009212 "Sust Goal Set Types ori" extends "Message Type ori"
{
    value(70009212; "Sustainability.Goal.Set")
    {
        Caption = 'Sustainability.Goal.Set', Locked = true;
        Implementation = "Msg Interface ori" = "Sust Goal Set Impl ori",
                          "Msg Discovery ori" = "Sust Goal Set Impl ori",
                          "Msg Contract ori" = "Sust Goal Set Impl ori";
    }
}
