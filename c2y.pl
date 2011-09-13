#!/usr/bin/perl
use strict;
use warnings;
use XML::RSS;
use LWP::Simple;
use Date::Manip;
use Net::SMTP;
use Net::SMTP::SSL;
use Authen::SASL;

# SMTP
use constant SMTP_SERVER   => 'smtp_server';   # change your smtp server
use constant SMTP_PORT     => 25;                # change your port
use constant SMTP_USER     => 'smtp_user';   # change your account
use constant SMTP_PASSWORD => 'smtp_password';         # change your password
use constant SMTP_DEBUG    => 0;                  # 0: no_debug, 1: deubg

# MAIL
use constant MAIL_TO      => 'group+yourdomain@yammer.com';
use constant MAIL_FROM    => 'yammer_user@yourdomain';
use constant HELLO_DOMAIN => 'yourdomain';

# LAST_MODIFY_DATE_FILE
use constant PREVIOUS_FILE => 'c2y.txt';

# FEEDS
use constant JIKOTSUCHI_FEED => 'http://yourdomain/rss.xml';
my @feeds = (JIKOTSUCHI_FEED);

# previous execute
open( PREVIOUS, PREVIOUS_FILE ) || die "$!";
my $last_exec_date = <PREVIOUS>;
close(PREVIOUS);
chomp $last_exec_date;
$last_exec_date =~ s/^(Mon|Tue|Wed|Thu|Fri|Sat|Sun) //;
$last_exec_date = ParseDate($last_exec_date);

# PostData
my $mail_content = undef;
foreach my $feed (@feeds) {
    my $content = get($feed);
    die "Couldn't get it" unless defined $content;
    my $rss = XML::RSS->new( version => '2.0' );
    $rss->parse($content);
    foreach my $item ( @{ $rss->{'items'} } ) {
        my $pubDate = $item->{'pubDate'};
        $pubDate = ParseDate($pubDate);
        if ( Date_Cmp( $pubDate, $last_exec_date ) == 1 ) {
            $mail_content .= "pubDate: $item->{'pubDate'}\n";
            $mail_content .= "title: $item->{'title'}\n";
            $mail_content .= "link: $item->{'link'}\n";
            $mail_content .= "\n";
        }
    }
}

#
unless ( defined($mail_content) ) {
    warn "no post data";
    exit;
}

# post
my $smtp =
  Net::SMTP::SSL->new( SMTP_SERVER, Port => SMTP_PORT, Debug => SMTP_DEBUG );
$smtp->auth( SMTP_USER, SMTP_PASSWORD ) || die "$!";
$smtp->mail(MAIL_FROM);
$smtp->to(MAIL_TO);
$smtp->data();
$smtp->datasend($mail_content);
$smtp->dataend();
$smtp->quit;

# modify timestamp
my $now = ParseDate("now");
open( PREVIOUS, ">" . PREVIOUS_FILE ) || die "$!";
print PREVIOUS UnixDate( $now, "%c" );
close(PREVIOUS);

exit;
