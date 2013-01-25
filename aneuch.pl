#!/usr/bin/perl
## $Id$
## **********************************************************************
## Copyright (c) 2012-2013, Aaron J. Graves (cajunman4life@gmail.com)
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
#use CGI::Carp qw(fatalsToBrowser);
# Some variables
use vars qw($DataDir $SiteName $Page $ShortPage @Passwords $PageDir $ArchiveDir
$ShortUrl $SiteMode $ScriptName $ShortScriptName $Header $Footer $PluginDir 
$Url $DiscussText $DiscussPrefix $DiscussLink $DefaultPage $CookieName 
$PageName %FORM $TempDir @Messages $command $contents @Plugins $TimeStamp
$PostFooter $TimeZone $VERSION $EditText $RevisionsText $NewPage $NewComment
$NavBar $ConfFile $UserIP $UserName $VisitorLog $LockExpire %Filec $MTime
$RecentChangesLog $Debug $DebugMessages $PageRevision $MaxVisitorLog
%Commands %AdminActions %AdminList $RemoveOldTemp $ArgList $ShortDir
@NavBarPages $BlockedList %PostingActions $HTTPStatus);
my %srvr = (
  80 => 'http://',	443 => 'https://',
);

$VERSION = '0.20';	# Set version number

# Subs
sub InitConfig  {
  $ConfFile = 'config.pl' unless $ConfFile; # Set default unless we get it
  if(-f $ConfFile) {		# File exists
    do $ConfFile;		# Execute the config
  }
}

sub InitVars {
  # We must be the first entry in Plugins
  @Plugins = ("aneuch.pl, version $VERSION, <a href='http://aneuch.myunixhost.com/' target='_blank'>Aneuch Wiki Engine</a>");
  # Define settings
  $DataDir = '/tmp/aneuch' unless $DataDir;	# Location of docs
  #$myd = $ENV{'DOCUMENT_ROOT'} . "/";		# Local location
  $DefaultPage = 'HomePage' unless $DefaultPage; # Default page
  @Passwords = qw() unless @Passwords;		# No password by default
  $SiteMode = 0 unless $SiteMode;		# 0=All, 1=Discus only, 2=None
  $DiscussPrefix = 'Discuss_' unless $DiscussPrefix; # Discussion page prefix
  $SiteName = 'Aneuch' unless $SiteName;	# Default site name
  $CookieName = 'Aneuch' unless $CookieName;	# Default cookie name
  $TimeZone = 0 unless $TimeZone;		# Default to GMT, 1=localtime
  $LockExpire = 60*5 unless $LockExpire;	# 5 mins, unless set elsewhere
  $Debug = 0 unless $Debug;			# Assume no debug
  $MaxVisitorLog = 1000 unless $MaxVisitorLog;	# Keep at most 1000 entries in
						#  visitor log
  $RemoveOldTemp = 60*60*24*7 unless $RemoveOldTemp; # > 7 days

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
  $Page =~ s/&/;/g;		# Replace ampersand with semicolon
  $Page =~ s/\+/ /g;		# Replace + with space...
  $Page =~ s!^/!!;		# Remove leading slash, if it exists
  $Page =~ s/ /_/g;		# Convert spaces to underscore
  $Page =~ s!\.{2,}!!g;		# Remove every instance of double period
  if($Page =~ m/^?do=(.*?)(;page=(.*)|)$/) { # We're getting a command directive
    $command = $1;		# Set the command
    $Page = $3; #if $2;		# Set the page
    if($Page =~ m/^.*?;(.*)$/) { # If there are still arguments...
      $ArgList = (split(/;/,$Page))[1]; # Get them
      $Page = (split(/;/,$Page))[0]; # Set page properly
    }
    $command =~ s/^\?//;	# Get rid of leading '?', if it's there.
  }
  if($Page eq "") { $Page = $DefaultPage };	# Default if blank
  if($Page =~ m/\.(\d+)$/) {	# Page revision being requested?
    $PageRevision = $1;		# Set it.
  }
  $Page =~ s/\.[\w\d]+$//;	# Remove all extensions
  # FIXME: $ShortPage and $Page are now the same... we can get rid of one.
  $ShortPage = $Page;		# ShortPage is Page sans extension
  $ShortPage =~ s/\.[a-z]{3,4}$//; # Remove extension
  $PageName = $ShortPage;	# PageName is ShortPage with spaces
  $PageName =~ s/_/ /g;		# Change underscore to space

  $ShortDir = substr($Page,0,1);	# Get first letter
  $ShortDir =~ tr/[a-z]/[A-Z]/;		# Capitalize it


  # I know we just went through all that crap, but if command=admin, we need:
  if($command and $command eq 'admin') {
    $PageName = 'Admin';
    #$ShortPage = '';
    $Page = '';
  }

  # Discuss links
  if(!$command) { #or $command ne 'admin') {
    if($ShortPage !~ m/^$DiscussPrefix/) {
      $DiscussLink = $ShortUrl . $DiscussPrefix . $ShortPage;
      $DiscussText = $DiscussPrefix;
      $DiscussText =~ s/_/ /g;
      $DiscussText .= $ShortPage;
      $DiscussText = '<a title="'.$DiscussText.'" href="'.$DiscussLink.'">'.
	$DiscussText.'</a>';
    } else {
      $DiscussLink = $ShortPage;
      $DiscussLink =~ s/^$DiscussPrefix//;
      $DiscussText = $DiscussLink;
      $DiscussLink = $ShortUrl . $DiscussLink;
      $DiscussText = '<a title="Return to '.$DiscussText.'" href="'.
	$DiscussLink.'">'.$DiscussText.'</a>';
    }
    if(CanEdit()) {
      $EditText = '<a title="Click to edit this page" rel="nofollow" href="'.
	$ShortUrl.'?do=edit;page='.$ShortPage.'">Edit '.$ShortPage.'</a>';
    } else {
      $EditText = '<a title="Read only page" rel="nofollow" href="'.$ShortUrl.
	'?do=edit;page='.$ShortPage.'">This page is read only</a>';
    }
    $RevisionsText = '<a title="Click here to see revision history" '.
      'rel="nofollow" href="'.$ShortUrl.'?do=history;page='.$ShortPage.
      '">View page history</a>';
  }

  # If we're a command, change the page title
  if($command) {
  #  $PageName = $commandtitle{$command};
    if($command eq 'search') { 
      $ArgList = $PageName;
      $PageName = "Search for: $PageName";
     }
  }

  # Set the TimeStamp
  $TimeStamp = time;

  # New page and new comment default text
  $NewPage = '<p>It appears that there is nothing here.</p>' unless $NewPage;
  $NewComment = 'Add your comment here.' unless $NewComment;

  # Set visitor IP address
  $UserIP = $ENV{'REMOTE_ADDR'};
  ($UserName) = &ReadCookie;
  if(!$UserName) { $UserName = $UserIP; }

  # Navbar
  $NavBar = "<a href='$Url$DefaultPage' title='$DefaultPage'>$DefaultPage</a> ".
    "<a href='".$ShortUrl."RecentChanges' title='RecentChanges'>".
    "RecentChanges</a> ".$NavBar;
  foreach (@NavBarPages) {
    $NavBar .= '<a href="'.$ShortUrl.$_.'" title="'.$_.'">'.$_.'</a> ';
  }

  # For the Admin stuff
  %Commands = (			# This is the list of commands, and their subs
    admin => \&DoAdmin,		edit => \&DoEdit,
    search => \&DoSearch,	history => \&DoHistory,
    random => \&DoRandom,	diff => \&DoDiff,
  );
  %AdminActions = (		# List of admin actions, and their subs
    password => \&DoAdminPassword,	version => \&DoAdminVersion,
    index => \&DoAdminIndex,		reindex => \&DoAdminReIndex,
    rmlocks => \&DoAdminRemoveLocks,	visitors => \&DoAdminListVisitors,
    lock => \&DoAdminLock,		unlock => \&DoAdminUnlock,
    block => \&DoAdminBlock,		clearvisits => \&DoAdminClearVisits,
  );
  %AdminList = (		# For the Admin menu
    version => 'View version information',
    index => 'List all pages',
    reindex => 'Rebuild page index',
    rmlocks => 'Force delete page locks',
    visitors => 'Display visitor log',
    clearvisits => 'Clear visitor log',
    lock => 'Lock the site for editing/discussions',
    unlock => 'Unlock the site',
    block => '(Un)Block users',
  );
  # Posting actions
  %PostingActions = (
    login => \&DoPostingLogin,		editing => \&DoPostingEditing,
    discuss => \&DoPostingDiscuss,	blocklist => \&DoPostingBlockList,
  );
}

