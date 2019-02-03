package MT::Plugin::FixRebuildingErrorInMTContentFieldTag;
use strict;
use warnings;
use base 'MT::Plugin';

use MT;
use MT::ContentFieldType::Common;
use MT::ContentFieldType::ContentType;

my $plugin = __PACKAGE__->new(
    {   name    => 'FixRebuildingErrorInMTContentFieldTag',
        version => '0.01',
        description =>
            '<__trans phrase="MT7 plugin to fix rebuilding error in MTContentField tag.">',
        plugin_link =>
            'https://github.com/masiuchi/mt7-plugin-fix-rebuilding-error-in-mt-content-field-tag',
        author_name => 'Masahiro IUCHI',
        author_link => 'https://github.com/masiuchi',
        registry    => {
            content_field_types => {
                asset       => { tag_handler => \&_tag_handler_asset, },
                asset_audio => { tag_handler => \&_tag_handler_asset, },
                asset_image => { tag_handler => \&_tag_handler_asset, },
                asset_video => { tag_handler => \&_tag_handler_asset, },
                content_type =>
                    { tag_handler => \&_tag_handler_content_type },
            },
        },
    }
);
MT->add_plugin($plugin);

sub _tag_handler_asset {
    my ( $ctx, $args, $cond, $field_data, $value ) = @_;

    my @ids;
    if ( ref $value eq 'ARRAY' ) {
        @ids = grep {$_} @$value;
    }
    elsif ($value) {
        @ids = ($value);
    }
    my %assets = map { $_->id => 1 }
        MT->model('asset')->load( { id => @ids ? \@ids : 0, class => '*' } );
    my $new_value = [ grep { $assets{$_} } @ids ];

    MT::ContentFieldType::Common::tag_handler_asset( $ctx, $args,
        $cond, $field_data, $new_value );
}

sub _tag_handler_content_type {
    my ( $ctx, $args, $cond, $field_data, $value ) = @_;

    if ( my $cd = $ctx->stash('content') ) {
        my $data    = $cd->data;
        my $raw_ids = $data->{ $field_data->{id} };
        my @ids;
        if ( ref $raw_ids eq 'ARRAY' ) {
            @ids = grep {$_} @$raw_ids;
        }
        elsif ($raw_ids) {
            @ids = ($raw_ids);
        }
        my %cds = map { $_ => 1 }
            MT->model('content_data')->load( { id => @ids ? \@ids : 0 } );
        my $new_ids = [ grep { $cds{$_} } @ids ];
        $data->{ $field_data->{id} } = $new_ids;
        $cd->data($data);
    }

    MT::ContentFieldType::ContentType::tag_handler( $ctx, $args, $cond,
        $field_data, $value );
}

1;
