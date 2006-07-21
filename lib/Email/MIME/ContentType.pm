package Email::MIME::ContentType;
# $Id: ContentType.pm,v 1.3 2005/02/22 00:24:03 cwest Exp $
use base 'Exporter';
use vars qw[$VERSION @EXPORT];
@EXPORT = qw(parse_content_type);
use strict;
use Carp;
$VERSION = '1.01';

my $tspecials = quotemeta '()<>@,;:\\"/[]?=';
my $ct_default = 'text/plain; charset=us-ascii';
my $extract_quoted = 
    qr/(?:\"(?:[^\\\"]*(?:\\.[^\\\"]*)*)\"|\'(?:[^\\\']*(?:\\.[^\\\']*)*)\')/;

# For documentation, really:
{
my $discrete  = qr/[^$tspecials]+/;
my $composite = qr/[^$tspecials]+/;
my $params    = qr/;.*/;

sub parse_content_type { # XXX This does not take note of RFC2822 comments
    my $ct = shift;

    $ct =~ m[ ^ ($discrete) / ($composite) \s* ($params)? $ ]x
        or return parse_content_type($ct_default);
        # It is also recommend (sic.) that this default be assumed when a
        # syntactically invalid Content-Type header field is encountered.

    return { discrete => lc $1, composite => lc $2,
             attributes => _parse_attributes($3) };
}

}

sub _parse_attributes {
    local $_ = shift;
    my $attribs = {};
    while ($_) {
        s/^;//;
        s/^\s+// and next;
        s/\s+$//;
        unless (s/^([^$tspecials]+)=//) {
          carp "Illegal Content-Type parameter $_";
          return $attribs;
        }
        my $attribute = lc $1;
        my $value = _extract_ct_attribute_value();
        $attribs->{$attribute} = $value;
    }
    return $attribs;
}

sub _extract_ct_attribute_value { # EXPECTS AND MODIFIES $_
    my $value;
    while ($_) { 
        s/^([^$tspecials]+)// and $value .= $1;
        s/^($extract_quoted)// and do {
            my $sub = $1; $sub =~ s/^["']//; $sub =~ s/["']$//;
            $value .= $sub;
        };
        /^;/ and last;
        /^([$tspecials])/ and do { 
            carp "Unquoted $1 not allowed in Content-Type!"; 
            return;
        }
    }
    return $value;
}

1;

__END__

=head1 NAME

Email::MIME::ContentType - Parse a MIME Content-Type Header

=head1 SYNOPSIS

  use Email::MIME::ContentType;
  my $ct = "Content-Type: text/plain; charset="us-ascii"; format=flowed";
  my $data = parse_content_type($ct);
  $data = {
    discrete => "text",
    composite => "plain",
    attributes => {
        charset => "us-ascii",
        format => "flowed"
    }
  }

=head1 DESCRIPTION

This module is responsible for parsing email content type headers
according to section 5.1 of RFC 2045. It returns a hash as above, with
entries for the discrete type, the composite type, and a hash of
attributes.

=head2 EXPORT

C<parse_content_type>

=head1 AUTHOR

Casey West, C<casey@geeknest.com>
Simon Cozens, C<simon@cpan.org>

=head1 CONTACT

Perl Email Project, C<pep@perl.org>.

=head1 SEE ALSO

L<Email::MIME>

=cut