sub InitTemplate {
  # If we don't have $Header or $Footer, use the built-in
  if(!defined($Header) and !defined($Footer)) {
    chomp(my @TEMPLATE = <DATA>);	# Read from DATA
    ($Header, $Footer) = split(/!!CONTENT!!/, join("\n", @TEMPLATE));
  }
}

sub Markup {
  # Markup is a cluster. It's so ugly and nasty, but it works. In the future,
  #  this thing will be re-written to be much cleaner.
  my $cont = shift;
  $cont = QuoteHTML($cont);
  my @contents = split("\n", $cont);
  #chomp(my @contents = @_);	# Receive data
  # If nomarkup is requested
  if($contents[0] eq "!! nomarkup") { return @contents; }
  my $step = 0;			# FIXME: not used!?
  my $openul = 0;		# For building <ul>
  my $openol = 0;		# For building <ol>
  my $listlevel = 0;		# List levels
  my @build;			# What will be returned
  foreach my $line (@contents) {
    # Are we doing lists?
    # UL
    if(($line =~ m/^[\s\t]*\*{1,5}[ \t]/) && (! $openul)) {
      $openul=1; push @build, "<ul>";
    }
    if(($openul) && ($line !~ m/^[\s\t]*\*{1,5}[ \t]/)) {
      $openul=0; push @build, "</ul>";
    }
    # OL
    if(($line =~ m/^[\s\t]*#{1,}/) && (! $openol)) {
      $openol=1; push @build, "<ol>";
    }
    if(($openol) && ($line !~ m/^[\s\t]*#{1,}/)) {
      $openol=0; push @build, "</ol>";
    }

    # Get rid of comments
    #$line =~ s/^#//;

    # Forced line breaks
    $line =~ s#\\\\#<br/>#g;

    # Headers
    $line =~ s#^={5}(.*?)(=*)$#<h5>$1</h5>#;
    $line =~ s#^={4}(.*?)(=*)$#<h4>$1</h4>#;
    $line =~ s#^={3}(.*?)(=*)$#<h3>$1</h3>#;
    $line =~ s#^={2}(.*?)(=*)$#<h2>$1</h2>#;
    $line =~ s#^=(.*?)(=*)$#<h1>$1</h1>#;

    # Links
    $line =~ s#\[{2}(htt(p|ps)://.*?)\|(.*?)\]{2}#<a href="$1" class="external" target="_blank" title="External link: $1" rel="nofollow">$3</a>#g;
    $line =~ s#\[{2}(htt(p|ps)://.*?)\]{2}#<a href="$1" class="external" target="_blank" title="External link: $1" rel="nofollow">$1</a>#g;
    $line =~ s#\[{2}(.*?)\|{1}(.*?)\]{2}#<a href="$1" title="$1">$2</a>#g;
    $line =~ s#\[{2}(.*?)\]{2}#<a href="$1" title="$1">$1</a>#g;

    # HR
    $line =~ s#^-{4,}$#<hr/>#;

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

    # Underline
    $line =~ s#_{2}(.*?)_{2}#<span style="text-decoration:underline">$1</span>#g;

    # Add it
    push @build, $line;
  }
  # Do we have anything open?
  #if($openol) { push @build, "</ol>"; }
  push @build, "</ol>" if $openol;
  #if($openul) { push @build, "</ul>"; }
  push @build, "</ul>" if $openul;
  # Ok, now let's do paragraphs.
  my $prevblank = 1;    # Assume true
  my $openp = 0;        # Assume false
  my $i = 0;
  for($i=0;$i<=$#build;$i++) {
    if($prevblank and ($build[$i] !~ m/^<(h|div)/) and ($build[$i] ne '')) {
      $prevblank = 0;
      if(!$openp) {
        $build[$i] = "<p>".$build[$i];
        $openp = 1;
      }
    }
    if(($build[$i] =~ m/^<(h|div)/) || ($build[$i] eq '')) {
      $prevblank = 1;
      if(($i > 0) && ($build[$i-1] !~ m/^<(h|div)/) && ($openp)) {
        $build[$i-1] .= "</p>"; $openp = 0;
      }
    }
  }
  if($openp) { $build[$#build] .= "</p>"; }

  # Output
  #return ("<!-- start of Aneuch markup -->\n", @build, "\n<!-- end of Aneuch markup -->\n");
  return "<!-- start of Aneuch markup -->\n".join("\n",@build)."\n<!-- end of Aneuch markup -->\n";
}

sub Trim {
  # Trim removes all leading and trailing whitespace
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub Interpolate {
  # Interpolate will replace any variables that exist in a string with their
  #  data. This is used for themeing.
  my $work = shift;
  $work =~ s/(\$\w+(?:::)?\w*)/"defined $1 ? $1 : ''"/gee;
  return $work;
}

sub GetFile {
  # GetFile will read the file into a hash, and return it.
  #my ($rt, $file) = @_;	# Get the elements
  my $file = shift;
  my @return;		# This used to be the return data, now it's used to
			#  read in the file.
  my %F;		# This is now the return variable.
  my $currentkey;	# Current key of the hash that we're reading in
  if(-f "$file") { # If the file exists
    open(FH,"$file") or push @Messages, $!; # Push error
    chomp(@return = <FH>);	# Remove \n
    close(FH);
    s/\r//g for @return;
    foreach (@return) {
      if(/^\t/) {
	$F{$currentkey} .= "\n$_";
      } else {
	my $e = index($_, ': ');
	$currentkey = substr($_,0,$e);
        $F{$currentkey} = substr($_,$e+2);
      }
    }
    #$MTime = $F{ts};
    #$MTime = (&FriendlyTime($MTime))[$TimeZone];
    #$F{text} =~ s/\r//g;
    s/\n\t/\n/g for ($F{text}, $F{diff});
    #return @{$Filec{text}}; #@return;
    #return split("\n", $F{text});
    return %F;
  } else {
    return ();
  }
}

sub InitDirs {
  # Sets the directories, and creates them if need be.
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
  $RecentChangesLog = "$DataDir/rc.log";
  $BlockedList = "$DataDir/banned";
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

sub IsAdmin {
  # Figure out if user has admin rights
  my ($u, $p) = ReadCookie();
  if(@Passwords == 0) {		# If no password set...
    return 1;
  }
  return scalar(grep(/^$p$/, @Passwords));
}

sub CanEdit {
  # If lock is set, return false automatically
  if(-f "$DataDir/lock") { return 0; }
  my ($u, $p) = ReadCookie();
  my $matchedpass = grep(/^$p$/, @Passwords);
  if($SiteMode == 0 or $matchedpass > 0) {
    return 1;
  } else {
    return 0;
  }
}

sub CanDiscuss {
  # If lock is set, return false automatically
  if(-f "$DataDir/lock") { return 0; }
  #my ($u, $p) = &ReadCookie;
  if($SiteMode < 2 and $ShortPage =~ m/^$DiscussPrefix/) {
    return 1;
  } else {
    return 0;
  }
}

sub LogRecent {
  my ($file,$un,$mess) = @_;
  # Log for RecentChanges
  my $day; my $time;
  my @rc = ();
  if($TimeZone == 0) {	# GMT
    $day = strftime "%Y%m%d", gmtime($TimeStamp);
    $time = strftime "%H%M%S", gmtime($TimeStamp);
  } else {		# Local
    $day = strftime "%Y%m%d", localtime($TimeStamp);
    $time = strftime "%H%M%S", localtime($TimeStamp);
  }
  if(-f "$RecentChangesLog") {
    open(RCL,"<$RecentChangesLog") or push @Messages, "LogRecent: Unable to read from $RecentChangesLog: $!";
    @rc = <RCL>;
    close(RCL);
  }
  # Remove any old entry...
  @rc = grep(!/^$day(\d{6})\t$file/,@rc);
  # Now update...
  push @rc, "$day$time\t$file\t$un\t$mess\t$TimeStamp\n";
  # Now write it back out...
  open(RCL,">$RecentChangesLog") or push @Messages, "LogRecent: Unable to write to $RecentChangesLog: $!";
  print RCL @rc;
  close(RCL);
}

sub RefreshLock {
  # Refresh a lock on $Page
  if(-f "$TempDir/$Page.lock") {
    open(LOCK,"<$TempDir/$Page.lock") or push @Messages, "Error opening $Page.lock for read: $!";
    my @lock = <LOCK>;
    close(LOCK);
    chomp(@lock);
    if($lock[0] eq $UserIP and $lock[1] eq $UserName) {
      $lock[2] = $TimeStamp;
      open(LOCK,">$TempDir/$Page.lock") or push @Messages, "RefreshLock: Error opening $Page.lock for write: $!";
      print LOCK join("\n", @lock);
      close(LOCK);
      return 1;
    } else { return 0; }
  } else { return 0; }
}

sub DoEdit {
  my $canedit = CanEdit();
  # Let's begin
  my ($contents, $revision);
  my @preview;
  if(-f "$TempDir/$Page.$UserName") {
    #open(PREVIEW,"<$TempDir/$Page.$UserName") or push @Messages, "DoEdit: Unable to read from preview file $Page.$UserName: $!";
    #@preview = <PREVIEW>;
    #close(PREVIEW);
    #s/\r//g for @preview;
    #chomp($revision = $preview[0]); shift @preview;
    #$contents = join("", @preview);
    #$contents = FileToString("$TempDir/$Page.$UserName");
    #$contents =~ s/\r//g;
    @preview = FileToArray("$TempDir/$Page.$UserName");
    s/\r//g for @preview;
    $revision = $preview[0]; shift @preview;
    $contents = join("\n", @preview);
    RefreshLock();
  } else {
    #$contents = join("", &GetFile($PageDir, $Page));
    my %f = GetFile("$PageDir/$Page");
    $contents = $f{text};
    $revision = $f{revision} if defined $f{revision};
    $revision = 0 unless $revision;
  }
  #$contents = QuoteHTML($contents);
  if($canedit) {
    print '<form action="' . $ShortUrl . $ShortScriptName . '" method="post">';
    print '<input type="hidden" name="doing" value="editing">';
    print '<input type="hidden" name="file" value="' . $ShortPage . '">';
    print '<input type="hidden" name="revision" value="'. $revision . '">';
    if(-f "$PageDir/$Page") {
      print '<input type="hidden" name="mtime" value="' . (stat("$PageDir/$Page"))[9] . '">';
    }
  }
  if(@preview) {
    #print "<div class=\"preview\">" . join("\n",Markup(@preview)) . "</div>";
    print "<div class=\"preview\">" . Markup($contents) . "</div>";
  }
  print '<textarea name="text" cols="100" rows="25">' . QuoteHTML($contents) . '</textarea>';
  if($canedit) {
    # Set a lock
    if(@preview or SetLock()) {
      print 'Summary: <input type="text" name="summary" size="60" />';
      print ' User name: <input type="text" name="uname" size="12" value="'.$UserName.'" /> ';
      print '<input type="submit" name="whattodo" value="Save" /> ';
      print '<input type="submit" name="whattodo" value="Preview" /> ';
      print '<input type="submit" name="whattodo" value="Cancel" />';
    }
    print '</form>';
  }
  #print '<p><a href="' . $ShortUrl . $ShortPage . '">Return</a></p>';
}

sub SetLock {
  if(-f "$TempDir/$Page.lock" and ((stat("$TempDir/$Page.lock"))[9] <= ($TimeStamp - $LockExpire))) {
    UnLock();
  }
  # Set a lock on $Page
  if(-f "$TempDir/$Page.lock") {
    open(LOCK,"<$TempDir/$Page.lock") or push @Messages, "Error opening $Page.lock for read: $!";
    my @lock = <LOCK>;
    close(LOCK);
    chomp(@lock);
    print "<p><span style='color:red'>This file is locked by <strong>$lock[0] ($lock[1])</strong> since <strong>" . (FriendlyTime($lock[2]))[$TimeZone] . "</strong>.</span>";
    print "<br/>Lock should expire by " . (FriendlyTime($lock[2] + $LockExpire))[$TimeZone] . ", and it is now " . (FriendlyTime())[$TimeZone] . ".</p>";
    return 0;
  } else {
    open(LOCK,">$TempDir/$Page.lock") or push @Messages, "Error opening $Page.lock for write: $!";
    print LOCK "$UserIP\n$UserName\n$TimeStamp";
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
  #if($pg =~ m/^$DiscussPrefix/) { return; }	# Don't index Discussion pages
  open(INDEX,"<$DataDir/pageindex") or push @Messages, "Index: Unable to open pageindex for read: $!";
  my @pagelist = <INDEX>;
  close(INDEX);
  if(!grep(/^$pg$/,@pagelist)) {
    open(INDEX,">>$DataDir/pageindex") or push @Messages, "Index: Unable to open pageindex for append: $!";
    print INDEX "$pg\n";
    close(INDEX);
  }
}

sub DoArchive {
  my $file = shift;	# The file we're working on
  if(!-f "$PageDir/$file") { return; }
  # $archive will be the 1-letter dir under /archive that we're writing to
  my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  # If $archive doesn't exist, we'd better create it...
  if(! -d "$ArchiveDir/$archive") { mkdir "$ArchiveDir/$archive"; }
  my %F = GetFile("$PageDir/$file");
  # Now copy...
  system("cp $PageDir/$file $ArchiveDir/$archive/$file.$F{revision}");
  #system("gzip $ArchiveDir/$archive/$file.$TimeStamp");
}

sub WriteFile {
  my ($file, $content, $user) = @_;
  if(-f "$TempDir/$file.$UserName") {	# Remove preview files
    unlink "$TempDir/$file.$UserName";
  }
  DoArchive($file);
  $content =~ s/\r//g;
  StringToFile($content, "$TempDir/new");
  $content =~ s/\n/\n\t/g;
  my %T = GetFile("$PageDir/$file");
  StringToFile($T{text}, "$TempDir/old");
  my $diff = `diff $TempDir/old $TempDir/new`;
  $diff =~ s/\\ No newline.*\n//g;
  $diff =~ s/\r//g;
  $diff =~ s/\n/\n\t/g;
  my %F;
  # Build file information
  #@{$Filec{summary}} = ($FORM{summary});
  $F{summary} = $FORM{summary};
  #@{$Filec{ip}} = ($UserIP);
  $F{ip} = $UserIP;
  #@{$Filec{author}} = $user; #($FORM{uname}) or ($UserName);
  $F{author} = $user;
  #@{$Filec{ts}} = ($TimeStamp);
  $F{ts} = $TimeStamp;
  #@{$Filec{text}} = split(/\n/,$content);
  $F{text} = $content;
  $F{revision} = $FORM{revision} + 1;
  $F{diff} = $diff;
  open(FILE, ">$PageDir/$file") or push @Messages, "Unable to write to $file: $!";
  #print FILE $content;
  #foreach my $key (sort keys %Filec) {
  foreach my $key (keys %F) {
    print FILE "$key: " . $F{$key} . "\n";
    #foreach my $c (@{$Filec{$key}}) {
    #  print FILE "  $c\n";
    #}
  }
  close(FILE);
  UnLock($file);
  Index($file);
  LogRecent($file,$user,$FORM{summary});
}

sub AppendFile {
  my ($file, $content, $user, $url) = @_;
  DoArchive($file);				# Keep history
  my $sig;
  $content =~ s/\r//g;
  $content =~ s/\n/\n\t/g;
  my %F; my %T;
  $F{summary} = $content; #("Comment by $user");
  $F{ip} = $UserIP;
  $F{author} = $user;
  $F{ts} = $TimeStamp;
  #@{$F{text}} = ();
  #chomp(@{$F{text}} = GetFile($PageDir, $file));
  if(-f "$PageDir/$file") {
    %T = GetFile("$PageDir/$file");
  } else {
    $T{revision} = 0;
    $T{text} = '';
  }
  #$T{text} =~ s/\r//g;
  #$T{text} =! s/\n/\n\t/g;
  $F{revision} = $T{revision} + 1;
  $F{text} = $T{text} . "\n" . $content . "\n\n";
  #push @{$F{text}}, split(/\n/,$content);
  #push @{$F{text}}, "\n";
  if(!$url) {
    $url = $user;
  }
  $sig = '- [['.$url.'|'.$user.']] //'.
  (FriendlyTime($TimeStamp))[$TimeZone] . "// ($UserIP)";
  #} else {
  #  $sig = $user.' //' . (&FriendlyTime($TimeStamp))[$TimeZone] . "//";
  #}
  #push @{$F{text}}, ($sig, "____\n");
  $F{text} .= "$sig\n----\n";
  $F{text} =~ s/\r//g;
  StringToFile($T{text}, "$TempDir/old");
  StringToFile($F{text}, "$TempDir/new");
  my $diff = `diff $TempDir/old $TempDir/new`;
  $diff =~ s/\\ No newline.*\n//g;
  $F{diff} = $diff;
  s/\n/\n\t/g for ($F{text}, $F{diff});
  open(FILE, ">$PageDir/$file") or push @Messages, "AppendFile: Unable to append to $file: $!";
  foreach my $key (sort keys %F) {
    print FILE "$key: " . $F{$key} . "\n";
    #foreach my $c (@{$F{$key}}) {
    #  print FILE "  $c\n";
    #}
  }
  close(FILE);
  LogRecent($file,$user,"Comment by $user");
  Index();
}

sub ListAllPages {
  my @files = (glob("$PageDir/*"));
  s#^$PageDir/## for @files;
  @files = sort(@files);
  return @files;
}

sub AdminForm {
  my ($u,$p) = ReadCookie();
  print '<form action="' . $ShortUrl . $ShortScriptName . '" method="post">';
  print '<input type="hidden" name="doing" value="login" />';
  print 'User: <input type="text" maxlength="30" size="8" name="user" value="'.
  $u.'" />';
  print ' Pass: <input type="password" size="12" name="pass" />';
  print '<input type="submit" value="Go" /></form>';
}

sub DoAdminPassword {
  my ($u,$p) = ReadCookie();
  if(!$u) {
    print "<p>Presently, you do not have a user name set.</p>";
  } else {
    print "<p>Your user name is set to '$u'.</p>";
  }
  AdminForm();
}

sub DoAdminVersion {
  # Display the version information of every plugin listed
  print '<p>Versions used on this site:</p>';
  foreach my $c (@Plugins) {
    print "<p>$c</p>\n";
  }
}

sub DoAdminIndex {
  my @indx = FileToArray("$DataDir/pageindex");
  #open(INDEX,"<$DataDir/pageindex") or push @Messages, "Admin.index: Unable to read from pageindex: $!";
  #@indx = <INDEX>;
  #close(INDEX);
  @indx = sort(@indx);
  print '<p>Note: This displays what is in the page index file. If results '.
    'are inaccurate, please run the "Rebuild page index" task from the '.
    'Admin panel.</p>';
  print "<h3>" . @indx . " pages found.</h3><p>";
  foreach my $pg (@indx) {
    print "<a href=\"$ShortUrl$pg\">$pg</a><br/>";
  }
  print "</p>";
}

sub DoAdminReIndex {
  # Re-index the site
  my @files = ListAllPages();
  #open(INDEX,">$DataDir/pageindex") or push @Messages, "Admin.reindex: Unable to write to pageindex: $!";
  #print INDEX join("\n",@files) . "\n";
  #close(INDEX);
  StringToFile(join("\n",@files)."\n","$DataDir/pageindex");
  print "<p>Reindex complete. Check page index.</p>";
}

sub DoAdminRemoveLocks {
  # Force remove all locks...
  my @files = glob("$TempDir/*.lock");
  foreach (@files) {
    unlink $_;
  }
  s!^$TempDir/!! for @files;
  print "Removed the following locks:<br/>".join("<br/>",@files);
}

sub DoAdminClearVisits {
  open(LOGFILE,">$VisitorLog") or push @Messages, "DoAdminClearVisits: Unable to open $VisitorLog: $!";
  print LOGFILE "";
  close(LOGFILE);
  print "Log file successfully cleared.";
}

sub DoAdminListVisitors {
  # Display the visitors.log file
  open(LOGFILE,"<$VisitorLog") or push @Messages, "DoAdminListVisitors: Unable to open $VisitorLog: $!";
  my @lf = <LOGFILE>;
  close(LOGFILE);
  @lf = reverse(@lf);	# Most recent entries are on bottom... fix that.
  chomp(@lf);
  my $curdate;
  my @IPs;
  print "<h2>Visitor log entries (newest to oldest, ".@lf." entries)</h2><p>";
  foreach my $entry (@lf) {
    my @e = split(/\t/, $entry);
    my $date = YMD($e[1]);
    my $time = HMS($e[1]);
    if($curdate ne $date) { print "</p><h2>$date</h2><p>"; $curdate = $date; }
    print "$time, user <strong>";
    print QuoteHTML($e[0])."</strong> (<strong>".QuoteHTML($e[3])."</strong>)";
    #if(@e == 4) { print " (logged in as <strong>".$e[3]."</strong>)"; }
    my @p = split(/\s+/,$e[2]);
    if(@p == 2) {
      if($p[1] eq "(edit)") {
	print " was editing <strong>".QuoteHTML($p[0])."</strong>";
      } elsif($p[1] eq "(history)") {
	print " was viewing the history of <strong>".QuoteHTML($p[0]).
	  "</strong>";
      } elsif($p[1] eq "(search)") {
	print " was searching for <strong>&quot;".QuoteHTML($p[0]).
	  "&quot;</strong>";
      } elsif($p[1] eq "(diff)") {
	print " was viewing differences on <strong>".QuoteHTML($p[0]).
	  "</strong>";
      } elsif($p[1] eq "(admin)") {
	print " was in Administrative mode, doing <strong>".QuoteHTML($p[0]).
	  "</strong>";
      } elsif($p[1] eq "(random)") {
	print " was redirected to a random page from <strong>".QuoteHTML($p[0]).
	  "</strong>";
      } else {
	my $tv = $p[1];
	$tv =~ s/\(//;
	$tv =~ s/\)//;
	print " hit page <strong>".QuoteHTML($p[0])."</strong> (error ".
	  QuoteHTML($tv).")";
      }
    } else { print " hit page <strong>".QuoteHTML($p[0])."</strong>"; }
    #if(@p == 2) { print ' and was doing "'.$p[1].'"'; }
    print "<br/>";
    if(!grep(/^$e[0]$/,@IPs)) { push @IPs, $e[0]; }
  }
  print "</p>";
  print "<div class=\"toc\"><strong>IPs:</strong><br/>";
  foreach my $entry (sort @IPs) {
    print "$entry<br/>";
  }
  print "</div>";
}

sub DoAdminLock {
  if(!-f "$DataDir/lock") {
    open(LOCKFILE,">$DataDir/lock") or push @Messages, "DoAdminLock: Unable to write to lock: $!";
    print LOCKFILE "";
    close(LOCKFILE);
    print "Site is locked.";
  } else {
    print "Site is already locked!";
  }
}

sub DoAdminUnlock {
  if(-f "$DataDir/lock") {
    unlink "$DataDir/lock";
    print "Site has been unlocked.";
  } else {
    print "Site is already unlocked!";
  }
}

sub DoAdminBlock {
  #my @blocked = FileToArray($BlockedList);
  my $blocked = FileToString($BlockedList);
  my @bl = split(/\n/,$blocked);
  print scalar @bl." user(s) blocked. Add an IP address, one per line, that ".
    "you wish to block.<br/>";
  print "<form action='$ShortUrl$ShortScriptName' method='post'>".
    "<input type='hidden' name='doing' value='blocklist' />".
    "<textarea name='blocklist' rows='25' cols='100'>".$blocked.
    "</textarea><input type='submit' value='Save' /></form>";
}

sub DoAdmin {
  #my ($u,$p) = &ReadCookie;
  # Command? And can we run it?
  if($ShortPage and $AdminActions{$ShortPage}) {
    if($ShortPage eq 'password' or IsAdmin()) {
      &{$AdminActions{$ShortPage}};			# Execute it.
    }
  } else {
    print '<p>You may:<ul><li><a href="'.$ShortUrl.
    '?do=admin;page=password">Authenticate</a></li>';
    #if($p) {
    if(IsAdmin()) {
      foreach my $listitem (keys %AdminList) {
	print '<li><a href="'.$ShortUrl.'?do=admin;page='.$listitem.
	'">'.$AdminList{$listitem}.'</a></li>';
      }
    }
    print '</ul></p>';
    print '<p>This site has ' . scalar(ListAllPages()) . ' pages.</p>';
  }
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
  InitConfig();
  InitVars();
  InitDirs();
  LoadPlugins();
  InitTemplate();
}

sub DoDiscuss {
  # So that plugins can modify the DoDiscuss action without having to totally
  # re-write it, the decision was made that instead of DoDiscuss printing
  # output directly, it should return an array.
  my @returndiscuss = ();
  if(!CanDiscuss()) {
    return @returndiscuss;
  }
  push @returndiscuss, "<form action='$ShortUrl$ShortScriptName' method='post'>";
  push @returndiscuss, "<input type='hidden' name='doing' value='discuss' />";
  push @returndiscuss, "<input type='hidden' name='file' value='$ShortPage' />";
  push @returndiscuss, "<textarea name='text' cols='80' rows='5'>$NewComment</textarea>";
  push @returndiscuss, "Name: <input type='text' name='uname' width='12' value='$UserName' /> ";
  push @returndiscuss, "URL (optional): <input type='text' name='url' width='12' />";
  push @returndiscuss, "<input type='submit' value='Save' />";
  push @returndiscuss, "</form>";
  return @returndiscuss;
}

sub DoRecentChanges {
  print "<hr/>";
  my @rc;
  my $curdate;
  my $tz;
  my $openul=0;
  open(RCF,"<$RecentChangesLog") or push @Messages, "DoRecentChanges: Unable to read $RecentChangesLog: $!";
  @rc = <RCF>;
  close(RCF);
  chomp(@rc);
  if($TimeZone == 0) {
    $tz = "UTC";
  } else {
    $tz = strftime "%Z", localtime(time);
  }
  # Sort them
  @rc = sort { $b <=> $a } (@rc);
  # Now show them...
  foreach my $entry (@rc) {
    my @ent = split(/\t/,$entry);
    my $day = $ent[0];
    $day =~ s#^(\d{4})(\d{2})(\d{2})\d{6}$#$1/$2/$3#;
    my $tme = $ent[0];
    $tme =~ s#^\d{8}(\d{2})(\d{2})\d{2}$#$1:$2#;
    if($curdate ne $day) { 
      $curdate = $day;
      if($openul) { print "</ul>"; }
      print "<h3>$day</h3><ul>";
      $openul = 1;
    }
    print "<li>$tme $tz (<a href='$ShortUrl?do=diff;page=$ent[1]".
      "'>diff</a>, ".
      "<a href='$ShortUrl?do=history;page=$ent[1]".
      "'>history</a>) ";
    print "<a href='$ShortUrl$ent[1]'>$ent[1]</a> . . . . $ent[2]<br/>".
    QuoteHTML($ent[3])."</li>";
  }
}

sub DoSearch {
  # First, get a list of all files...
  my @files = (glob("$PageDir/*"));
  # Sort by modification time, newest first
  @files = sort {(stat($b))[9] <=> (stat($a))[9]} @files;
  my $search = $ArgList; #$ShortPage;
  #my $result;
  my %result;
  print "<p>Search results for &quot;$ArgList&quot;</p>";
  foreach my $file (@files) {
    my $fn = $file;
    my $linkedtopage;
    my $matchcount;
    $fn =~ s#^$PageDir/##;
    my %F = GetFile($file);
    if($fn =~ m/.*?$search.*?/i) {
      $linkedtopage = 1;
      $result{$fn} = '<small>Last modified '.
	(FriendlyTime($F{ts}))[$TimeZone]."</small><br/>";
    }
    while($F{text} =~ m/(.{0,25}$search.{0,25})/gsix) {
      if(!$linkedtopage) {
	#$result.="<br/><br/><a href='$ShortUrl$fn'>$fn</a> <small>last updated";
	#$result.=" ".(FriendlyTime($F{ts}))[$TimeZone]."</small><br/> . . . ";
	$linkedtopage = 1;
	$result{$fn} = '<small>Last modified '.
	  (FriendlyTime($F{ts}))[$TimeZone]."</small><br/>";
      }
      if($matchcount == 0) { $result{$fn} .= " . . . "; }
      my $res = QuoteHTML($1); 
      $res =~ s#(.*?)($search)(.*?)#$1<strong>$2</strong>$3#gsix;
      #$result .= "$res . . . ";
      $result{$fn} .= "$res . . . ";
      $matchcount++;
    }
  }
  # Now sort them by value...
  my @keys = sort {length $result{$b} <=> length $result{$a}} keys %result;
  foreach my $key (@keys) {
    print "<a href='$ShortUrl$key'>$key</a><br/>".
      $result{$key}."<br/><br/>";
  }
  #print $result . "<br/><br/><br/>";
}

sub SearchForm {
  my $ret;
  $ret = "<form action='$ScriptName' method='get'>";
  $ret .= "<input type='hidden' name='do' value='search' />";
  $ret .= "<input type='text' name='page' size='40' />";
  $ret .= " <input type='submit' value='Search' /></form>";
  return $ret;
}

sub YMD {
  # Takes timestamp, and returns YYYY/MM/DD
  my $time = shift;
  if($TimeZone == 0) {	# GMT
    return strftime "%Y/%m/%d", gmtime($time);
  } else {		# Local
    return strftime "%Y/%m/%d", localtime($time);
  }
}

sub HM {
  # Takes timestamp, and returns HH:MM
  my $time = shift;
  if($TimeZone == 0) {	# GMT
    return strftime "%H:%M UTC", gmtime($time);
  } else {		# Local
    return strftime "%H:%M %Z", localtime($time);
  }
}

sub HMS {
  # Takes timestamp, and returns HH:MM:SS
  my $time = shift;
  if($TimeZone == 0) {	# GME
    return strftime "%H:%M:%S UTC", gmtime($time);
  } else {
    return strftime "%H:%M:%S %Z", localtime($time);
  }
}

sub QuoteHTML {
  # Escape html characters
  my $html = shift;
  $html =~ s/&/&amp;/g;	# Found on the hard way, this must go first.
  $html =~ s/</&lt;/g;
  $html =~ s/>/&gt;/g;
  return $html;
}

sub DoHistory {
  #my $shortdir = substr($Page,0,1);   # Get first letter
  #$shortdir =~ tr/[a-z]/[A-Z]/;       # Capital
  my $author; my $summary; my %f;
  if(-f "$PageDir/$Page") {
    %f = GetFile("$PageDir/$Page");
    my $currentday = YMD($f{ts});
    print "<h3>$currentday</h3>";
    print "<p>" . HM($f{ts}) . " ".
    "<a href=\"$ShortUrl$Page\">Revision " . $f{revision} . " (current)</a>";
    if($f{revision} > 1) {
      print " (<a href='$ShortUrl?do=diff;page=$Page'>diff</a>)";
    }
    print " . . . . " . QuoteHTML($f{author});
    print " &ndash; <strong>" . QuoteHTML($f{summary});
    print "</strong><br/>";

    if($ArchiveDir and $ShortDir and -d "$ArchiveDir/$ShortDir") {
      my @history = (glob("$ArchiveDir/$ShortDir/$Page.*"));
      @history = reverse(@history);
      #my $revision = @history + 1;
      foreach my $c (@history) {
	%f = GetFile($c);
	my $nextrev;
        my $day = YMD($f{ts});
        if($day ne $currentday) {
	  $currentday = $day;
	  print "</p><h3>$day</h3><p>";
	}
	if($f{revision} == 1) {
	  $nextrev = '';
	} else {
	  $nextrev = ''.($f{revision} - 1).'.'.$f{revision};
	}
	print HM($f{ts})." <a href=\"$ShortUrl$Page.$f{revision}\"> Revision ".
          $f{revision}."</a>";
	if($nextrev) {
 	  print " (<a href='$ShortUrl?do=diff;page=$Page;rev=$nextrev'>".
	    "diff</a>)";
	}
        print " . . . . $f{author}";
        print " &ndash; <strong>" . QuoteHTML($f{summary});
        print "</strong><br/>";
      }
    }
    print "</p>";
  } else {
    print "<p>This page does not appear to have a history. How strange.</p>";
  }
}

sub FriendlyTime {
  my ($rcvd) = @_ if @_ >= 0;
  # FriendlyTime gives us a human readable time rather than num of seconds
  $TimeStamp = time() unless $TimeStamp;	# If it wasn't set before...
  my $tv = $TimeStamp;
  $tv = $rcvd if $rcvd;
  my $localtime = strftime "%a %b %e %H:%M:%S %Z %Y", localtime($tv);
  my $gmtime = strftime "%a %b %e %H:%M:%S UTC %Y", gmtime($tv);
  # Send them back in an array... GMT first, local second.
  return ($gmtime, $localtime);
}

sub Preview {
  # Preview will show us what changes would look like
  my $file = shift;
  # First off, we need to save a temp file...
  my $tempfile = $ShortPage.".".$UserName;
  # Save contents to temp file
  #open(TEMPFILE, ">$TempDir/$tempfile") or push @Messages, "Preview: Unable to write to temp file: $!";
  #print TEMPFILE $FORM{'revision'}."\n".$FORM{'text'};
  #close(TEMPFILE);
  StringToFile($FORM{'revision'}."\n".$FORM{'text'}, "$TempDir/$tempfile");
}

sub ReDirect {
  my $loc = shift;
  print "Location: $loc\n\n";
}

sub DoPostingLogin {
  SetCookie();
  ReDirect($Url.$FORM{'file'});
}

sub DoPostingEditing {
  my $redir;
  if(CanEdit()) {
    if($FORM{'whattodo'} eq "Cancel") {
      UnLock($FORM{'file'});
      my @tfiles = (glob("$TempDir/".$FORM{'file'}.".*"));
      foreach my $file (@tfiles) { unlink $file; }
    } elsif($FORM{'whattodo'} eq "Preview") {
      Preview($FORM{'file'});
      $redir = 1;
    } else {
      WriteFile($FORM{'file'}, $FORM{'text'}, $FORM{'uname'});
    }
  }
  if($redir) {
    ReDirect($Url."?do=edit;page=".$FORM{'file'});
  } else {
    ReDirect($Url.$FORM{'file'});
  }
}

sub DoPostingDiscuss {
  if(CanDiscuss()) {
    AppendFile($FORM{'file'}, $FORM{'text'}, $FORM{'uname'}, $FORM{'url'});
  }
  ReDirect($Url.$FORM{'file'});
}

sub DoPostingBlockList {
  if(IsAdmin()) {
    StringToFile($FORM{'blocklist'},$BlockedList);
  }
  ReDirect($Url."?do=admin;page=block");
}

sub DoPosting {
  my $action = $FORM{doing};
  #my ($action) = @_ if @_ >= 0;
  #my $action = shift;
  #return unless $action;
  $ShortPage = $FORM{'file'};
  #my $redir = 1;
  #if($action eq 'login') {
  #  SetCookie();
  #}
  #if(($action eq 'editing') and CanEdit()) {
  #  if($FORM{'whattodo'} eq "Cancel") {
  #    UnLock($FORM{'file'});
  #    my @tfiles = (glob("$TempDir/".$FORM{'file'}.".*"));
  #    foreach my $file (@tfiles) { unlink $file; }
  #  } elsif($FORM{'whattodo'} eq "Preview") {
  #    Preview($FORM{'file'});
  #    $redir = 0;
  #  } else {
  #    WriteFile($FORM{'file'}, $FORM{'text'}, $FORM{'uname'});
  #  }
  #}
  #if(($action eq 'discuss') and CanDiscuss()) {
  #  AppendFile($FORM{'file'}, $FORM{'text'}, $FORM{'uname'}, $FORM{'url'});
  #}
  #if($redir) {
  #  print "Location: ".$Url.$FORM{'file'}."\n\n";
  #} else {
  #  print "Location: ".$Url."?do=edit;page=".$FORM{'file'}."\n\n";
  #}
  if($action and $PostingActions{$action}) {	# Does it exist?
    &{$PostingActions{$action}};		# Run it
  }
}

sub DoVisit {
  # Log a visit to the visitor log
  my $logentry = "$UserIP\t$TimeStamp\t$ShortPage";
  if($PageRevision) { $logentry .= ".$PageRevision"; }
  if($command) { $logentry .= " ($command)"; }
  if($HTTPStatus) { 
    chomp(my $tv = $HTTPStatus);
    $tv =~ s/Status: //;
    $tv = (split(/ /,$tv))[0];
    $logentry .= " ($tv)";
  }
  $logentry .= "\t$UserName";
  my @rc;
  open(LOGFILE,"<$VisitorLog");
  @rc = <LOGFILE>;
  close(LOGFILE);
  push @rc, "$logentry\n";
  #if($#rc + 1 >= $MaxVisitorLog) {
  #until $#rc <= ($MaxVisitorLog - 1) shift @rc;
  while(@rc > $MaxVisitorLog) {
    shift @rc;
  }
  #open(LOGFILE,">>$VisitorLog");
  open(LOGFILE,">$VisitorLog");
  #print LOGFILE "$logentry\n";
  print LOGFILE join("",@rc);
  close(LOGFILE);
  #system("tail -n $MaxVisitorLog $VisitorLog > $VisitorLog");
}

sub DoMaint {
  # Remove files from temp older than $RemoveOldTemp
  # First, get all files
  my @filelist = (glob("$TempDir/*"));
  # Next, find out when the cutoff is
  my $cutoff = $TimeStamp - $RemoveOldTemp;
  # Finally, walk though the file list and remove
  foreach my $file (@filelist) {
    if((stat($file))[9] <= $cutoff) {
      unlink $file;
    }
  }
}

sub StringToFile {
  my ($string, $file) = @_;
  open(FILE,">$file") or push @Messages, "StringToFile: Can't write to $file: $!";
  print FILE $string;
  close(FILE);
}

sub FileToString {
  my $file = shift;
  my @return;
  open(FILE,"<$file") or push @Messages, "FileToString: Can't read from $file: $!";
  @return = <FILE>;
  close(FILE);
  s/\r//g for @return;
  return join("",@return);
}

sub FileToArray {
  my $file = shift;
  my @return;
  open(FILE,"<$file") or push @Messages, "FileTOArray: Can't read from $file: $!";
  chomp(@return = <FILE>);
  close(FILE);
  s/\r//g for @return;
  return @return;
}

sub GetDiff {
  my ($old, $new) = @_;
  #my $shortdir = substr($old,0,1); $shortdir =~ tr/[a-z]/[A-Z]/;
  my %OldFile = GetFile("$ArchiveDir/$ShortDir/$old");
  my %NewFile;
  if($new =~ m/\.\d+$/) {
    %NewFile = GetFile("$ArchiveDir/$ShortDir/$new");
  } else {
    %NewFile = GetFile("$PageDir/$new");
  }
  # Write them out
  StringToFile($OldFile{text}, "$TempDir/old");
  StringToFile($NewFile{text}, "$TempDir/new");
  my $diff = `diff $TempDir/old $TempDir/new`;
  $diff =~ s/\\ No newline.*\n//g;
  return $diff;
}

sub HTMLDiff {
  my $diff = shift;
  my @blocks = split(/^(\d+,?\d*[dca]\d+,?\d*\n)/m, $diff);
  my $return = "<div class='diff'>";
  shift @blocks;
  while($#blocks > 0) {
    my $h = shift @blocks;
    $h =~ s#^(\d+.*d.*)#<p><strong>Deleted:</strong></p>#
	or $h =~ s#^(\d+.*c.*)#<p><strong>Changed:</strong></p>#
	or $h =~ s#^(\d+.*a.*)#<p><strong>Added:</strong></p>#;
    $return .= $h;
    my $next = shift @blocks;
    $next = QuoteHTML($next);
    my ($o, $n) = split(/\n---\n/,$next,2);
    s#\n#<br/>#g for ($o,$n);
    if($o and $n) {
      $return .= "<div class='old'>$o</div><p><strong>to</strong></p>\n".
	"<div class='new'>$n</div><hr/>";
    } else {
      if($h =~ m/Added:/) {
	$return .= "<div class='new'>";
      } else {
	$return .= "<div class='old'>";
      }
      $return .= "$o</div><hr/>";
    }
  }
  $return .= "</div>";
  return $return;
}

sub DoDiff {
  #my $ShortDir = substr($ShortPage,0,1); $shortdir =~ tr/[a-z]/[A-Z]/;
  # If there are no more arguments, assume we want most recent diff
  if(!$ArgList) {
    my %F = GetFile("$PageDir/$ShortPage");
    #return $F{diff};
    print HTMLDiff($F{diff});
    print "<hr/>";
    if(defined &Markup) {
      print Markup($F{text});
    } else {
      print $F{text};
    }
  } else {
    if($ArgList =~ m/^rev=(\d+)($|\.?(\d+))/) {
      my %F;
      my $oldrev = "$ShortPage.$1"; #"$ArchiveDir/$shortdir/$ShortPage.$1";
      my $newrev = $3 ? "$ShortPage.$3" : "$ShortPage";
      print "<p>Comparing revision $1 to " . ($3 ? $3 : "current") . "</p>";
      print HTMLDiff(GetDiff($oldrev, $newrev));
      print "<hr/>";
      if($newrev =~ m/\.\d+$/) {
	%F = GetFile("$ArchiveDir/$ShortDir/$newrev");
      } else {
	%F = GetFile("$PageDir/$newrev");
      }
      if(defined &Markup) {
	print Markup($F{text});
      } else {
	print $F{text};
      }
    }
  }
}

sub DoRandom {
  my @files = ListAllPages();
  my $count = @files;
  my $randompage = int(rand($count));
  print '<script language="javascript" type="text/javascript">'.
    'window.location.href="'.$files[$randompage].'"; </script>';
}

sub IsBlocked {
  if(!-f $BlockedList) { return 0; }
  chomp(my @blocked = FileToArray($BlockedList));
  if(grep(/^$UserIP$/,@blocked)) {
    return 1;
  } else {
    return 0;
  }
}

sub DoRequest {
  # Blocked?
  if(IsBlocked()) {
    $HTTPStatus = "Status: 403 Forbidden\n";
    print $HTTPStatus . "Content-type: text/html\n\n";
    print '<html><head><title>403 Forbidden</title></head><body>'.
      "<h1>Forbidden</h1><p>You've been banned. Please don't come back.</p>".
      "</body></html>";
    return;
  }

  # Are we receiving something?
  if(ReadIn()) {
    DoPosting();
    return;
  }

  # Check if page exists or not, and not calling a command
  if(! -f "$PageDir/$Page" and !$command and !$Commands{$command}) {
    $HTTPStatus = "Status: 404 Not Found\n";
  }

  # HTTP Header
  print $HTTPStatus . "Content-type: text/html\n\n";

  # Header
  print Interpolate($Header);
  # This is where the magic happens
  if($command and $Commands{$command}) {	# Command directive?
    &{$Commands{$command}};			# Execute it.
  } else {
    if(! -f "$PageDir/$Page") {		# Doesn't exist!
      print $NewPage;
    } else {
      if($PageRevision) {	# We're doing a previous page...
        #my $shortdir = substr($Page,0,1);   # Get first letter
        #$shortdir =~ tr/[a-z]/[A-Z]/;       # Capital
	#my @rc = (glob("$ArchiveDir/$shortdir/$Page.*"));
	#@rc = reverse(@rc);
	#print "<h1>Revision $PageRevision</h1>\n<a href=\"".
        #"$ShortUrl$ShortPage\">view current</a><hr/>\n";
        #my $ptg = $rc[$PageRevision-1];
	#$ptg =~ s#^$ArchiveDir/$shortdir/##;
	#%Filec = GetFile("$ArchiveDir/$shortdir", $ptg);
	%Filec = GetFile("$ArchiveDir/$ShortDir/$ShortPage.$PageRevision");
	print "<h1>Revision $Filec{revision}</h1>\n<a href=\"".
	"$ShortUrl$ShortPage\">view current</a><hr/>\n";
	if(exists &Markup) {
	  #print join("\n", Markup(GetFile("$ArchiveDir/$shortdir", $ptg)));
	  print Markup($Filec{text});
	} else {
	  #print join("\n", GetFile("$ArchiveDir/$shortdir", $ptg));
	  print join("\n", $Filec{text});
	}
      } else {
	%Filec = GetFile("$PageDir/$Page");
        if(exists &Markup) {	# If there's markup defined, do markup
          #print join("\n", Markup(GetFile($PageDir, $Page)));
	  print Markup($Filec{text});
        } else {
          #print join("\n", GetFile($PageDir, $Page));
	  print join("\n", $Filec{text});
        }
      }
    }
    #if($MTime) {
    if($Filec{ts}) {
      $MTime = "Last modified: ".(FriendlyTime($Filec{ts}))[$TimeZone]." by ".
	$Filec{author} . "<br/>";
    }
    if($ShortPage eq 'RecentChanges') {
      DoRecentChanges();
    }
    if($ShortPage =~ m/^$DiscussPrefix/ and $SiteMode < 2) {
      print DoDiscuss();
    }
  }
  $MTime .= SearchForm();
  if($Debug) {
    $DebugMessages = join("<br/>", @Messages);
  }
  # Footer
  print Interpolate($Footer);
}

## START
Init();		# Load
DoRequest();	# Handle the request
DoVisit();	# Log visitor
DoMaint();	# Run maintenance commands
1;		# In case we're being called elsewhere

# Everything below the DATA line is the default "theme"

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<title>$SiteName: $PageName</title>
<link rel="alternate" type="application/wiki" title="Edit this page" href="$Url?do=edit;page=$ShortPage" />
<meta name="robots" content="INDEX,FOLLOW" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta name="generator" content="Aneuch $VERSION" />
<style type="text/css">
body {
    background:#fff;
    padding:1% 3%;
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

.mtime {
  font-size:0.8em;
  color:gray;
}

.mtime form {
  padding-top: 10px;
}

div.wrapper img {
  padding:5px;
  margin:10px;
  border:1px solid rgb(221,221,221);
  background-color: rgb(243,243,243);
  border-radius: 3px 3px 3px 3px;
}

h1.hr, h2.hr, h3.hr, h4.hr, h5.hr {
  border-bottom: 2px solid rgb(0,0,0);
}

.toc {
  /*float:right;*/
  background-color: rgb(243,243,243);
  padding:5px;
  margin:10px;
  border: 1px solid rgb(221,221,221);
  border-radius: 3px 3px 3px 3px;
  /*font-size:0.9em;*/
  position:absolute;
  top:0;
  right:0;
}

.wrapper {
  position: relative;
}

.preview {
  margin: 10px;
  padding: 5px;
  border: 1px solid rgb(221,221,221);
  background-color: lightyellow;
}

.diff {
  padding-left: 5%;
  padding-right: 5%;
}

.old {
  background-color: lightpink;
}

.new {
  background-color: lightgreen;
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
<h1><a title="Search for references to $ShortPage" rel="nofollow" href="$ShortUrl?do=search;page=$ShortPage">$PageName</a></h1></div>
<div class="wrapper">
!!CONTENT!!
</div>
<div class="close"></div>
<div class="footer">
<hr/>
<span class="navbar">$DiscussText
$EditText
$RevisionsText
<a title="Administration options" rel="nofollow" href="$ShortUrl?do=admin;page=admin">Admin</a>
<a title="Random page" rel="nofollow" href="$ShortUrl?do=random;page=$ShortPage">Random Page</a></span><span style="float:right;font-size:0.9em;"><strong>$SiteName</strong>
is powered by <em>Aneuch</em>.</span><br/>
<span class="mtime">$MTime</span><br/>
$PostFooter
</div>
<div class="debug">
$DebugMessages
</div>
</body>
</html>
