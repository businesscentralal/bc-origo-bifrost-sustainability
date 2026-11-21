namespace Origo.Bifrost.Sustainability;

/// <summary>Permission capability for the emission summary read. No records are stored in this table.</summary>
table 70009207 "Sust Emission Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Sustainability Emission Read Access', Comment = 'is-IS=Lesaðgangur að losunaryfirliti';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
