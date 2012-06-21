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
use POSIX qw(strftime);
# Some variables
use vars qw($DataDir $SiteName $Page $ShortPage @Passwords $PageDir $ArchiveDir
$ShortUrl $SiteMode $ScriptName $ShortScriptName $Header $Footer $PluginDir 
$Url $DiscussText $DiscussPrefix $DiscussLink $DefaultPage $CookieName 
$PageName %FORM $TempDir @Messages $command $contents @Plugins $TimeStamp
$PostFooter $TimeZone $VERSION $EditText $RevisionsText $NewPage $NewComment
$NavBar $ConfFile $UserIP $UserName $VisitorLog $LockExpire);
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
my %Commands = (
  admin => \&DoAdmin,
  edit => \&DoEdit,
  search => \&DoSearch,
  history => \&DoHistory,
);

$VERSION = '0.1';

# Subs
sub InitConfig  {
  $ConfFile = 'config.pl' unless $ConfFile;
  if(-f $ConfFile) {
    do $ConfFile;
  }
}

sub InitVars {
  # We must be the first entry in Plugins
  @Plugins = ("aneuch.pl, version $VERSION, <a href='http://aneuch.myunixhost.com/' target='_blank'>Aneuch Wiki Engine</a>");
  # Define settings
  $DataDir = '/tmp/aneuch' unless $DataDir;	# Location of docs
  #$myd = $ENV{'DOCUMENT_ROOT'} . "/";		# Local location
  $DefaultPage = 'HomePage' unless $DefaultPage;	# Default page
  @Passwords = qw() unless @Passwords;		# No password by default
  $SiteMode = 0 unless $SiteMode;		# 0=All, 1=Discus only, 2=None
  $DiscussPrefix = 'Discuss_' unless $DiscussPrefix; # Discussion page prefix
  $SiteName = 'Aneuch' unless $SiteName;		# Default site name
  $CookieName = 'Aneuch' unless $CookieName;	# Default cookie name
  $TimeZone = 0 unless $TimeZone;		# Default to GMT, 1=localtime
  $LockExpire = 60*5 unless $LockExpire;	# 5 mins, unless set elsewhere

  # Some cleanup
  #  Remove trailing slash from $DataDir, if it exists
  $DataDir =~ s!/\z!!;

  # Figure out the script name, URL, etc.
  $ShortUrl = $ENV{'SCRIPT_NAME'};
  $ShortUrl =~ s/$0//;
  $Url = $srvr{$ENV{'SERVER_PORT'}} . $ENV{'HTTP_HOST'} . $ShortUrl;
  $ScriptName = $ENV{'SCRIPT_NAME'};
  $ShortScriptName = $0;

  # Get page name that is being requested
  $Page = $ENV{'QUERY_STRING'};	# Should be the page
  $Page =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;	# Get "plain"
  $Page =~ s!^/!!;		# Remove leading slash, if it exists
  $Page =~ s/ /_/g;		# Convert spaces to underscore
  $Page =~ s!\.{2,}!!g;		# Remove every instance of double period
  if($Page =~ m/^?do=(.*)&page=(.*)$/) {# We're getting a command directive
    $command = $1;
    $Page = $2;
    $command =~ s/^\?//;	# Get rid of '?', if it's there.
  }
  if($Page eq "") { $Page = $DefaultPage };	# Default if blank
  #$Page =~ s/\.[a-z]{3,4}$/.txt/;		# If extension, change to .txt
  #if($Page !~ m/\.[a-z]{3}$/) { $Page .= ".txt"; }	# If none, default
  $Page =~ s/\.[\w]{3,4}$//;		# Remove all extensions
  $ShortPage = $Page;			# ShortPage is Page sans extension
  $ShortPage =~ s/\.[a-z]{3,4}$//;
  $PageName = $ShortPage;		# PageName is ShortPage with spaces
  $PageName =~ s/_/ /g;

  # I know we just went through all that crap, but if command=admin, we need:
  if($command and $command eq 'admin') {
    $PageName = 'Admin';
    #$ShortPage = '';
    $Page = '';
  }

  # Discuss links
  if(!$command or $command ne 'admin') {
    if($ShortPage !~ m/^$DiscussPrefix/) {
      $DiscussLink = $ShortUrl . $DiscussPrefix . $ShortPage;
      $DiscussText = $DiscussPrefix . $ShortPage;
      $DiscussText =~ s/_/ /g;
      $DiscussText = '<a title="' . $DiscussText . '" href="' . $DiscussLink . '">' . $DiscussText . '</a>';
    } else {
      $DiscussLink = $ShortPage;
      $DiscussLink =~ s/^$DiscussPrefix//;
      $DiscussText = $DiscussLink;
      $DiscussLink = $ShortUrl . $DiscussLink;
      $DiscussText = '<a title="Return to ' . $DiscussText . '" href="' . $DiscussLink . '">' . $DiscussText . '</a>';
    }
    if(&CanEdit) {
      $EditText = '<a title="Click to edit this page" rel="nofollow" href="' . $ShortUrl . '?do=edit&page=' . $ShortPage . '">Edit ' . $PageName . '</a>';
    } else {
      $EditText = '<a title="Read only page" rel="nofollow" href="' . $ShortUrl . '?do=edit&page=' . $ShortPage . '">This page is read only</a>';
    }
    $RevisionsText = '<a title="Click here to see revision history" rel="nofollow" href="' . $ShortUrl . '?do=history&page=' . $ShortPage . '">View page history</a>';
  }

  # If we're a command, change the page title
  #if($command) {
  #  $PageName = $commandtitle{$command};
  #}

  # Set the TimeStamp
  $TimeStamp = time;

  # New page and new comment
  $NewPage = '<p>It appears that there is nothing here.</p>' unless $NewPage;
  $NewComment = 'Add your comment here.' unless $NewComment;

  # Set visitor IP address
  $UserIP = $ENV{'REMOTE_ADDR'};
  ($UserName) = &ReadCookie;

  # Navbar
  $NavBar = "<a href='$Url$DefaultPage'>$DefaultPage</a> <a href='".$ShortUrl."RecentChanges'>RecentChanges</a> " . $NavBar;
}

