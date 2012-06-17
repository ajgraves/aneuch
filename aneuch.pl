#!/usr/bin/perl
## $Id$
## **********************************************************************
## Copyright (c) 2012, Aaron J. Graves (cajunman4life@gmail.com)
## All rights reserved.
##
## Redistribution and use in source and binary forms, with or without 
## modification, are permitted provided that the following conditions are met:
##
## 1. Redistributions of source code must retain the above copyright notice, 
##    this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright notice,
##    this list of conditions and the following disclaimer in the documentation
##    and/or other materials provided with the distribution.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
## ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
## POSSIBILITY OF SUCH DAMAGE.
## **********************************************************************
## This is Aneuch, which means 'enough.' I hope this wiki is enough for you.
## **********************************************************************
package Aneuch;
use strict;
# Some variables
use vars qw($DataDir $SiteName $Page $ShortPage @Passwords $PageDir $ArchiveDir
$ShortUrl $SiteMode $ScriptName $ShortScriptName $Header $Footer $PluginDir 
$Url $DiscussText $DiscussPrefix $DiscussLink $DefaultPage $CookieName 
$PageName %FORM $TempDir @Errors $command $contents);
my %srvr = (
  80 => 'http://',
  443 => 'https://',
);
my %commandtitle = (
  ':admin' => 'Administration',
  ':edit' => "Edit $ShortPage",
  ':search' => "Search $ShortPage",
  ':history' => "History for $ShortPage",
);
my %CommandLinks = (
  'admin' => '?admin',
  'edit' => '?edit=',
  'search' => '?search=',
  'history' => '?history=',
);

# Subs
sub InitConfig  {
  if(-f "config.pl") {
    do 'config.pl';
  }
}

sub InitVars {
  # Define settings
  $DataDir = '/tmp/aneuch' unless $DataDir;	# Location of docs
  #$myd = $ENV{'DOCUMENT_ROOT'} . "/";		# Local location
  $DefaultPage = 'HomePage' unless $DefaultPage;	# Default page
  @Passwords = qw() unless @Passwords;		# No password by default
  $SiteMode = 0 unless $SiteMode;		# 0=All, 1=Discus only, 2=None
  $DiscussPrefix = 'Discuss_' unless $DiscussPrefix; # Discussion page prefix
  $SiteName = 'Aneuch' unless $SiteName;		# Default site name
  $CookieName = 'Aneuch' unless $CookieName;	# Default cookie name

  # Some cleanup
  #  Remove trailing slash from $DataDir, if it exists
  $DataDir =~ s!/\z!!;

  # Local variables declared
  #my ($command, $contents);

  # Get page name that is being requested
  $Page = $ENV{'REQUEST_URI'};	# Should be the page
  $Page =~ s!^/!!;		# Remove leading slash, if it exists
  $Page =~ s!\.{2,}!!g;		# Remove every instance of double period
  if($Page =~ m/^.*=.*$/) {		# We're getting a command directive
    my @tc = split("=", $Page);	# Surely there's a better way...
    $command = shift @tc;
    $Page = join("/", @tc);
    $command =~ s/^\?//;	# Get rid of '?', if it's there.
  }
  if($Page eq "") { $Page = $DefaultPage };	# Default if blank
  $Page =~ s/\.[a-z]{3,4}$/.txt/;		# If extension, change to .txt
  if($Page !~ m/\.[a-z]{3}$/) { $Page .= ".txt"; }	# If none, default
  $ShortPage = $Page;			# ShortPage is Page sans extension
  $ShortPage =~ s/\.[a-z]{3,4}$//;
  $PageName = $ShortPage;		# PageName is ShortPage with spaces
  $PageName =~ s/_/ /g;

  # Discuss links
  if($ShortPage !~ m/^$DiscussPrefix/) {
    $DiscussLink = $ShortUrl . $DiscussPrefix . $ShortPage;
    $DiscussText = $DiscussPrefix . $ShortPage;
    $DiscussText =~ s/_/ /g;
    $DiscussText = '<a href="' . $DiscussLink . '">' . $DiscussText . '</a>';
  } else {
    $DiscussLink = $ShortPage;
    $DiscussLink =~ s/^$DiscussPrefix//;
    $DiscussText = $DiscussLink;
    $DiscussLink = $ShortUrl . $DiscussLink;
    $DiscussText = '<a href="' . $DiscussLink . '">' . $DiscussText . '</a>';
  }

  # Figure out the script name, URL, etc.
  $ShortUrl = $ENV{'SCRIPT_NAME'};
  $ShortUrl =~ s/$0//;
  $Url = $srvr{$ENV{'SERVER_PORT'}} . $ENV{'HTTP_HOST'} . $ShortUrl;
  $ScriptName = $ENV{'SCRIPT_NAME'};
  $ShortScriptName = $0;

  # If we're a command, change the page title
  if($command) {
    #$PageName = $commandtitle{$command};
  }
}

