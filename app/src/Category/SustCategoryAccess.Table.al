namespace Origo.Bifrost.Sustainability;

/// <summary>Empty permission capability; category maintenance stores no records here.</summary>
table 70009211 "Sust Category Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Category Write Access', Comment = 'is-IS=Skrifaðgangur að flokkum';

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