sub InitTemplate {
  # If we don't have $Header or $Footer, use the built-in
  if(!defined($Header) and !defined($Footer)) {
    chomp(my @TEMPLATE = <DATA>);
    ($Header, $Footer) = split(/!!CONTENT!!/, join("\n", @TEMPLATE));
  }
}

sub Markup {
  chomp(my @contents = @_);
  if($contents[0] eq "# nomarkup") { return @contents; }
  my $step = 0;
  my $openul = 0;
  my $openol = 0;
  my $listlevel = 0;
  my @build;
  foreach my $line (@contents) {
    # Are we doing lists?
    # UL
    if(($line =~ m/^[\s\t]*\*{1,5}[ \t]/) && (! $openul)) {$openul=1; push @build, "<ul>";}
    if(($openul) && ($line !~ m/^[\s\t]*\*{1,5}[ \t]/)) {$openul=0; push @build, "</ul>";}
    # OL
    if(($line =~ m/^[\s\t]*#{1,}/) && (! $openol)) {$openol=1; push @build, "<ol>";}
    if(($openol) && ($line !~ m/^[\s\t]*#{1,}/)) {$openol=0; push @build, "</ol>";}

    # Get rid of comments
    #$line =~ s/^#//;

    # Forced line breaks
    $line =~ s#\\\\#<br/>#;

    # Headers
    $line =~ s#^={5}(.*?)(=*)$#<h5>$1</h5>#;
    $line =~ s#^={4}(.*?)(=*)$#<h4>$1</h4>#;
    $line =~ s#^={3}(.*?)(=*)$#<h3>$1</h3>#;
    $line =~ s#^={2}(.*?)(=*)$#<h2>$1</h2>#;
    $line =~ s#^=(.*?)(=*)$#<h1>$1</h1>#;

    # Links
    $line =~ s#\[{2}(htt(p|ps)://.*?)\|(.*?)\]{2}#<a href="$1" class="external" target="_blank" title="External link: $1">$3</a>#g;
    $line =~ s#\[{2}(.*?)\|{1}(.*?)\]{2}#<a href="$1" title="$1">$2</a>#g;
    $line =~ s#\[{2}(.*?)\]{2}#<a href="$1" title="$1">$1</a>#g;

    # HR
    $line =~ s#^_{4,}$#<hr/>#;

    # <tt>
    $line =~ s#\`{1}(.*?)\`{1}#<tt>$1</tt>#g;

    # Extra tags
    #$line =~ s#^{(.*)$#<$1>#;
    #$line =~ s#^}(.*)$#</$1>#;

    # UL LI
    $line =~ s#^[\s\t]*\*{1,5}[ \t](.*)#<li>$1</li>#s;

    # OL LI
    $line =~ s!^[\s\t]*#{1,5}[ \t](.*)!<li>$1</li>!s;

    # Bold
    $line =~ s#\*{2}(.*?)\*{2}#<strong>$1</strong>#g;

    # Images
    #$line =~ s#<{2}([^\|]+)\|([^>{2}]+)>{2}#<img src="$1" $2 />#g;
    $line =~ s#\{{2}(left|right):(.*?)\|(.*?)\}{2}#<img src="$2" alt="$3" align="$1" />#g;
    $line =~ s#\{{2}(left|right):(.*?)\}{2}#<img src="$2" align="$1" />#g;
    $line =~ s#\{{2}(.*?)\|(.*?)\}{2}#<img src="$1" alt="$2" />#g;
    $line =~ s#\{{2}(.*?)\}{2}#<img src="$1" />#g;

    # Fix for italics...
    $line =~ s#htt(p|ps)://#htt$1:~/~/#g;
    # Italics
    $line =~ s#/{2}(.*?)/{2}#<em>$1</em>#g;
    # Fix for italics...
    $line =~ s#htt(p|ps):~/~/#htt$1://#g;

    # Strikethrough
    $line =~ s#-{2}(.*?)-{2}#<del>$1</del>#g;

    # Add it
    push @build, $line;
  }
  # Ok, now let's do paragraphs.
  my $prevblank = 0;    # Assume false
  my $openp = 0;        # Assume false
  my $i = 0;
  for($i=0;$i<=$#build;$i++) {
    if($prevblank and ($build[$i] !~ m/^<[h]/) and ($build[$i] ne '')) {
      $prevblank = 0;
      if(!$openp) {
        $build[$i] = "<p>".$build[$i];
        $openp = 1;
      }
    }
    if(($build[$i] =~ m/^<[h]/) || ($build[$i] eq '')) {
      $prevblank = 1;
      if(($i > 0) && ($build[$i-1] !~ m/^<[h]/) && ($openp)) {
        $build[$i-1] .= "</p>"; $openp = 0;
      }
    }
  }
  if($openp) { $build[$#build] .= "</p>"; }

  # Output
  return ("<!-- start of Aneuch markup -->\n", @build, "\n<!-- end of Aneuch markup -->\n");
}

sub Trim {
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
    open(FH,"${rt}/${file}") or push @Messages, $!; #die $!;
    @return = <FH>;
    close(FH);
  }
  #chomp(@return);
  s/\r//g for @return;
  return @return;
}

sub InitDirs {
  eval { mkdir $DataDir unless -d $DataDir; }; push @Messages, $@ if $@;
  $PageDir = "$DataDir/pages";
  eval { mkdir $PageDir unless -d $PageDir; }; push @Messages, $@ if $@;
  $ArchiveDir = "$DataDir/archive";
  eval { mkdir $ArchiveDir unless -d $ArchiveDir; }; push @Messages, $@ if $@;
  $PluginDir = "$DataDir/plugins";
  eval { mkdir $PluginDir unless -d $PluginDir; }; push @Messages, $@ if $@;
  $TempDir = "$DataDir/temp";
  eval { mkdir $TempDir unless -d $TempDir; }; push @Messages, $@ if $@;
  $VisitorLog = "$DataDir/visitors.log";
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
  my ($uname, $passwd) = ('','');
  my @cookies = split(/;/, $rcvd_cookies);
  foreach my $c (@cookies) {
    if(grep(/^$CookieName=/,&Trim($c))) {
      ($uname, $passwd) = split(/:/, (split(/=/,$c))[1]);
    }
  }
  return ($uname, $passwd);
}

sub SetCookie {
  # Save user and pass to cookie
  my ($user, $pass) = ($FORM{user}, $FORM{pass});
  my $matchedpass = grep(/^$pass$/, @Passwords); # Did they provide right pass?
  my $cookie = $user if $user;		# Username first, if they gave it
  if($matchedpass and $user) {		# Need both...
    $cookie .= ':' . $pass;
  }
  my $futime = gmtime($TimeStamp + 31556926)." GMT";	# Now + 1 year
  print "Set-cookie: $CookieName=$cookie; path=$ShortUrl; expires=$futime;\n";
  #print "Location: $ShortUrl\n\n";
}

sub CanEdit {
  my ($u, $p) = &ReadCookie;
  my $matchedpass = grep(/^$p$/, @Passwords);
  if($SiteMode == 0 or $matchedpass > 0) {
    return 1;
  } else {
    return 0;
  }
}

sub CanDiscuss {
  #my ($u, $p) = &ReadCookie;
  if($SiteMode < 2 and $ShortPage =~ m/^$DiscussPrefix/) {
    return 1;
  } else {
    return 0;
  }
}

sub DoEdit {
  my $canedit = &CanEdit;
  # Let's begin
  my $contents = join("", &GetFile($PageDir, $Page));
  $contents =~ s/</&lt;/g;            # Transform
  $contents =~ s/>/&gt;/g;
  if($canedit) {
    print '<form action="' . $ShortUrl . $ShortScriptName . '" method="post">';
    print '<input type="hidden" name="doing" value="editing">';
    print '<input type="hidden" name="file" value="' . $ShortPage . '">';
    if(-f "$PageDir/$Page") {
      print '<input type="hidden" name="mtime" value="' . (stat("$PageDir/$Page"))[9] . '">';
    }
  }
  print '<textarea name="text" cols="100" rows="25">' . $contents . '</textarea>';
  if($canedit) {
    # Set a lock
    if(&SetLock) {
      print 'Log message: <input type="text" name="log" size="60" />';
      print ' User name: <input type="text" name="uname" size="12" value="'.$UserName.'" />';
      print '<input type="submit" name="whattodo" value="Save" />';
      print '<input type="submit" name="whattodo" value="Cancel" />';
    }
    print '</form>';
  }
  #print '<p><a href="' . $ShortUrl . $ShortPage . '">Return</a></p>';
}

sub SetLock {
  if(-f "$TempDir/$Page.lock" and ((stat("$TempDir/$Page.lock"))[9] <= ($TimeStamp - $LockExpire))) {
    &UnLock;
  }
  # Set a lock on $Page
  if(-f "$TempDir/$Page.lock") {
    open(LOCK,"<$TempDir/$Page.lock") or push @Messages, "Error opening $Page.lock for read: $!";
    my @lock = <LOCK>;
    close(LOCK);
    print "<p><span style='color:red'>This file is locked by <strong>$lock[0]</strong> since <strong>" . (FriendlyTime($lock[1]))[$TimeZone] . "</strong>.</span>";
    print "<br/>Lock should expire by " . (FriendlyTime($lock[1] + $LockExpire))[$TimeZone] . ", and it is now " . (&FriendlyTime)[$TimeZone] . ".</p>";
    return 0;
  } else {
    open(LOCK,">$TempDir/$Page.lock") or push @Messages, "Error opening $Page.lock for write: $!";
    print LOCK "$UserIP\n$TimeStamp";
    close(LOCK);
    return 1;
  }
}

sub UnLock {
  my $pg = $Page;
  ($pg) = @_ if @_ >= 1;
  if(-f "$TempDir/$pg.lock") {
    if(!unlink "$TempDir/$pg.lock") {
      push @Messages, "Unable to delete lock file $pg.lock: $!";
    }
  }
}

sub Index {
  my $pg = $ShortPage;
  ($pg) = @_ if @_ >= 1;
  open(INDEX,"<$DataDir/pageindex") or push @Messages, "Index: Unable to open pageindex for read: $!";
  my @pagelist = <INDEX>;
  close(INDEX);
  if(!grep(/^$pg$/,@pagelist)) {
    open(INDEX,">>$DataDir/pageindex") or push @Messages, "Index: Unable to open pageindex for append: $!";
    print INDEX "$pg\n";
  }
}

sub DoArchive {
  my $file = shift;	# The file we're working on
  if(!-f "$PageDir/$file") { return; }
  # $archive will be the 1-letter dir under /archive that we're writing to
  my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  # If $archive doesn't exist, we'd better create it...
  if(! -d "$ArchiveDir/$archive") { mkdir "$ArchiveDir/$archive"; }
  # Now copy...
  system("cp $PageDir/$file $ArchiveDir/$archive/$file.$TimeStamp");
  #system("gzip $ArchiveDir/$archive/$file.$TimeStamp");
}

sub WriteFile {
  my ($file, $content) = @_;
  &DoArchive($file);
  $content =~ s/\r//g;
  open(FILE, ">$PageDir/$file") or push @Messages, "Unable to write to $file: $!";
  print FILE $content;
  close(FILE);
  &UnLock($file);
  &Index($file);
}

sub AdminForm {
  print '<form action="' . $ShortUrl . $ShortScriptName . '" method="post">';
  print '<input type="hidden" name="doing" value="login" />';
  print 'User: <input type="text" maxlength="30" size="8" name="user" />';
  print ' Pass: <input type="password" size="12" name="pass" />';
  print '<input type="submit" value="Go" /></form>';
}

sub DoAdmin {
  if($ShortPage eq 'version') {
    print '<p>Versions used on this site:</p>';
    foreach my $c (@Plugins) {
      print "<p>$c</p>\n";
    }
  }
  print '<p>You may:<ul><li><a href="'.$ShortUrl.'?do=admin&page=version">View version information</a></li>';
  print '</ul></p>';
  my ($u,$p) = &ReadCookie;
  if(!$u) {
    print "<p>Presently, you do not have a user name set.</p>";
  } else {
    print "<p>Your user name is set to '$u'.</p>";
  }
  &AdminForm;
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

sub DoDiscuss {
  # So that plugins can modify the DoDiscuss action without having to totally
  # re-write it, the decision was made that instead of DoDiscuss printing
  # output directly, it should return an array.
  my @returndiscuss = ();
  if(!&CanDiscuss) {
    return @returndiscuss;
  }
  push @returndiscuss, "<form action='$ShortUrl$ShortScriptName' method='post'>";
  push @returndiscuss, "<input type='hidden' name='doing' value='discuss' />";
  push @returndiscuss, "<input type='hidden' name='file' value='$ShortPage' />";
  push @returndiscuss, "<textarea name='comment' cols='80' rows='5'>$NewComment</textarea>";
  push @returndiscuss, "Name: <input type='text' name='uname' width='12' value='$UserName' /> ";
  push @returndiscuss, "URL (optional): <input type='text' name='url' width='12' />";
  push @returndiscuss, "<input type='submit' value='Save' />";
  push @returndiscuss, "</form>";

  return @returndiscuss;
}

sub DoRecentChanges {
  print "<hr/><p>Showing recent changes:</p>";
}

sub DoSearch {

}

sub DoHistory {

}

sub FriendlyTime {
  my ($rcvd) = @_ if @_ >= 0;
  # FriendlyTime gives us a regular time rather than num of seconds
  $TimeStamp = time() unless $TimeStamp;	# If it wasn't set before...
  my $tv = $TimeStamp;
  $tv = $rcvd if $rcvd;
  my $localtime = strftime "%a %b %e %H:%M:%S %Z %Y", localtime($tv);
  my $gmtime = strftime "%a %b %e %H:%M:%S GMT %Y", gmtime($tv);
  # Send them back in an array... GMT first, local second.
  return ($gmtime, $localtime);
}

sub Posting {
  #my $action = $FORM{doing};
  my ($action) = @_ if @_ >= 0;
  #return unless $action;
  if($action eq 'login') {
    &SetCookie;
  }
  if($action eq 'editing') {
    if($FORM{'whattodo'} eq "Cancel") {
      &UnLock($FORM{'file'});
    } else {
      &WriteFile($FORM{'file'}, $FORM{'text'});
    }
  }
}

sub DoVisit {
  my $logentry = "$UserIP $TimeStamp $ShortPage ";
  if($command) { $logentry .= "($command) "; }
  $logentry .= "$UserName";
  open(LOGFILE,">>$VisitorLog");
  print LOGFILE "$logentry\n";
  close(LOGFILE);
}

sub DoMaint {

}

sub DoRequest {
  # Are we receiving something?
  if(&ReadIn) {
    &Posting($FORM{doing});
    #return;
  }

  # HTTP Header
  print "Content-type: text/html\n\n";

  # Header
  print Interpolate($Header);
  # This is where the magic happens
  if($command and $Commands{$command}) {	# Command directive?
    &{$Commands{$command}};			# Execute it.
  } else {
    if(! -f "$PageDir/$Page") {
      print $NewPage;
    } else {
      if(exists &Markup) {                # If there's markup defined, do markup
        print join("\n", Markup(GetFile($PageDir, $Page)));
      } else {
        print join("\n", GetFile($PageDir, $Page));
      }
    }
    if($ShortPage eq 'RecentChanges') {
      DoRecentChanges;
    }
    if($ShortPage =~ m/^$DiscussPrefix/ and $SiteMode < 2) {
      print DoDiscuss;
    }
  }
  # Footer
  print Interpolate($Footer);
}

## START
&Init;		# Load
&DoRequest;	# Handle the request
&DoVisit;	# Log visitor
&DoMaint;	# Run maintenance commands
1;	# In case we're being called elsewhere

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<title>$SiteName: $PageName</title>
<link rel="alternate" type="application/wiki" title="Edit this page" href="$Url?do=edit&page=$ShortPage" />
<meta name="robots" content="INDEX,FOLLOW" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta name="generator" content="Aneuch $VERSION" />
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
    color: blue; /*#c00;*/
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
  color: #c00; /*blue;*/
}
a.external:hover {
  color:white;
  background-color:red;
}

textarea {
  border-color:black;
  border-style:solid;
  border-width:thin;
  padding: 3px;
  width: 100%;
}

.navbar a {
  padding-right: 1ex;
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
<div class="header">
<span class="navbar">$NavBar</span>
<h1><a title="Search for references to $ShortPage" rel="nofollow" href="$ShortUrl?do=search&page=$ShortPage">$PageName</a></h1></div>
<div class="wrapper">
!!CONTENT!!
</div>
<div class="close"></div>
<div class="footer">
<hr/>
<span class="navbar">$DiscussText
$EditText
$RevisionsText
<a title="Administration options" rel="nofollow" href="$ShortUrl?do=admin&page=admin">Admin</a></span><span style="float:right;"><strong>$SiteName</strong>
is powered by <em>Aneuch</em>.</span>
<span class="time"><br/>
$EditString</span>
$PostFooter
</div>
</body>
</html>