sub InitTemplate {
  # If we don't have $Header or $Footer, use the built-in
  if(!defined($Header) and !defined($Footer)) {
    chomp(my @TEMPLATE = <DATA>);
    ($Header, $Footer) = split(/!!CONTENT!!/, join("\n", @TEMPLATE));
  }
}

sub Markup {
  my @contents = @_;
  chomp(@contents);

  if($contents[0] eq "# nomarkup") { return @contents; }
  my $step = 0;
  my $openul = 0;
  my $openol = 0;
  my @build;
  foreach my $line (@contents) {
    # Are we doing lists?
    # UL
    if(($line =~ m/^\*{1,}/) && (! $openul)) {$openul=1; push @build, "<ul>";}
    if(($openul) && ($line !~ m/^\*{1,}/)) {$openul=0; push @build, "</ul>";}
    # OL
    if(($line =~ m/^-{1,}/) && (! $openol)) {$openol=1; push @build, "<ol>";}
    if(($openol) && ($line !~ m/^-{1,}/)) {$openol=0; push @build, "</ol>";}

    # Get rid of comments
    $line =~ s/^#//;

    # Forced line breaks
    $line =~ s#\\\\\s#<br/>#;

    # Headers
    $line =~ s#^={5}(.*)={5}$#<h5>$1</h5>#;
    $line =~ s#^={4}(.*)={4}$#<h4>$1</h4>#;
    $line =~ s#^={3}(.*)={3}$#<h3>$1</h3>#;
    $line =~ s#^={2}(.*)={2}$#<h2>$1</h2>#;
    $line =~ s#^=(.*)=$#<h1>$1</h1>#;

    # Links
    $line =~ s#\[{2}(htt(p|ps)://[^\|]+)\|([^\]]+)\]{2}#<a href="$1" class="external" target="_blank" title="External link: $1">$3</a>#g;
    $line =~ s#\[{2}(\w+)\|{1}([^\]{2}]+)\]{2}#<a href="$1" title="$1">$2</a>#g;
    $line =~ s#\[{2}([^\]{2}]+)\]{2}#<a href="$1" title="$1">$1</a>#g;

    # HR
    $line =~ s#_{4,}#<hr/>#;

    # <tt>
    $line =~ s#\`{1}([^\`]+)\`{1}#<tt>$1</tt>#g;

    # Bold
    $line =~ s#'{3}([^'{3}]+)'{3}#<strong>$1</strong>#g;

    # Extra tags
    #$line =~ s#^{(.*)$#<$1>#;
    #$line =~ s#^}(.*)$#</$1>#;

    # UL LI
    $line =~ s#^\*{1,}(.*)$#<li>$1</li>#;

    # OL LI
    $line =~ s#^-{1,}(.*)$#<li>$1</li>#;

    # Images
    #$line =~ s#<{2}([^\|]+)\|([^>{2}]+)>{2}#<img src="$1" $2 />#g;
    $line =~ s#\{{3}(\w+)\}([^\}]+)\}{2}#<img src="$2" align="$1" />#g;
    $line =~ s#\{{2}([^\}]+)\}{2}#<img src="$1" />#g;

    # Italics
    $line =~ s#'{2}([^'{2}]+)'{2}#<em>$1</em>#g;

    # Add it
    push @build, $line;
  }
  # Ok, now let's do paragraphs.
  my $prevblank = 0;    # Assume false
  my $openp = 0;        # Assume false
  my $i = 0;
  for($i=0;$i<=$#build;$i++) {
    if(($prevblank) && ($build[$i] !~ m/^<[hd]/) && ($build[$i] ne '')) {
      $build[$i] = "<p>".$build[$i];
      $prevblank = 0; $openp = 1;
    }
    if(($build[$i] =~ m/^<[hd]/) || ($build[$i] eq '')) {
      $prevblank = 1;
      if(($i > 0) && ($build[$i-1] !~ m/^<[hd]/) && ($openp)) {
        $build[$i-1] .= "</p>"; $openp = 0;
      }
    }
  }
  if($openp) { $build[$#build] .= "</p>"; }

  # Output
  return ("<!-- start of Aneuch markup -->\n", @build, "\n<!-- end of Aneuch markup -->\n");
}

sub Trim($) {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub Interpolate {
  my $work = shift;
  $work =~ s/(\$\w+(?:::)?\w*)/"defined $1 ? $1 : ''"/gee;
  return $work;
}

sub GetFile {
  my ($rt, $file) = @_;
  my @return = qw();
  my $ret;
  if(-f "${rt}/${file}") {
    open(FH,"${rt}/${file}") or die $!;
    @return = <FH>;
    close(FH);
  }
  return @return;
}

sub InitDirs {
  eval { mkdir $DataDir unless -d $DataDir; }; push @Errors, $@ if $@;
  $PageDir = "$DataDir/pages";
  eval { mkdir $PageDir unless -d $DataDir; }; push @Errors, $@ if $@;
  $ArchiveDir = "$DataDir/archive";
  eval { mkdir $ArchiveDir unless -d $ArchiveDir; }; push @Errors, $@ if $@;
  $PluginDir = "$DataDir/plugins";
  eval { mkdir $PluginDir unless -d $PluginDir; }; push @Errors, $@ if $@;
  $TempDir = "$DataDir/temp";
  eval { mkdir $TempDir unless -d $TempDir; }; push @Errors, $@ if $@;
}

sub LoadPlugins {
  # Scan $PluginDir for .pl and .pm files, and load them.
  if($PluginDir and -d $PluginDir) {
    foreach my $plugin (glob("$PluginDir/*.pl $PluginDir/*.pm")) {
      next unless ($plugin =~ /^($PluginDir\/[-\w.]+\.p[lm])$/o);
      $plugin = $1;
      do $plugin;
    }
  }
}

sub ReadCookie {
  # Read cookies
  my $rcvd_cookies = $ENV{'HTTP_COOKIE'};
  my @cookies = split(/;/, $rcvd_cookies);
  my $wikicookie = (split(/=/,grep(/^$CookieName=/, @cookies)))[1];
  if(!$wikicookie) { return ('',''); }
  my @c = split(/&/,$wikicookie);
  my ($uname, $passwd) = '';
  foreach my $cc (@c) {
    if($cc =~ m/^user\./) { $uname = (split(/\./, $cc))[1]; }
    if($cc =~ m/^pwd\./) { $passwd = (split(/\./, $cc))[1]; }
  }
  return ($uname, $passwd);
}

sub CanEdit {
  
}

sub EditDisplay {
  my $contents = join("", GetFile($PageDir, $Page));
  $contents =~ s/</&lt;/g;            # Transform
  $contents =~ s/>/&gt;/g;
  print '<textarea cols="100" rows="25">' . $contents . '</textarea>';
  print '<p><a href="' . $ShortUrl . $ShortPage . '">Return</a></p>';
  if(CanEdit) {
    # Buttons
  }
}

sub AdminForm {
  print '<form action="' . $ScriptName . '" method="post">';
  print 'User: <input type="text" maxlength="8" size="8" name="user" />';
  print ' Pass: <input type="password" size="12" name="pass" />';
  print '<input type="submit" value="Go" /></form>';
}

sub DoAdmin {
  my ($u,$p) = ReadCookie;
  if(!$u) {
    print "<p>Presently, you do not have a user name set.</p>";
  } else {
    print "<p>Your user name is set to '$u'.</p>";
  }
  AdminForm;
}

sub ReadIn {
  my $buffer;
  if($ENV{'REQUEST_METHOD'} ne "POST") { return 0; }
  read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  if ($buffer eq "") {
    return 0;
  }
  my @pairs = split(/&/, $buffer);
  foreach my $pair (@pairs) {
    my ($name, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $FORM{$name} = $value;
  }
  return 1;
}

sub Init {
  InitConfig;
  InitVars;
  InitDirs;
  LoadPlugins;
  InitTemplate;
}

sub DoRequest {
  # HTTP Header
  print "Content-type: text/html\n\n";

  # Header
  print Interpolate($Header);
  
  # This is where the magic happens
  if($command) {                          # Command directive?
    if($command eq 'edit') {             # Edit file
      EditDisplay;
    }
    if($command eq 'admin') {
      DoAdmin;
    }
  } else {
    if(! -f "$PageDir/$Page") {
      print '<p>It appears that there is nothing here.</p>';
    } else {
      if(exists &Markup) {                # If there's markup defined, do markup
        print join("\n", Markup(GetFile($PageDir, $Page)));
      } else {
        print join("\n", GetFile($PageDir, $Page));
      }
    }
  }

  # Footer
  print Interpolate($Footer);
}

## START
Init;		# Load
DoRequest;	# Handle the request
1;	# In case we're being called elsewhere

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<title>$SiteName: $PageName</title>
<link rel="alternate" type="application/wiki" title="Edit this page" href="$Url?edit=$ShortPage" />
<meta name="robots" content="INDEX,FOLLOW" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<style type="text/css">
body {
    background:#fff;
    padding:2% 3%;
    margin:0;
    font-family: "Bookman Old Style", "Times New Roman", serif;
    font-size: 12pt;
}
a {
    text-decoration:none;
    font-weight:bold;
    color:#c00;
}
/*a:visited { color:#c55; }*/
div.header h1 a:hover, h1 a:hover, h2 a:hover, h3 a:hover, h4 a:hover,
a:hover, span.caption a.image:hover {
    background:#000000;
    color:#FFFFFF;
}
a.image:hover {
    background:inherit;
}
a.image:hover img {
    background:#ccc;
}
div.header h1 {
    font-size:xx-large; margin-top:1ex;
    border-bottom: 5px solid #000;
}
div.header h1 a {
    color: gray;
}
hr {
    border:none;
    color:black;
    background-color:#000;
    height:2px; 
    margin-top:2ex;
}
div.footer hr { 
  height:4px;
  clear:both;
}
div.wrapper p {
  text-align:justify;
}
a.external {
  color:blue;
}
a.external:hover {
  color:white;
  background-color:red;
}

textarea {
  width: 100%;
}

@media print {
body { font:11pt "Neep", "Arial", sans-serif; }
a, a:link, a:visited { color:#000; text-decoration:none; font-style:oblique; font-weight:normal; }
h1 a, h2 a, h3 a, h4 a { font-style:normal; }
a.edit, div.footer, div.refer, form, span.gotobar, a.number span { display:none; }
a[class="url number"]:after, a[class="inter number"]:after { content:"[" attr(href) "]"; }
a[class="local number"]:after { content:"[" attr(title) "]"; }
img[smiley] { line-height: inherit; }
pre { border:0; font-size:10pt; }
}
</style>
</head>
<body>
<div class="header"><a href="$Url$DefaultPage">$DefaultPage</a> $Navbar
<h1><a title="Search for references to $ShortPage" rel="nofollow" href="$ShortUrl?search=$ShortPage">$PageName</a></h1></div>
<div class="wrapper">
!!CONTENT!!
</div>
<div class="close"></div>
<div class="footer">
<hr/>
$DiscussText
<a title="Click to edit this page" rel="nofollow" href="$ShortUrl?edit=$ShortPage">Edit $PageName</a> 
<a title="Click here to see revision history" rel="nofollow" href="$ShortUrl?history=$ShortPage">View Revisions</a> 
<a title="Administration options" rel="nofollow" href="$ShortUrl?admin">Admin</a><span style="float:right;"><strong>$SiteName</strong>
is powered by <em>Aneuch</em>.</span>
<span class="time"><br/>
$EditString</span>
</div>
</body>
</html>
