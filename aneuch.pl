#!/usr/bin/perl -wT
## **********************************************************************
## Copyright (c) 2012-2015, Aaron J. Graves (cajunman4life@gmail.com)
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
use 5.010;		# Require perl 5.10 or higher
use strict;		# Require strict declarations
use POSIX qw(strftime);	# String from time
use Fcntl qw(:flock :seek); # import LOCK_* and SEEK_END constants
use CGI;		# Use CGI.pm
use CGI::Carp qw(fatalsToBrowser);
local $| = 1;		# Do not buffer output
# Some variables
our ($DataDir, $SiteName, $Page, $ShortPage, @Passwords, $PageDir, $ArchiveDir,
     $ShortUrl, $SiteMode, $ScriptName, $ShortScriptName, $Header, $Footer,
     $PluginDir, $Url, $DiscussText, $DiscussPrefix, $DiscussLink,
     $DefaultPage, $CookieName, $PageName, $TempDir, @Messages, $command,
     $contents, %Plugins, $TimeStamp, $PostFooter, $TimeZone, $VERSION,
     $EditText, $RevisionsText, $NewPage, $NewComment, $NavBar, $ConfFile,
     $UserIP, $UserName, $VisitorLog, $LockExpire, %Filec, $MTime, 
     $RecentChangesLog, $Debug, $DebugMessages, $PageRevision, $MaxVisitorLog,
     %Commands, %AdminActions, %AdminList, $RemoveOldTemp, $ArgList, $ShortDir,
     @NavBarPages, $BlockedList, %PostingActions, $HTTPStatus, $PurgeRC,
     %MaintActions, $PurgeArchives, $SearchPage, $SearchBox, $ThemeDir, $Theme,
     $FancyUrls, %QuestionAnswer, $BannedContent, %Param, %SpecialPages,
     $SurgeProtectionTime, $SurgeProtectionCount, @PostInitSubs,
     $EditorLicenseText, $AdminText, $RandomText, $CountPageVisits,
     $PageVisitFile, $q, $Hostname, @RawHandlers, $UploadsAllowed, 
     @UploadTypes, %ShortCodes, %HTTPHeader, %CommandsDisplay,
     $PurgeDeletedPage, $VERSIONID, @DashboardItems);

my %srvr = (
  80 => 'http://',	443 => 'https://',
);

$VERSION = '0.50';	# Set version number
$VERSIONID = '0050';	# Version ID

# Subs
sub InitConfig  {
  $ConfFile = './config.pl' unless $ConfFile; # Set default unless we get it
  if(-f $ConfFile) {		# File exists
    do $ConfFile;		# Execute the config
  }
}

sub InitScript {
  # Figure out the script name, URL, etc.
  # Initially includes script name. If $FancyUrls is set, we'll get rid of it.
  $ShortUrl = $ENV{'SCRIPT_NAME'};
  $Url = $srvr{$ENV{'SERVER_PORT'}} . $ENV{'HTTP_HOST'} . $ShortUrl;
  $ScriptName = $ENV{'SCRIPT_NAME'};
  $ShortScriptName = $0;

  # Get $q
  $q = new CGI unless $q;
}

sub InitVars {
  # Safe path
  $ENV{'PATH'} = '/usr/local/bin:/usr/pkg/bin:/usr/bin:/bin';
  # We must be the first entry in Plugins
  # Define settings
  $DataDir = '/tmp/aneuch' unless $DataDir;	# Location of docs
  $DefaultPage = 'HomePage' unless $DefaultPage; # Default page
  @Passwords = qw() unless @Passwords;		# No password by default
  $SiteMode = 0 unless $SiteMode;		# 0=All, 1=Discus only, 2=None
  # Discussion page prefix
  $DiscussPrefix = 'Discuss_' unless defined $DiscussPrefix;
  $SiteName = 'Aneuch' unless $SiteName;	# Default site name
  $CookieName = 'Aneuch' unless $CookieName;	# Default cookie name
  $TimeZone = 0 unless $TimeZone;		# Default to GMT, 1=localtime
  $LockExpire = 60*5 unless $LockExpire;	# 5 mins, unless set elsewhere
  $Debug = 0 unless $Debug;			# Assume no debug
  $MaxVisitorLog = 1000 unless $MaxVisitorLog;	# Keep at most 1000 entries in
						#  visitor log
  $RemoveOldTemp = 60*60*24*7 unless $RemoveOldTemp; # > 7 days
  $PurgeRC = 60*60*24*7 unless $PurgeRC;	# > 7 days
  $PurgeArchives = -1 unless $PurgeArchives;	# Default to keep all!
  $Theme = "" unless $Theme;		# No theme by default
  $FancyUrls = 1 unless defined $FancyUrls;	# Use fancy urls w/.htaccess
  # New page and new comment default text
  $NewPage = 'It appears that there is nothing here.' unless $NewPage;
  $NewComment = 'Add your comment here.' unless $NewComment;
  # $SurgeProtectionTime is the number of seconds in the past to check hits
  $SurgeProtectionTime = 20 unless defined $SurgeProtectionTime;
  # $SurgeProtectionCount is the number of hits in the defined amount of time
  $SurgeProtectionCount = 20 unless defined $SurgeProtectionCount;
  # Count the number of visits to each page
  $CountPageVisits = 1 unless defined $CountPageVisits;
  $UploadsAllowed = 0 unless $UploadsAllowed;	# Do not allow uploads
  # The list of allowable uploads (MIME types)
  @UploadTypes = qw(image/gif image/png image/jpeg) unless defined @UploadTypes;
  # Blog pattern
  $PurgeDeletedPage = 60*60*24*14 unless $PurgeDeletedPage; # > 2 weeks
  # If $FancyUrls, remove $ShortScriptName from $ShortUrl
  if(($FancyUrls) and ($ShortUrl =~ m/$ShortScriptName/)) {
    $ShortUrl =~ s/$ShortScriptName//;
    $Url =~ s/$ShortScriptName//;
  } else {
    $ShortUrl .= "/";
    $Url .= "/";
  }

  # Some cleanup
  #  Remove trailing slash from $DataDir, if it exists
  $DataDir =~ s!/\z!!;

  # Initialize Directories
  InitDirs();

  # Check for needed %3B, convert to ;
  if($ENV{'REQUEST_URI'} =~ m/%3[Bb]/) { #ne $q->unescape($ENV{'REQUEST_URI'})) {
    $HTTPStatus = "301 Moved Permanently";
    #ReDirect($q->unescape($ENV{'REQUEST_URI'}), $HTTPStatus);
    my $new = $ENV{'REQUEST_URI'};
    $new =~ s/%3B/;/ig;
    ReDirect($new,$HTTPStatus);
    exit 0;
  }

  # Get page name that is being requested
  $Page = $q->path_info;
  if($Page =~ m/^\/{1,}/) { $Page =~ s/^\/{1,}//; }
  if($ENV{'QUERY_STRING'} and $ENV{'QUERY_STRING'} !~ /=/ and !$Page) {
    $Page = $ENV{'QUERY_STRING'};
    $ENV{'QUERY_STRING'} = '';
  }
  if(GetParam('page') and !$Page) {
    $Page = GetParam('page','');
  }
  $Page =~ s/^\/{1,}//;
  $Page = QuoteHTML($Page);
  if($Page and !GetParam('page')) {
    SetParam('page', $Page);
  }
  if(!$Page and GetParam('do')) {
    $Page = GetParam('do');
  }
  # If there is a space in the page name, and it's not part of a command,
  #  we're going to convert all the spaces to underscores and re-direct.
  if(($Page =~ m/.*\s.*/ or $Page =~ m/^\s.*/) and !$Page =~ m/^?/) {
    $Page =~ s/ /_/g;             # Convert spaces to underscore
    ReDirect($Url.$Page);
    exit 0;
  }
  if(GetParam('search',0)) { 
    my $sp = GetParam('search');
    $sp =~ s/\+/ /g;
    SetParam('search', $sp);
  }
  $Page =~ s!^/!!;		# Remove leading slash, if it exists
  $Page =~ s/^\.+//g;		# Remove leading periods
  $Page =~ s!\.{2,}!!g;         # Remove every instance of double period
  # Wait! If there's a trailing slash, let's remove and redirect...
  if($Page =~ m!/$!) {
    $Page =~ s!/$!!;		# Remove the trailing slash
    $HTTPStatus = "301 Moved Permanently";
    ReDirect($Url.$Page, $HTTPStatus);	# Redirect to the page sans trailing slash
    exit 0;
  }
  if($Page eq "") { 
    $Page = $DefaultPage;	# Default if blank
  }
  $PageName = $Page;		# PageName is Page with spaces
  $PageName =~ s/_/ /g;		# Change underscore to space

  $ShortDir = substr($Page,0,1);	# Get first letter
  $ShortDir =~ tr/[a-z]/[A-Z]/;		# Capitalize it

  # Discuss, edit links
  if(!GetParam('do') or GetParam('do') eq "revision") {
    if($DiscussPrefix) {
      if($Page !~ m/^$DiscussPrefix/) {	# Not a discussion page
	$DiscussLink = $Url . $DiscussPrefix . $Page;
	$DiscussText = $DiscussPrefix;
	$DiscussText =~ s/_/ /g;
	$DiscussText .= $Page . " (".DiscussCount().")";
	$DiscussText = '<a title="'.$DiscussText.'" href="'.$DiscussLink.'">'.
	  $DiscussText.'</a>';
      } else {				# Is a discussion page
	$DiscussLink = $Page;
	$DiscussLink =~ s/^$DiscussPrefix//;	# Strip discussion prefix
	$DiscussText = $DiscussLink;
	$DiscussLink = $Url . $DiscussLink;
	$DiscussText = '<a title="Return to '.$DiscussText.'" href="'.
	  $DiscussLink.'">'.$DiscussText.'</a>';
      }
    }
    # Edit link
    if(CanEdit()) {
      my $rev = GetParam('revision','');
      if($rev and $rev =~ m/\d+/ and PageExists($Page, $rev)) {
	$EditText = CommandLink('edit', $Page, 
	  'Edit Revision '.GetParam('revision'), 'Edit this page',
	  'revision='.GetParam('revision'));
      } else {
	$EditText = CommandLink('edit', $Page, 'Edit Page', 'Edit this page');
      }
    } else {
      $EditText = CommandLink('edit', $Page, 'Read Only', 'Read only page',
	(GetParam('revision')) ? 'revision='.GetParam('revision') : '');
    }
    $RevisionsText = CommandLink('history',$Page,'Page Info &amp; History',
      'Click here to see info and history');
  }

  # Admin link
  $AdminText = AdminLink('','Admin');

  # Random link
  $RandomText = CommandLink('random',$Page,'Random Page',
    'Navigate to a random page');

  # If we're a command, change the page title
  if(GetParam('do') eq 'search') {
    $PageName = "Search for: ".GetParam('search','');
  }

  # Set the TimeStamp
  $TimeStamp = time;

  # Set visitor IP address
  $UserIP = $q->remote_addr; #$ENV{'REMOTE_ADDR'};
  ($UserName) = &ReadCookie;
  # Get the hostname
  eval 'use Socket; $Hostname = gethostbyaddr(inet_aton($UserIP), AF_INET);';
  $Hostname = $UserIP unless $Hostname;
  # Set the username (unless it's already set)
  if(!$UserName) {
    $UserName = ($Hostname and $Hostname ne '.') ? $Hostname : $UserIP;
  }

  # Navbar
  $NavBar = "<ul id=\"navbar\">";
  foreach ($DefaultPage, 'RecentChanges', @NavBarPages) {
    $NavBar .= '<li><a href="'.$Url.ReplaceSpaces($_).'" title="'.$_.'"';
    if($Page eq ReplaceSpaces($_)) {
      $NavBar .= ' class="active"';
    }
    $NavBar .= '>'.$_.'</a></li>';
  }
  $NavBar .= "</ul>";

  # Search box
  $SearchBox = SearchForm() unless $SearchBox;  # Search box code

  # Register the built-in commands (?do= directives)
  # Administrative menu
  RegCommand('admin', \&DoAdmin,
    'was in Administrative mode, doing %s');
  # Editing screen
  RegCommand('edit', \&DoEdit, 'was editing %s');
  # Search feature
  RegCommand('search', \&DoSearch, 'was searching for "%s"');
  # Page history
  RegCommand('history', \&DoHistory, 'was viewing the history of %s');
  # Random page
  RegCommand('random', \&DoRandom, 'was redirected to a random page from %s');
  # Differences between revisions
  RegCommand('diff', \&DoDiff, 'was viewing differences on %s');
  # Spamming the page
  RegCommand('spam', \&DoSpam, 'was spamming the page %s');
  # Just in case...
  RegCommand('recentchanges', \&DoRecentChanges, 'was viewing recent changes');
  # Index of all pages
  RegCommand('index', \&DoAdminIndex, 'was viewing the page index');
  # Pages that link here
  RegCommand('links', \&DoLinkedPages, 'was viewing backlinks to %s');
  # Download/raw display for files
  RegCommand('download', \&DoDownload, 'downloaded the file %s');
  # robots.txt support
  RegCommand('robotstxt', \&DoRobotsTxt, 'was getting %s');

  # Now register the admin actions (?do=admin;page= directives)
  # 'password' has to be set by itself, since technically there isn't a menu
  #  item for it in the %AdminList (it's hard coded)
  $AdminActions{'password'} = \&DoAdminPassword;
  $AdminActions{'dashboard'} = \&DoAdminDashboard;
  RegAdminPage('version', 'View version information', \&DoAdminVersion);
  RegAdminPage('index', 'List all pages', \&DoAdminIndex);
  RegAdminPage('reindex', 'Rebuild page index', \&DoAdminReIndex);
  RegAdminPage('rmlocks', 'Force delete page locks', \&DoAdminRemoveLocks);
  RegAdminPage('visitors', 'Display visitor log', \&DoAdminListVisitors);
  RegAdminPage('clearvisits', 'Clear visitor log', \&DoAdminClearVisits);
  RegAdminPage('lock',
    (-f "$DataDir/lock") ? 'Unlock the site' : 'Lock the site', \&DoAdminLock);
  RegAdminPage('block', 'Block users', \&DoAdminBlock);
  RegAdminPage('bannedcontent', 'Ban certain types of content',
   \&DoAdminBannedContent);
  RegAdminPage('css', "Edit the site's style (CSS)", \&DoAdminCSS);
  RegAdminPage('files', "List uploaded files", \&DoAdminListFiles);
  RegAdminPage('robotstxt', "Modify your robots.txt file", \&DoAdminRobotsTxt);
  #RegAdminPage('getbannedcontentfile', '', \&DoAdminGetBannedContentFile);
  RegAdminPage('templates', "List template pages", \&DoAdminListTemplates);
  RegAdminPage('plugins', "Plugin manager", \&DoAdminPlugins);
  RegAdminPage('deleted', "List pending deleted pages", \&DoAdminDeleted);

  # Dashboard items
  RegDashboardItem(\&DashboardDatabase);
  RegDashboardItem(\&DashboardBannedContent);
  RegDashboardItem(\&DashboardBannedUsers);

  # Register POSTing actions
  RegPostAction('login', \&DoPostingLogin);		# Login
  RegPostAction('editing', \&DoPostingEditing);		# Editing
  RegPostAction('discuss', \&DoPostingDiscuss);		# Discussions
  RegPostAction('blocklist', \&DoPostingBlockList);	# Block list
  RegPostAction('commenting', \&DoPostingSpam);		# Spam submissions
  RegPostAction('bannedcontent', \&DoPostingBannedContent); # Banned content
  RegPostAction('css', \&DoPostingCSS);			# Style/CSS
  RegPostAction('upload', \&DoPostingUpload);		# File uploads
  RegPostAction('robotstxt', \&DoPostingRobotsTxt);	# robots.txt

  # Register raw handlers
  RegRawHandler('download');
  RegRawHandler('random');
  RegRawHandler('robotstxt');

  # Is robots.txt? Let's send it.
  if($Page eq "robots.txt") { SetParam('do','robotstxt'); }

  # Maintenance actions
  RegMaintAction('purgerc', \&DoMaintPurgeRC);
  RegMaintAction('purgeoldr', \&DoMaintPurgeOldRevs);
  RegMaintAction('purgetemp', \&DoMaintPurgeTemp);
  RegMaintAction('trimvisit', \&DoMaintTrimVisit);
  RegMaintAction('deletepages', \&DoMaintDeletePages);

  # Register the "Special Pages"
  RegSpecialPage('RecentChanges', \&DoRecentChanges);	# Recent Changes
  if($DiscussPrefix) {
    RegSpecialPage("$DiscussPrefix.*", \&DoDiscuss);	# Discussion pages
  }

  # Register short codes
  RegShortCode('search', \&DoSearchShortCode);
}

sub DoPostInit {
  # Runs any subs that want to be called at the tail end of Init()
  if(@PostInitSubs) {
    foreach my $SubToRun (@PostInitSubs) {
      &{$SubToRun};
    }
  }
}

sub DoHeader {
  if(!$Theme or !-d "$ThemeDir/$Theme") {
    print "<!DOCTYPE html>\n".
      '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">'.
      "<head><title>$PageName - $SiteName</title>\n".
      "<meta name=\"generator\" content=\"Aneuch $VERSION\" />\n".
      '<style type="text/css">'.DoCSS().
      "</style></head>\n<body>\n<div id=\"container\">\n".
      "<div id=\"header\"><div id=\"searchbox\">".SearchForm().
      "</div>\n".
      "<a title=\"Return to $DefaultPage\" href=\"$Url\">$SiteName</a>: <h1>";
    if(PageExists($Page)) {
      print "<a title=\"Search for references to $SearchPage\" ".
	"rel=\"nofollow\" href=\"$Url?do=search;search=".
	"$SearchPage\">$PageName</a>";
    } else {
      print "$PageName";
    }
    print "</h1>\n</div>\n<div class=\"navigation\">\n<ul>$NavBar</ul></div>".
      "<div id=\"content\"";
    if((CanEdit()) and (!IsDiscussionPage()) and (!GetParam('do'))) {
      print " ondblclick=\"window.location.href='$Url?do=edit;page=$Page'\"";
    }
    print '><span id="top"></span>';
  } else {
    if(-f "$ThemeDir/$Theme/head.pl") {
      do "$ThemeDir/$Theme/head.pl";
    } elsif(-f "$ThemeDir/$Theme/head.html") {
      print Interpolate(FileToString("$ThemeDir/$Theme/head.html"));
    }
  }
}

sub DoFooter {
  if(!$Theme or !-d "$ThemeDir/$Theme") {
    print '<span id="bottom"></span></div> <!-- content -->'.
      '<div class="navigation">'."<ul>";
    # If we want discussion pages
    if($DiscussPrefix) {
      print "<li>$DiscussText</li>";
    }
    print "<li>$EditText</li><li>$RevisionsText</li><li>$AdminText</li>".
      "<li>$RandomText</li></ul>".'<div id="identifier"><strong>'.
      $SiteName.'</strong> is powered by <em>Aneuch</em>.</div>'.
      '</div> <!-- navigation --><div id="footer"><div id="mtime">';
    if(PageExists($Page)) {
      print Commify(GetPageViewCount($Page))." view(s).&nbsp;&nbsp;";
    }
    print "$MTime</div>$PostFooter</div> <!-- footer --></div> ".
      "<!-- container --></html>";
  } else {
    if(-f "$ThemeDir/$Theme/foot.pl") {
      do "$ThemeDir/$Theme/foot.pl";
    } elsif(-f "$ThemeDir/$Theme/foot.html") {
      print Interpolate(FileToString("$ThemeDir/$Theme/foot.html"));
    }
  }
}

sub DoCSS {
  # Style sheet for the template. This is in it's own sub to facilitate
  #  CSS Customization in the future.
  if(-f "$DataDir/style.css") {
    return FileToString("$DataDir/style.css");
  } elsif($Theme and -f "$ThemeDir/$Theme/style.css") {
    return FileToString("$ThemeDir/$Theme/style.css");
  } else {
    my $data_pos = tell DATA;	# Find the position of __DATA__
    chomp(my @CSS = <DATA>);	# Read in __DATA__
    seek DATA, $data_pos, 0;	# So we can re-read __DATA__ later
    return join("\n", @CSS);
  }
}

sub MarkupBuildLink {
  # This sub takes everything between [[ and ]] and builds a link out of it.
  my $data = shift;
  my $return;
  my $href;
  my $text;
  my $url = $Url; $url =~ s/\/$//;
  my $same = 0;
  if($data =~ m/\|/) {        # Seperate text
    ($href,$text) = split(/\|/, $data);
  } else {                    # No seperate text
    $href = $data; $text = $data;
    $same = 1;
  }
  if($text =~ /#/ and $text !~ /^#/) {
    $text = (split(/#/,$text))[0] if $same;
  } elsif($text =~ /^#/) {
    $text =~ s/^#+// if $same;
  }
  if(($href =~ m/^htt(p|ps):/) and ($href !~ m/^$url/)) { # External link!
    $return = $q->a({-class=>'external',-rel=>'nofollow',
      -title=>'External link: '.$href,-target=>'_blank',-href=>$href},$text);
  } else {			# Internal link!
    my $testhref = (split(/#/,$href))[0];
    $testhref = (split(/\?/,$testhref))[0];
    if((PageExists(ReplaceSpaces($testhref))) or ($testhref =~ m/^\?/)
     or (ReplaceSpaces($testhref) =~ m/^$DiscussPrefix/)
     or ($testhref =~ m/^$url/) or ($testhref eq '') or (!CanEdit())) {
      $return = "<a title='".ReplaceSpaces($href)."' href='";
      if(($href !~ m/^$url/) and ($href !~ m/^#/)) {
	$return .= $Url.ReplaceSpaces($href);
      } else {
	$return .= $href;
      }
      $return .= "'>".$text."</a>";
    } else {
      $return = "[<span style=\"border-bottom: 1px dashed #FF0000;\">".
	"$text</span>".
	CommandLink('edit', ReplaceSpaces($href), '?',
	  "Create page \"".ReplaceSpaces($href)."\"")."]";
    }
  }
  return $return;
}

sub MarkupImage {
  my $data = shift;
  my ($align, $alt, $img);
  if($data =~ m/^(left|right):/) {
    my @dd = split(/:/,$data);
    $align = shift(@dd);
    $img = join(":", @dd);
  } else {
    $img = $data;
  }
  if($img =~ m/\|/) {
    ($img,$alt) = split(/\|/,$img);
  }
  my $return = '<img src="';
  if(PageExists(ReplaceSpaces($img))) {
    $return .= "$Url?do=download;page=".ReplaceSpaces($img)."\" ";
  } else {
    $return .= "$img\" ";
  }
  if($alt) {
    $return .= "alt=\"$alt\" ";
  }
  if($align) {
    $return .= "align=\"$align\" ";
  }
  $return .= "/>";
  return $return;
}

sub MarkupShortcode {
  my $orig = shift;
  my $shortcode = $orig;
  my $params;
  if($shortcode =~ m/^(.*?)\s+(.*?)$/) {
    $shortcode = $1;
    $params = $2;
  }
  if(defined($ShortCodes{$shortcode})) {
    return &{$ShortCodes{$shortcode}}($params);
  } else {
    return "%$orig%";
  }
}

sub Markup {
  # Markup is a cluster. It's so ugly and nasty, but it works. In the future,
  #  this thing will be re-written to be much cleaner.
  my $cont = shift;
  my @contents = split(/\n/, $cont);

  my $ulstep = 0;
  my $olstep = 0;
  my $openul = 0;		# For building <ul>
  my $openol = 0;		# For building <ol>
  my $ulistlevel = 0;		# List levels
  my $olistlevel = 0;
  my @build;			# What will be returned
  my $line;			# Line-by-line
  my $nowiki = 0;		# #NOWIKI
  my $pre = 0;			# <pre>
  my $c;
  my $extra;
  foreach $line (@contents) {
    # #NOWIKI
    if(!$nowiki and ($line =~ m/^#NOWIKI$/ or $line =~ m/^\{{3}$/)) {
      $nowiki = 1;
      push @build, "<!--#NOWIKI-->";
      if($line =~ m/^\{{3}$/) { push @build, "<pre>"; $pre = 1; }
      next;
    }
    if($nowiki and ($line !~ m/^#NOWIKI$/ and $line !~ m/^\}{3}$/)) { 
      push @build, ($pre) ? QuoteHTML($line) : $line;
      next;
    }
    if($nowiki and ($line =~ m/^#NOWIKI$/ or $line =~ m/^\}{3}$/)) {
      $nowiki = 0;
      if($line =~ m/^\}{3}$/) { push @build, "</pre>"; $pre = 0; }
      push @build, "<!--#NOWIKI-->";
      next;
    }

    $line = QuoteHTML($line);

    # Are we doing lists?
    # UL
    if($line =~ m/^[\s\t]*(\*{1,})[ \t]/) {
      if(!$openul) { $openul=1; }
      $ulstep=length($1);
      if($ulstep > $ulistlevel) {
	until($ulistlevel == $ulstep) { push @build, "<ul>"; $ulistlevel++; }
      } elsif($ulstep < $ulistlevel) {
	until($ulistlevel == $ulstep) { push @build, "</ul>"; $ulistlevel--; }
      }
    }
    if(($openul) && ($line !~ m/^[\s\t]*\*{1,}[ \t]/)) {
      $openul=0; 
      until($ulistlevel == 0) { push @build, "</ul>"; $ulistlevel--; }
    }
    # OL
    if($line =~ m/^[\s\t]*(#{1,})/) {
      if(!$openol) { $openol=1; }
      $olstep=length($1);
      if($olstep > $olistlevel) {
	until($olistlevel == $olstep) { push @build, "<ol>"; $olistlevel++; }
      } elsif($olstep < $olistlevel) {
	until($olistlevel == $olstep) { push @build, "</ol>"; $olistlevel--; }
      }
    }
    if(($openol) && ($line !~ m/^[\s\t]*#{1,}/)) {
      $openol=0;
      until($olistlevel == 0) { push @build, "</ol>"; $olistlevel--; }
    }

    # Signature
    #  This is only for preview!!!!!!!
    $line =~ s/~{4}/GetSignature($UserName)/eg;

    # Forced line breaks
    $line =~ s#\\\\#<br/>#g;

    # Headers
    $line =~ s#^(={1,5})(.*?)(=*)$#"<h".length($1)." id='".ReplaceSpaces(StripMarkup($2))."'>$2</h".length($1).">"#e;

    # HR
    $line =~ s#^-{4,}$#<hr/>#;

    # <tt>
    $line =~ s#\`{1}(.*?)\`{1}#<tt>$1</tt>#g;

    # NOTE: I changed the #s to #m on the next two, to match multi-line.
    #  However, multiline is impossible the way the markup engine currently
    #  works (by splitting the text into lines and operating on individual
    #  lines).
    # UL LI
    $line =~ s#^[\s\t]*\*{1,5}[ \t](.*)#<li>$1</li>#m;

    # OL LI
    $line =~ s!^[\s\t]*#{1,5}[ \t](.*)!<li>$1</li>!m;

    # Bold
    $line =~ s#\*{2}(.*?)\*{2}#<strong>$1</strong>#g;

    # Images
    $line =~ s#\{{2}(.+?)\}{2}#MarkupImage($1)#eg;

    # Links
    $line =~ s#\[{2}(.+?)\]{2}#MarkupBuildLink($1)#eg;

    # Fix for italics...
    $line =~ s#htt(p|ps)://#htt$1:~/~/#g;
    # Italics
    $line =~ s#/{2}(.*?)/{2}#<em>$1</em>#g;
    # Fix for italics...
    $line =~ s#htt(p|ps):~/~/#htt$1://#g;

    # Strikethrough
    $line =~ s#-{2}(.*?\S)-{2}#<del>$1</del>#g;

    # Underline
    $line =~ s#_{2}(.*?)_{2}#<span style="text-decoration:underline">$1</span>#g;

    # Shortcodes
    $line =~ s#%([^%]+?)%#MarkupShortcode($1)#eg;

    # Add it
    push @build, $line;
  }
  # Do we have anything open?
  push @build, "</ol>" if $openol;
  push @build, "</ul>" if $openul;
  # Ok, now let's do paragraphs.
  my $prevblank = 1;    # Assume true
  my $openp = 0;        # Assume false
  my $i = 0;
  $nowiki = 0;
  for($i=0;$i<=$#build;$i++) {
    if($build[$i] =~ m/<!--#NOWIKI-->/) {
      $nowiki = (($nowiki == 0) ? 1 : 0);
      next;
    }
    next if $nowiki;
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

  # Build output
  my $returnout = join("\n",@build);

  # Output
  return "<!-- start of Aneuch markup -->\n".$returnout."\n<!-- end of Aneuch markup -->\n";
}

sub MarkupHelp {
  # This sub will be called at the end of the edit form, and provides 
  #  assistance to the users for markup
  print '<div id="markup-help"><dl>'.
    '<dt>Styling</dt><dd>**<strong>bold</strong>**, '.
    '//<em>italic</em>//, __<span style="text-decoration:underline">'.
    'underline</span>__, --<del>strikethrough</del>--, '.
    '`<tt>teletype</tt>`</dd>'.
    '<dt>Headers</dt><dd>= Level 1 =, == Level 2 ==, === Level 3 ===, '.
    "==== Level 4 ====, ===== Level 5 ===== (ending ='s optional)</dd>".
    '<dt>Lists</dt><dd>* Unordered List, # Ordered List, ** Level 2 unordered,'.
    ' ### Level 3 ordered (up to 5 levels, NO SPACES IN FRONT)</dd>'.
    '<dt>Links</dt><dd>[[Page]], [[Page|description]], [[http://link]], '.
    '[[http://link|description]]</dd>'.
    '<dt>Images</dt><dd>{{image.jpg}}, {{right:image.jpg}} (right aligned), '.
    '[[link|{{image.jpg}}]] (image linked to link), '.
    '{{image.jpg|alt text}}</dd>'.
    '<dt>Extras</dt><dd>---- (horizonal rule), ~~~~ (signature)</dd></div>';
}

sub Commify {
  local $_  = shift;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
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

sub PageIsFile {
  my $file = shift;
  my %f = GetPage($file);
  return ($f{text} =~ m/^#FILE /) ? 1 : 0;
}

sub IsRawHandler {
  my $handler = shift;
  my $return = 0;
  $return = grep(/^$handler$/, @RawHandlers);
  return $return;
}

sub RegRawHandler {
  my $Handler = shift;
  return unless $Handler;
  push @RawHandlers, $Handler;
}

sub RegPostInitSub {
  my $Sub = shift;
  push @PostInitSubs, $Sub;
}

sub RegSpecialPage {
  my ($page, $sref) = @_;
  return unless $page;
  $SpecialPages{$page} = $sref;
}

sub UnregSpecialPage {
  my $name = shift;
  if(exists $SpecialPages{$name}) {
    delete $SpecialPages{$name};
    return 1;
  } else {
    return 0;
  }
}

sub RegShortCode {
  my ($code, $sref) = @_;
  return unless $code;
  $ShortCodes{$code} = $sref;
}

sub UnregShortCode {
  my $code = shift;
  if(exists $ShortCodes{$code}) {
    delete $ShortCodes{$code};
    return 1;
  } else {
    return 0;
  }
}

sub RegPlugin {
  # Registers plugin
  my ($name, $description) = @_;
  $Plugins{$name} = $description;
}

sub IsSpecialPage {
  # Determines of the current requested page is a special page
  foreach my $spage (sort keys %SpecialPages) {
    if($Page =~ m/^$spage$/) { return 1; }
  }
  return 0;
}

sub DoSpecialPage {
  return if GetParam('revision','');
  foreach my $spage (sort keys %SpecialPages) {
    if($Page =~ m/^$spage$/) { &{$SpecialPages{$spage}}; return; }
  }
}

sub RegAdminPage {
  my ($name, $description, $sref) = @_;
  if(!exists $AdminList{$name}) {
    $AdminList{$name} = $description;
    $AdminActions{$name} = $sref;
    return 1;
  } else {
    return 0;
  }
}

sub UnregAdminPage {
  my $name = shift;
  if(exists $AdminList{$name}) {
    delete $AdminList{$name};
    delete $AdminActions{$name};
    return 1;
  } else {
    return 0;
  }
}

sub RegPostAction {
  my ($name, $sref) = @_;
  if(!exists $PostingActions{$name}) {
    $PostingActions{$name} = $sref;
    return 1;
  } else {
    return 0;
  }
}

sub UnregPostAction {
  my $name = shift;
  if(exists $PostingActions{$name}) {
    delete $PostingActions{$name};
    return 1;
  } else {
    return 0;
  }
}

sub RegCommand {
  my ($name, $sref, $display) = @_;
  if(!exists $Commands{$name}) {
    $Commands{$name} = $sref;
    $CommandsDisplay{$name} = $display;
    return 1;
  } else {
    return 0;
  }
}

sub UnregCommand {
  my $name = shift;
  if(exists $Commands{$name}) {
    delete $Commands{$name};
    delete $CommandsDisplay{$name};
    return 1;
  } else {
    return 0;
  }
}

sub RegMaintAction {
  my ($name, $sref) = @_;
  if(!exists $MaintActions{$name}) {
    $MaintActions{$name} = $sref;
    return 1;
  } else {
    return 0;
  }
}

sub UnregMaintAction {
  my $name = shift;
  if(exists $MaintActions{$name}) {
    delete $MaintActions{$name};
    return 1;
  } else {
    return 0;
  }
}

sub RegDashboardItem {
  my $sref = shift;
  push @DashboardItems, $sref;
}

sub GetParam {
  my ($ParamToGet, $Default) = @_;
  $Default = 0 unless defined $Default;
  my $result = QuoteHTML($q->param($ParamToGet));
  # NOTE: You now have to unquote anything that should have HTML
  return (defined $result) ? $result : $Default;
}

sub SetParam {
  my ($name, $value) = @_;
  $q->param($name, $value);
}

sub GetPage {
  # GetPage will read the file into a hash, and return it.
  my ($file, $revision) = @_;
  # Get short dir
  my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  # Call ReadDB!
  if($revision =~ m/\d+/) {	# If revision exists and is a numeric value
    return ReadDB("$ArchiveDir/$archive/$file.$revision");
  } else {
    return ReadDB("$PageDir/$archive/$file");
  }
}

sub GetPageViewCount {
  my $page = shift;
  my %f = ReadDB($PageVisitFile);
  return ($f{$page}) ? $f{$page} : 0;
}

sub GetTotalViewCount {
  my $sum;
  my %f = ReadDB($PageVisitFile);
  for(keys %f) {
    $sum += $f{$_};
  }
  return $sum;
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
  $ThemeDir = "$DataDir/themes";
  eval { mkdir $ThemeDir unless -d $ThemeDir; }; push @Messages, $@ if $@;
  $VisitorLog = "$DataDir/visitors.log";
  $RecentChangesLog = "$DataDir/rc.log";
  $BlockedList = "$DataDir/banned";
  $BannedContent = "$DataDir/bannedcontent";
  $PageVisitFile = "$DataDir/visitcount";
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
  my ($uname, $passwd) = ('','');
  my $cookie = $q->cookie($CookieName);
  ($uname, $passwd) = split(/:/, $cookie);
  return ($uname, $passwd);
}

sub SetCookie {
  # Save user and pass to cookie
  my ($user, $pass) = @_;
  my $matchedpass = grep(/^$pass$/, @Passwords); # Did they provide right pass?
  my $cookie = $user if $user;		# Username first, if they gave it
  if($matchedpass and $user) {		# Need both...
    $cookie .= ':' . $pass;
  }
  my $futime = gmtime($TimeStamp + 31556926)." GMT";	# Now + 1 year
  my $cookiepath = $ShortUrl;
  $cookiepath =~ s/$ShortScriptName\?//;
  $cookiepath =~ s/$ShortScriptName\///;
  my $ck = $q->cookie(-name=>$CookieName, -value=>$cookie,
		      -path=>$cookiepath, -expires=>$futime);
  $HTTPHeader{'-cookie'} = $ck;
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

sub CanView {
  # Determine if the site can be viewed
  if($SiteMode < 3) { return 1; }	# Automatic if not 3
  if(IsLoggedIn()) {
    return 1;
  } else {
    # Check if we're requesting the password page
    if((GetParam('do') eq 'admin') and (GetParam('page') eq "password")) {
      return 1;
    } else {
      return 0;
    }
  }
}

sub CanUpload {
  my $upload = shift;
  # Is edit allowed?
  return 0 unless CanEdit();
  # Are uploads allowed?
  return 0 unless ($UploadsAllowed or IsAdmin());
  # If we're being passed a MIME type, check it...
  if($upload) {
    return grep(/^$upload$/,@UploadTypes);
  }
  # I guess that leaves us with nothing else but to return true
  return 1;
}

sub IsLoggedIn {
  # Determine if user is logged in
  #  NOTE: Right now, it does the same thing as IsAdmin. This could be used
  #  in the future to provide for an editor password, or actual user logins.
  my ($u, $p) = ReadCookie();
  if(@Passwords == 0) {         # If no password set...
    return 1;
  }
  return scalar(grep(/^$p$/, @Passwords));
}

sub CanDiscuss {
  # If lock is set, return false automatically
  if(-f "$DataDir/lock") { return 0; }
  if(($SiteMode < 2 or IsAdmin()) and $Page =~ m/^$DiscussPrefix/) {
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
    @rc = FileToArray($RecentChangesLog);
  }
  # Remove any old entry...
  @rc = grep(!/^$day(\d{6})\t$file\t/,@rc);
  # Now update...
  push @rc, "$day$time\t$file\t$un\t$mess\t$TimeStamp\n";
  # Now write it back out...
  StringToFile(join("\n",@rc), $RecentChangesLog);
  Notify($file, $un, $mess);
}

sub Notify {
  my ($file, $user, $message) = @_;
  # Prepare to notify people
}

sub RefreshLock {
  # Refresh a lock on $Page
  if(-f "$TempDir/$Page.lock") {
    chomp(my @lock = FileToArray("$TempDir/$Page.lock"));
    if($lock[0] eq $UserIP and $lock[1] eq $UserName) {
      $lock[2] = $TimeStamp;
      StringToFile(join("\n",@lock), "$TempDir/$Page.lock");
      return 1;
    } else { return 0; }
  } else { return 0; }
}

sub DoEdit {
  my $canedit = CanEdit();
  my $clear = GetParam('clear');
  # Let's begin
  my ($contents, $revision);
  $revision = GetParam('revision','');
  my $summary = GetParam('summary','');
  my $preview = 0;
  my $template = GetParam('template',0);
  my %f;

  if($clear) {
    SetParam('upload',0);
  }

  if(PageIsFile($Page) and !GetParam('upload') and !$clear) {
    SetParam('upload',1);
  }

  if(GetParam('upload') and !CanUpload()) {
    print $q->p("Uploads are not allowed on this site.");
    return;
  }

  # Get a list of templates
  my @templates = ('None', ListAllTemplates());

  if(-f "$TempDir/$Page.$UserName") {
    %f = ReadDB("$TempDir/$Page.$UserName");
    $revision = $f{revision};
    #chomp($contents = $f{text});
    $contents = $f{text};
    $preview = 1;
    $summary = $f{summary};
    $template = $f{template};
    RefreshLock();
  } else {
    %f = GetPage($Page, $revision);
    #chomp($contents = $f{text});
    $contents = $f{text};
    if($clear) { $contents = ''; }
    $revision = $f{revision} if defined $f{revision};
    $revision = 0 unless $revision;
    $template = $f{template};
  }

  # Are we supposed to be a template?
  if(GetParam('use_template',0) and $clear) {
    if(PageExists(GetParam('use_template'))) {
      my %T = GetPage(GetParam('use_template'));
      $contents = $T{text};
    }
  }

  if($revision > 0) {
    print "<p>Editing version $revision of page $Page";
    if($revision != LatestRevision($Page)) {
      print " (the most recent revision is ".LatestRevision($Page).")";
    } elsif($revision == LatestRevision($Page)) {
      print " (this is the most recent revision)";
    }
  } else {
    print "<p>Editing the new page $Page";
  }
  print "</p>";

  if(IsSpecialPage($Page)) {
    print $q->p($q->span({-style=>'color:red; font-style: italic;'},
      "Note: This page is defined as a special page, ".
      "and as such its final state may be different from what you see here."));
  }

  if($preview) {
    print $q->div({-class=>'preview'},Markup($contents));
  }

  if($canedit) {
    print RedHerringForm();
    # Template select
    print StartForm('get');
    print $q->hidden(-name=>'do', -value=>'edit');
    print $q->hidden(-name=>'page', -value=>$Page);
    print $q->p("Use template: ".
      $q->popup_menu(-name=>'use_template', -values=>\@templates,
        -onchange=>'this.form.submit()'));
    print $q->hidden(-name=>'clear', -value=>1);
    print "</form>";
    # Main edit form
    print StartForm();
    my $doing = (GetParam('upload')) ? 'upload' : 'editing';
    print $q->hidden(-name=>'doing', -value=>$doing);
    print $q->hidden(-name=>'file', -value=>$Page);
    print $q->hidden(-name=>'revision', -value=>$revision);
    if(-f "$PageDir/$ShortDir/$Page") {
      print $q->hidden(-name=>'mtime', -value=>(stat("$PageDir/$ShortDir/$Page"))[9]);
    }
  }
  if(GetParam('upload')) {
    print $q->p("File to upload: ".$q->filefield(-name=>'fileupload',
      -size=>50, -maxlength=>100, -style=>"border:none;"));
  } else {
    print $q->textarea(-name=>'text', -cols=>'100', -rows=>'25',
      -style=>'width:100%', -default=>$contents);
  }
  # For templates
  print $q->checkbox(-name=>'template', -checked=>$template, -value=>'1',
    -label=>'Is this page a template?',
    -title=>'Check this to save this page as a template');

  if($canedit) {
    # Set a lock
    if($preview or SetLock()) {
      print $q->p("Summary:<br/>".$q->textarea(-name=>'summary',
	-cols=>'100', -rows=>'2', -style=>'width:100%;',
	-placeholder=>'Edit summary (required)', -default=>$summary));
      print '<p>User name: '.$q->textfield(-name=>'uname',
	-size=>'30', -value=>$UserName)." ";
      print AntiSpam();
      if(GetParam('upload')) {
	print $q->submit(-name=>'whattodo', -value=>'Upload'), " ";
      } else {
	print $q->submit(-name=>'whattodo', -value=>'Save'), " ";
	print $q->submit(-name=>'whattodo', -value=>'Preview'), " ";
      }
      print $q->submit(-name=>'whattodo', -value=>'Cancel');
    }
    print "</p>".$q->endform;
    if(GetParam('upload')) {
      print $q->p($q->a({-href=>"$Url?do=edit;page=$Page;clear=1"}, 
	"Convert this file to text"));
    } else {
      print $q->p($q->a({-href=>"$Url?do=edit;page=$Page;upload=1"}, 
	"Upload a file")) if CanUpload();
    }
    if($EditorLicenseText) {
      print "<p>$EditorLicenseText</p>";
    }
    MarkupHelp();
  }
}

sub SetLock {
  # Sets a page lock
  if(-f "$TempDir/$Page.lock" and ((stat("$TempDir/$Page.lock"))[9] <= ($TimeStamp - $LockExpire))) {
    UnLock();
  }
  # Set a lock on $Page
  if(-f "$TempDir/$Page.lock") {
    chomp(my @lock = FileToArray("$TempDir/$Page.lock"));
    my ($u, $p) = ReadCookie();
    if(($lock[0] ne $UserIP) or ($lock[1] ne $u)) {
      print "<p><span style='color:red'>This file is locked by <strong>".
	"$lock[0] ($lock[1])</strong> since <strong>".
	(FriendlyTime($lock[2]))[$TimeZone]."</strong>.</span>";
      print "<br/>Lock should expire by ".
	(FriendlyTime($lock[2] + $LockExpire))[$TimeZone].", and it is now ".
	(FriendlyTime())[$TimeZone].".</p>";
      return 0;
    } else {
      # Let's refresh the lock!
      #return RefreshLock();
      my $ret = RefreshLock();
      print "<p><span style='color:red'>Call to RefreshLock() failed.</span>".
	"</p>" unless $ret;
      return $ret;
    }
  } else {
    StringToFile("$UserIP\n$UserName\n$TimeStamp", "$TempDir/$Page.lock");
    return 1;
  }
}

sub UnLock {
  # Removed a page lock
  my $pg = $Page;
  ($pg) = @_ if @_ >= 1;
  $pg =~ m/^([^\\\/]+)$/; $pg = $1;
  if(-f "$TempDir/$pg.lock") {
    if(!unlink "$TempDir/$pg.lock") {
      push @Messages, "Unable to delete lock file $pg.lock: $!";
    }
  }
}

sub Index {
  # Adds a page to the pageindex file.
  my $pg = $Page;
  ($pg) = @_ if @_ >= 1;
  my @pagelist = FileToArray("$DataDir/pageindex");
  if(!grep(/^$pg$/,@pagelist)) {
    open my($INDEX), '>>', "$DataDir/pageindex" or push @Messages,
      "Index: Unable to open pageindex for append: $!";
    print $INDEX "$pg\n";
    close($INDEX);
  }
}

sub DoArchive {
  my $file = shift;	# The file we're working on
  $file =~ m/^([^\\\/]+)$/; $file = $1;
  # $archive will be the 1-letter dir under /archive that we're writing to
  my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  $archive =~ m/^(\w)$/; $archive = $1;
  if(!PageExists($file)) { return; }
  # If $archive doesn't exist, we'd better create it...
  if(! -d "$ArchiveDir/$archive") { mkdir "$ArchiveDir/$archive"; }
  my %F = GetPage($file);
  # Now copy...
  $F{revision} =~ m/^(\d+)$/; $F{revision} = $1;
  system("cp $PageDir/$archive/$file $ArchiveDir/$archive/$file.$F{revision}");
}

sub WritePage {
  my ($file, $content, $user) = @_;
  if(-f "$TempDir/$file.$UserName") {	# Remove preview files
    unlink "$TempDir/$file.$UserName";
  }
  # $archive will be the 1-letter dir under /archive that we're writing to
  my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  # If $archive doesn't exist, we'd better create it...
  if(! -d "$PageDir/$archive") { mkdir "$PageDir/$archive"; }
  chomp($content);
  # Unquote HTML
  $content = UnquoteHTML($content);
  # Catch any signatures!
  if($content !~ m/^#FILE /) {
    $content =~ s/~{4}/GetSignature($UserName)/eg;
  }
  $content .= "\n";
  DoArchive($file);
  $content =~ s/\r//g;
  my $diff;
  if(!GetParam('fileupload')) {
    StringToFile($content, "$TempDir/new");
    my %T = GetPage($file);
    StringToFile($T{text}, "$TempDir/old");
    $diff = `diff $TempDir/old $TempDir/new`;
    $diff =~ s/\\ No newline.*\n//g;
    $diff =~ s/\r//g;
  }
  my %F;
  # Build file information
  $F{summary} = UnquoteHTML(GetParam('summary')); # FIXME: This needs to be a var passed!
  $F{summary} =~ s/\r//g; $F{summary} =~ s/\n//g;
  $F{ip} = $UserIP;
  $F{author} = $user;
  $F{ts} = $TimeStamp;
  $F{text} = $content;
  $F{revision} = NextRevision($file);
  $F{diff} = $diff;
  $F{hostname} = $Hostname;
  if(GetParam('fileupload')) {
    $F{filename} = GetParam('fileupload');
  }
  $F{template} = GetParam('template');
  WriteDB("$PageDir/$archive/$file", \%F);
  UnLock($file);
  Index($file);
  LogRecent($file,$user,UnquoteHTML(GetParam('summary')));
}

sub WriteDB {
  # We receive file name, and hash
  my $filename = shift;
  my %filedata = %{shift()};
  $filename =~ m/^(.*)$/; $filename = $1;
  open my($FILE), '>', $filename or push @Messages,
    "WriteDB: Unable to write to $filename: $!";
  flock($FILE, LOCK_EX);	# Lock, exclusive
  seek($FILE, 0, SEEK_SET);	# Go to beginning of file...
  foreach my $key (sort keys %filedata) {
    $filedata{$key} =~ s/\n/\n\t/g;
    $filedata{$key} =~ s/\r//g;
    print $FILE "$key: ".$filedata{$key}."\n";
  }
  close($FILE);
}

sub ReadDB {
  # Reads in the DB format that Aneuch wants...
  my $file = shift;
  my @return;
  my %F;
  my $currentkey;	# Current key of the hash that we're reading in
  if(-f "$file") { # If the file exists
    @return = FileToArray($file);
    s/\r//g for @return;
    foreach my $r (@return) {
      if($r =~ m/^\t/) {
        $F{$currentkey} .= "\n$r";
      } else {
        my $e = index($r, ': ');
        $currentkey = substr($r,0,$e);
        $F{$currentkey} = substr($r,$e+2);
      }
    }
    foreach my $key (keys %F) {
      $F{$key} =~ s/\n\t/\n/g;
    }
    return %F;
  } else {
    return ();
  }
}

sub GetSignature {
  my ($author, $url) = @_;
  my $ret = '-- ';
  if(!$url) {
    if(PageExists(ReplaceSpaces($author))) {
      $ret .= "[[$author|$author]] //";
    } else {
      $ret .= "$author //";
    }
  } else {
    $ret .= "[[$url|$author]] //";
  }
  return $ret . (FriendlyTime($TimeStamp))[$TimeZone] . "// ($UserIP)";
}

sub GetDiscussionSeparator {
  return "\n----\n";
}

sub AppendPage {
  my ($file, $content, $user, $url) = @_;
  DoArchive($file);				# Keep history
  $content = UnquoteHTML($content);
  $content =~ s/\r//g;
  if(!$user) { $user = $UserIP; }
  my %F; my %T;
  $F{summary} = $content;
  $F{summary} =~ s/\n//g;
  $F{ip} = $UserIP;
  $F{author} = $user;
  $F{ts} = $TimeStamp;
  $F{hostname} = $Hostname;
  # $archive will be the 1-letter dir under /archive that we're writing to
  my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  if(!-d "$PageDir/$archive") { mkdir "$PageDir/$archive"; }
  if(-f "$PageDir/$archive/$file") {
    %T = GetPage($file);
  } else {
    $T{revision} = 0;
    $T{text} = '';
  }
  $F{revision} = $T{revision} + 1;
  $F{text} = $T{text} . "\n" . $content . "\n\n";
  $F{text} .= GetSignature($user, $url).GetDiscussionSeparator();
  $F{text} =~ s/\r//g;
  StringToFile($T{text}, "$TempDir/old");
  StringToFile($F{text}, "$TempDir/new");
  my $diff = `diff $TempDir/old $TempDir/new`;
  $diff =~ s/\\ No newline.*\n//g;
  $F{diff} = $diff;
  WriteDB("$PageDir/$archive/$file", \%F);
  $content =~ s/\n/ /g;
  if(length($content) > 200) {
    $content = substr($content,0,200).". . .";
  }
  LogRecent($file,$user,$content);
  Index($file);
}

sub ListAllPages {
  my @files = (glob("$PageDir/*/*"));
  s#^$PageDir/.*?/## for @files;
  @files = sort(@files);
  return @files;
}

sub ListAllFiles {
  my @files;
  open my($FL), "grep -rli '^text: #FILE ' $PageDir 2>/dev/null |";
  while(<$FL>) {
    push @files, $1 if m#^$PageDir/.{1}/(.*)$#;
  }
  close($FL);
  return @files;
}

sub ListAllTemplates {
  my @templates;
  open my($FL), "grep -rli '^template: 1' $PageDir 2>/dev/null |";
  while(<$FL>) {
    push @templates, $1 if m#^$PageDir/.{1}/(.*)$#;
  }
  close($FL);
  return @templates;
}

sub ListDeletedPages {
  my @list;
  open my($FILES), "grep -rli '^text: DeletedPage' $PageDir 2>/dev/null |";
  while(<$FILES>) {
    push @list, $1 if m#^$PageDir/.{1}/(.*)$#;
  }
  close($FILES);
  return @list;
}

sub CountAllRevisions {
  # Counts the total number of revisions
  my @files = (glob("$ArchiveDir/*/*"));
  return scalar(@files);
}

sub LatestRevision {
  # Return the highest revision number for a page, or 0 if the page doesn't
  #  exist.
  my $page = shift;
  $page = ReplaceSpaces($page);	# Just in case...
  if(!PageExists($page)) { return 0; }
  my %t = GetPage($page);
  return $t{revision};
}

sub NextRevision {
  # Calls LatestRevision, adds 1, and returns.
  my $page = shift;
  return LatestRevision($page) + 1;
}

sub CountAllComments {
  my @pages = ListAllPages();
  my @discussionpages = grep(/^$DiscussPrefix.*/,@pages);
  my $comments;
  foreach my $pg (@discussionpages) {
    $comments += DiscussCount($pg);
  }
  return $comments;
}

sub CommandDisplay {
  my ($command, $p, $r) = @_;
  $p = "<strong>".QuoteHTML($p)."</strong>";
  if(!defined $CommandsDisplay{$command}) {
    return "was doing &quot;".QuoteHTML($command)."&quot; on page $p";
  }
  my $ret = $CommandsDisplay{$command};
  $ret =~ s/\%s/$p/;
  if($r) {
    $ret .= " (revision <strong>$r</strong>)";
  }
  return $ret;
}

sub AdminForm {
  # Displays the admin login form
  my ($u,$p) = ReadCookie();
  print Form('login','post',
    "User: ".$q->textfield(-name=>'user',-value=>$u,-size=>20,-maxlength=>30),
    " Pass: ".$q->password_field(-name=>'pass',-value=>$p,-size=>20),
    " ".$q->submit(-value=>'Go'));
}

sub DoAdminPassword {
  my ($u,$p) = ReadCookie();
  if(!$u) {
    print $q->p("Presently, you do not have a user name set.");
  } else {
    print $q->p("Your user name is set to '$u'.");
  }
  if(IsAdmin()) {
    print $q->p("You are currently authenticated as a site admin. ".
      "To unset this, clear the \"Pass\" field below, and click \"Go\".");
  }
  AdminForm();
}

sub DoAdminVersion {
  # Display the version information of every plugin listed
  print $q->p('Versions used on this site:');
  print $q->p("aneuch.pl: version $Aneuch::VERSION (build $Aneuch::VERSIONID)".
    ", the <a href='http://www.aneuch.org/' target='_blank'>".
    "Aneuch Wiki Engine</a>");
  foreach my $c (keys %Plugins) {
    print $q->p({-style=>'margin-left:20px;'},"$c: $Plugins{$c}");
  }
  print $q->p("CGI.pm, version ".$CGI::VERSION);
  print $q->p($ENV{'SERVER_SOFTWARE'});
  print $q->p("perl: ".`perl -v`);
  print $q->p("diff: ".`diff --version`);
  print $q->p("grep: ".`grep --version`);
  print $q->p("awk: ".`awk --version`);
}

sub DoAdminIndex {
  # Shows the pageindex
  my @indx = FileToArray("$DataDir/pageindex");
  @indx = sort(@indx);
  print '<p>Note: This displays what is in the page index file. If results '.
    'are inaccurate, please run the "Rebuild page index" task from the '.
    'Admin panel.</p>';
  print "<h3>" . @indx . " pages found.</h3><p>";
  print "<ol>";
  foreach my $pg (@indx) {
    print "<li>".$q->a({-href=>$Url.$pg}, $pg);
    if($CountPageVisits) {
      print " <small><em>(".Commify(GetPageViewCount($pg))." views)</em></small>";
    }
    print "</li>";
  }
  print "</ol></p>";
}

sub RebuildIndex {
  my @files = ListAllPages();
  StringToFile(join("\n",@files)."\n","$DataDir/pageindex");
  return scalar(@files);
}

sub DoAdminReIndex {
  # Re-index the site
  my $files = RebuildIndex();
  print "Reindex complete, $files pages found and added to index.";
}

sub DoAdminRemoveLocks {
  # Force remove all locks...
  my @files = glob("$TempDir/*.lock");
  s!^$TempDir/!! for @files;
  foreach (@files) {
    $_ = m/^([^\\\/]+)$/; $_ = $1;
    unlink $TempDir.'/'.$_;
  }
  print "Removed the following locks:<br/>".join("<br/>",@files);
}

sub DoAdminClearVisits {
  # Clears out $VisitorLog after confirming (too many accidental deletes)
  if(GetParam('confirm','no') eq "yes") {
    if(unlink $VisitorLog) {
      print "Log file successfully cleared.";
    } else {
      print "Error while deleting visitors.log: $!";
    }
  } else {
    print "<p>Are you sure you want to clear the visitor log? ".
      "This cannot be undone.</p>";
    print $q->p(AdminLink('clearvisits', "YES", 'confirm=yes')."&nbsp;&nbsp;".
      $q->a({-href=>"javascript:history.go(-1)"},"NO"));
  }
}

sub DoAdminListVisitors {
  my $lim;
  # If we're getting 'limit='... (to limit by IP)
  if(GetParam('limit',0)) {
    $lim = GetParam('limit');
  }
    print '<form method="get"><input type="hidden" name="do" value="admin"/>
      <input type="hidden" name="page" value="visitors"/>
      <input type="text" name="limit" size="40" value="'.$lim.'" />
      <input type="submit" value="Search"/>';
  if($lim) {
    print " ".AdminLink('visitors',"Remove");
  }
  print "</form>";
  # Display the visitors.log file
  my @lf = FileToArray($VisitorLog);
  @lf = reverse(@lf);	# Most recent entries are on bottom... fix that.
  chomp(@lf);
  if($lim) {
    @lf = grep(/$lim/i,@lf);
  }
  my $curdate;
  print "<h2>Visitor log entries (newest to oldest, ".@lf." entries)</h2>".
    "<p style=\"text-align: left;\">";
  foreach my $entry (@lf) {
    my ($ip,$ts,$pg,$do,$revision,$status,$user) = split(/\t/,$entry);
    my $date = YMD($ts);
    my $time = HMS($ts);
    if($curdate ne $date) {
      print "</p><h2>$date</h2><p style=\"text-align: left;\">";
      $curdate = $date;
    }
    print "$time, user <strong>";
    print QuoteHTML($ip)."</strong> (<strong>".QuoteHTML($user)."</strong>)";
    if($do) {
      print " ".CommandDisplay($do, $pg, $revision);
    } else {
      print " hit page <strong>".QuoteHTML($pg)."</strong>";
      if($revision) { print " (revision <strong>$revision</strong>)"; }
    }
    if($status) {
      print " (<em>$status</em>)";
    }
    print "<br/>";
  }
  print "</p>";
}

sub DoAdminLock {
  if(GetParam('confirm','no') eq "yes") {
    if(-f "$DataDir/lock") {
      if(unlink "$DataDir/lock") {
	print $q->p("Site has been unlocked.");
      } else {
	print $q->p("Error while attempting to unlock the site: $!");
      }
    } else {
      StringToFile("","$DataDir/lock");
      print $q->p("Site has been locked.");
    }
  } else {
    if(-f "$DataDir/lock") {
      print $q->p("Are you sure you want to unlock the site?");
    } else {
      print $q->p("Are you sure you want to lock the site?");
    }
    print $q->p(AdminLink('lock', "YES", 'confirm=yes')."&nbsp;&nbsp;".
      $q->a({-href=>"javascript:history.go(-1)"},"NO"));
  }
}

sub DoAdminBlock {
  my $blocked = FileToString($BlockedList);
  my @bl = split(/\n/,$blocked);
  print "<p><strong>".
    Commify(scalar(grep { length($_) and $_ !~ /^#/ } @bl)).
    "</strong> user(s) blocked. Add an IP address, one per line, ".
    "that you wish to block. Regular expressions are allowed (be careful!). ".
    "Lines that begin with '#' are considered comments and ignored.</p>";
  print Form('blocklist','post',
    $q->textarea(-name=>'blocklist', -rows=>30, -cols=>100, -default=>$blocked),
    "<br/>", $q->submit('Save')
  );
}

sub DoAdminBannedContent {
  my $content = FileToString($BannedContent);
  print "<p><strong>".
    Commify(scalar(grep { length($_) and $_ !~ /^#/ } split(/\n/,$content))).
    "</strong> rules loaded (blank lines and comments don't count).</p>";
  print "<p>CAUTION! This is very powerful! If you're not careful, you can ".
    "easily block all forms of editing on your site.</p>";
  print "<p>Enter regular expressions for content you wish to ban. Any edit ".
    "by a non-administrative user that matches this content will immediately ".
    "be rejected as spam. Any line that begins with a '#' is considered ".
    "a comment, and will be ignored by the parser.</p>";
  print Form('bannedcontent', 'post',
    $q->textarea(-name=>'bannedcontent', -rows=>30, -cols=>100,
      -default=>$content),"<br/>",
    $q->submit('Save')
  );
}

sub DoAdminCSS {
  if(GetParam('action') eq "restore") {
    if(GetParam('confirm') eq "yes") {
      unlink "$DataDir/style.css";
      print "<p>Default stylesheet has been restored.</p>";
    } else {
      print "<p>Are you sure you want to restore the default CSS? This cannot".
	" be undone.</p>";
      print $q->p(AdminLink('css','YES','action=restore','confirm=yes').
	"&nbsp;&nbsp;".$q->a({-href=>'javascript:history.go(-1)'},"NO"));
    }
  } else {
    my $content = DoCSS();
    print "<p>You may edit your site's CSS here. ";
    if(-f "$DataDir/style.css") {
      print AdminLink('css','Restore to default CSS','action=restore');
    } else {
      print "This is the default CSS, and has not been modified.";
    }
    print "</p>";
    print Form('css','post',
      $q->textarea(-name=>'css', -rows=>30, -cols=>100, -default=>$content),
      "<br/>", $q->submit('Save')
    );
  }
}

sub DoAdminListFiles {
  print $q->p("Here is a list of pages that contain uploaded files:");
  print "<ul>";
  foreach (ListAllFiles()) {
    print $q->li($q->a({-href=>$Url.$_}, $_));
  }
  print "</ul>";
}

sub DoAdminListTemplates {
  # Get a list of templates
  print $q->p("Here is a list of pages that are marked as templates:");
  print "<ul>";
  foreach (ListAllTemplates()) {
    print $q->li($q->a({-href=>$Url.$_}, $_));
  }
  print "</ul>";
}

sub DoAdminRobotsTxt {
  my $content = FileToString("$DataDir/robots.txt");
  print $q->p("For more information about robots.txt, see <a href=\"http://www.robotstxt.org/\">http://www.robotstxt.org/</a>");
  print Form('robotstxt', 'post',
    $q->textarea(-name=>'robotstxt', -rows=>30, -cols=>100, -default=>$content),
    "<br/>", $q->submit('Save')
  );
}

sub DoAdminPlugins {
  # Plugin manager!
  # Do we have an action and plugin?
  my $pi = GetParam('plugin');
  my $act = GetParam('act');
  if($pi and $act) {
    if($act eq 'disable' and -f "$PluginDir/$pi") {
      rename "$PluginDir/$pi", "$PluginDir/$pi.disabled";
    }
    if($act eq 'enable' and -f "$PluginDir/$pi.disabled") {
      rename "$PluginDir/$pi.disabled", "$PluginDir/$pi";
    }
    print $q->p("$pi has been ".($act eq 'disable' ? 'disabled' : 'enabled'));
    print AdminLink('plugins',"Return to plugin manager");
    return;
  }

  # Main code
  my @alist = keys %Plugins;
  my $active = @alist;
  my @plist = glob("$PluginDir/*");
  s/^$PluginDir\/// for @plist;
  my @dlist = grep(/\.disabled$/,@plist);
  s/\.disabled$// for (@plist,@dlist);
  my $total = @plist;
  print $q->p("You have $total ".($total eq 1 ? 'plugin' : 'plugins').
    " installed, $active of which ".($active eq 1 ? 'is' : 'are').
    " active.");
  #foreach my $p (@plist) {
  #  print $q->p($q->strong("$p").' '.
  #    (defined $Plugins{$p} ? '(active)' : '(inactive)'));
  #}
  print $q->h3('Active');
  print "<ul>";
  foreach (@alist) {
    print $q->li(AdminLink('plugins',$_,"plugin=$_",'act=disable').
      ' - '.$Plugins{$_});
  }
  print "</ul>";
  print $q->h3('Disabled');
  print "<ul>";
  foreach (@dlist) {
    print $q->li(AdminLink('plugins',$_,"plugin=$_",'act=enable'));
  }
  print "</ul>";
}

sub DoAdminDeleted {
  my @deleted = ListDeletedPages();
  print $q->p("Here is a list of pages that are pending delete:");
  print "<ul>";
  foreach my $item (@deleted) {
    my %f = GetPage($item);
    print $q->li($q->a({-href=>$Url.$item}, $item).
      " to be deleted after ".
      (FriendlyTime($f{ts} + $PurgeDeletedPage))[$TimeZone]);
  }
  print "</ul>";
}

sub DashboardDatabase {
  print $q->h3('Database Info');
  print "<p>There are currently ".
    AdminLink('index',Commify(scalar(ListAllPages()))." pages").
    " and ".Commify(CountAllRevisions()).
    " page revisions stored in the database.";
  if($CountPageVisits) {
    print " There are ".AdminLink('visitors',Commify(GetTotalViewCount()).
      " total page views").".";
  }
  print "</p>";
  print $q->p('There are '.
    AdminLink('files',Commify(scalar(ListAllFiles()))." uploaded files").
    ' and '.AdminLink('templates',
      Commify(scalar(ListAllTemplates()))." templates").".");
}

sub DashboardBannedContent {
  print $q->h3('Banned Content');
  my $content = FileToString($BannedContent);
  print $q->p("Your site is protected against certain types of content by ".
    AdminLink('bannedcontent',
      Commify(scalar(grep { length($_) and $_ !~ /^#/ } split(/\n/,$content))).
    " rules").".");
}

sub DashboardBannedUsers {
  print $q->h3('Banned Users');
  my $content = FileToString($BlockedList);
  print $q->p("You have entered ".
    AdminLink('block',
      Commify(scalar(grep { length($_) and $_ !~ /^#/ } split(/\n/,$content))).
      " rules").
    " for blocking users via IP address.");
}

sub DoAdminDashboard {
  print $q->h2('Dashboard');
  my $active = keys %Plugins;
  print $q->p('This is Aneuch, '.
    AdminLink('version',"version $VERSION (build $VERSIONID)").
    " with ".
    AdminLink('plugins',"$active loaded ".
      ($active eq 1 ? 'plugin' : 'plugins')).'.');
  my ($u,$p) = ReadCookie();
  print "<p>You are currently authenticated as '$u' and ".
    ((IsAdmin()) ? 'are' : 'are not').
    " an administrator.</p>";
  print Form('login','post',
    $q->hidden(-name=>'user', -value=>$u).
    $q->hidden(-name=>'pass', -value=>'').
    $q->submit(-value=>'Log out')
  );

  # Do dashboard items
  foreach (@DashboardItems) {
    &{$_};
  }
}

sub DoAdmin {
  # Command? And can we run it?
  #if($Page and $AdminActions{$Page}) {
  #  if($Page eq 'password' or IsAdmin()) {
  #    &{$AdminActions{$Page}};	# Execute it.
  #    print $q->p(AdminLink('',"&larr; Admin Menu"));
  #  }
  #} else {
  #  print '<p>You may:<ul><li><a href="'.$Url.
  #  '?do=admin;page=password">Authenticate</a></li>';
  #  if(IsAdmin()) {
  #    my %al = reverse %AdminList;
  #    foreach my $listitem (sort keys %al) {
#	unless($listitem eq '') {
#	  print $q->li(AdminLink($al{$listitem},$listitem));
#	}
  #    }
  #  }
  #  print '</ul></p>';
  #  print '<p>This site has ' . Commify(scalar(ListAllPages())) . ' pages, '.
  #    Commify(CountAllRevisions()).' revisions';
  #  if($CountPageVisits) {
  #    print ", and ".Commify(GetTotalViewCount()).' page views';
  #  }
  #  print ".</p>";
  #}

  # Set default page
  if($Page eq 'admin') {
    $Page = (IsAdmin()) ? 'dashboard' : 'password';
  }

  # Set the description for lock action
  # NOTE: The line below does nothing currently.
  #$AdminList{'lock'} = (-f "$DataDir/lock") ? 'Unlock the site' : 'Lock the site';

  #print '<div class="admin">';
  print '<table width=100%><tr valign=top><td class="admin">';
  print "<ul>";
  if($Page eq 'password') {
    print $q->li({class=>'current'},AdminLink('password','Authenticate'));
  } else {
    print $q->li(AdminLink('password','Authenticate')) unless IsAdmin();
  }
  if(IsAdmin()) {
    if($Page eq 'dashboard') {
      print $q->li({class=>'current'},AdminLink('dashboard','Dashboard'));
    } else {
      print $q->li(AdminLink('dashboard','Dashboard'));
    }
    my %al = reverse %AdminList;
    foreach my $listitem (sort keys %al) {
      next if $listitem eq '';
      if($Page eq $al{$listitem}) {
	print $q->li({class=>'current'},AdminLink($al{$listitem},$listitem));
      } else {
	print $q->li(AdminLink($al{$listitem},$listitem));
      }
    }
  }
  #print '</div>'; #End of admin menu, now print page
  print "</td><td style='padding-left:20px;'>";
  #print '<div style="padding-left:10px;">';
  if($Page and $AdminActions{$Page}) {
    if($Page eq 'password' or IsAdmin()) {
      &{$AdminActions{$Page}};
    }
  }
  #print '</div>';
  #print '<div style="clear:both;"></div>'; #End of admin
  print '</td></tr></table>';
}

sub Init {
  InitScript();
  InitConfig();
  InitVars();
  #InitDirs();		# Now called inside InitVars();
  #DoPostInit();
  LoadPlugins();
  DoPostInit();
  #InitTemplate();
}

sub RedHerringForm {
  # This sub will print the "red herring" or honeypot form. This is an
  #  anti-spam measure.
  return '<form action="'.$ScriptName.'" method="post" style="display:none;">'.
    '<input type="hidden" name="doing" value="commenting" />'.
    '<input type="hidden" name="file" value="'.$Page.'" />'.
    'Name: <input type="text" name="hname" size="20" /><br/>'.
    'Message:<br/><textarea name="htext" cols="80" rows="5"></textarea>'.
    '<input type="submit" value="Save" /></form>';
}

sub StartForm {
  my $method = shift;
  $method ||= 'post';
  return $q->start_multipart_form(-method=>$method, -action=>$ScriptName);
}

sub Form {
  my ($doing, $method, @elements) = @_;
  my $return;
  $return = StartForm($method);
  $return .= $q->hidden(-name=>'doing', -value=>$doing);
  foreach (@elements) {
    $return .= $_;
  }
  $return .= "</form>";
  return $return;
}

sub AntiSpam {
  # Provides several anti-spam features to forms

  # If we're an admin user, we probably don't need this.
  if(IsAdmin()) { return; }

  # Let's do a hidden value, maybe?

  # If the %QuestionAnswer hash is empty, forget about it.
  if(!%QuestionAnswer) {	# Evaluates the hash in scalar context, returns
    return;			#  0 if there are 0 elements, which with the
  } else {			#  '!' used here, will match and exit.
    my $question = (keys %QuestionAnswer)[rand keys %QuestionAnswer];
    return $q->hidden(-name=>'session',
      -value=>unpack("%32W*", $question) % 65535).$q->br.$q->br.
      "$question&nbsp;".$q->textfield(-name=>'answer', -size=>'30').'&nbsp;';
  }
}

sub IsBannedContent {
  # Checks the edit for banned content.
  # If we have an uploaded file, return false
  if(GetParam('text') =~ m/^#FILE /) { return 0; }
  my @bc = FileToArray($BannedContent);
  @bc = grep { length($_) and $_ !~ /^#/ } @bc;
  foreach my $c (@bc) {
    # If trailing comments...
    $c = (split("#",$c))[0];
    if(GetParam('text') =~ m/$c/i) {
      return 1;
    }
  }
  return 0;
}

sub PassesSpamCheck {
  # Checks to see if the form submitted passes all spam checks. Returns 1 if
  #  passed, 0 otherwise.
  my $session = GetParam('session');
  my $answer = GetParam('answer');

  if(IsAdmin()) { return 1; }	# If admin, assume passed.
  # Check BannedContent
  if(IsBannedContent()) { return 0; }
  # If there are no questions, assume passed
  if(!%QuestionAnswer) { return 1; }
  # If the form was sumbitted without "question" or if it wasn't defined, fail
  if(!$session) {
    return 0;
  }
  # If the form was submitted without the answer or it wasn't defined, fail
  if(!$answer or Trim($answer) eq '') {
    return 0;
  }
  # Check the answer against the question asked
  my %AnswerQuestions = reverse %QuestionAnswer;
  $answer = lc($answer);
  if((!exists $AnswerQuestions{$answer}) or (!defined $AnswerQuestions{$answer})) {
    return 0;
  }
  my $question = $AnswerQuestions{$answer};
  # "Checksum" of the question
  my $qcs = unpack("%32W*",$question) % 65535;
  # If checksum doesn't match, don't pass
  if($qcs != $session) { return 0; }
  # Nothing else? Return 1.
  return 1;
}

sub DoDiscuss {
  # Displays the discussion form
  my $newtext;# = $NewComment;
  if(!CanDiscuss()) {
    return;
  }
  # Check if a preview exists
  if(-f "$TempDir/$Page.$UserIP") {
    # If the preview is older than 10 seconds, remove it and don't display it
    if((stat("$TempDir/$Page.$UserIP"))[9] < ($TimeStamp - 10)) {
      unlink "$TempDir/$Page.$UserIP";
    } else {
      $newtext = FileToString("$TempDir/$Page.$UserIP");
      print "<div class=\"preview\">".Markup($newtext)."</div>";
      my @ta = split(/\n\n/,$newtext); pop @ta;
      $newtext = join("\n\n", @ta);
    }
  }
  print RedHerringForm();
  print "<p id=\"discuss-form\"></p><form action='$ScriptName' method='post'>
    <input type='hidden' name='doing' value='discuss' />
    <input type='hidden' name='file' value='$Page' />
    <textarea name='text' style='width:100%;' placeholder='$NewComment'"; 
    print" cols='80' rows='10'>$newtext</textarea><br/><br/>
    Name: <input type='text' name='uname' size='30' value='$UserName' /> 
    URL (optional): <input type='text' name='url' size='50' />";
  print AntiSpam();
  print " <input type='submit' name='whattodo' value='Save' />
    <input type='submit' name='whattodo' value='Preview' /></form>";
  print '<script language="javascript" type="text/javascript">'.
    "function ShowHide() {
	document.getElementById('discuss-help').style.display = (document.getElementById('discuss-help').style.display == 'none') ? 'block' : 'none';
	document.getElementById('showhidehelp').innerHTML = (document.getElementById('showhidehelp').innerHTML == 'Show markup help') ? 'Hide markup help' : 'Show markup help';
	return true; }".
    '</script>';
  print "<br/><a title=\"Markup help\" id=\"showhidehelp\"".
    "href=\"#discuss-form\" onclick=\"ShowHide();\">".
    "Show markup help</a>";
  print "<br/><div id=\"discuss-help\" style=\"display:none;\">";
  MarkupHelp();
  print "</div>";
}

sub DoRecentChanges {
  print "<hr/>";
  my @rc;
  my $curdate;
  my $tz;
  my $openul=0;
  @rc = FileToArray($RecentChangesLog);
  if($TimeZone == 0) {
    $tz = "UTC";
  } else {
    $tz = strftime "%Z", localtime(time);
  }
  # If none, say so.
  if(($rc[0] eq "") or (@rc == 0)) {
    print "No recent changes.";
    return;
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
      print "<strong>$day</strong><ul>";
      $openul = 1;
    }
    print "<li>$tme $tz (".
      CommandLink('history', $ent[1], 'history').") ";
    print "<a href='$Url$ent[1]'>$ent[1]</a> . . . . ";
    if(PageExists(ReplaceSpaces($ent[2]))) {
      print "<a href='$Url$ent[2]'>$ent[2]</a> &ndash; ";
    } else {
      print "$ent[2] &ndash; ";
    }
    print QuoteHTML($ent[3])."</li>";
  }
}

sub DoLinkedPages {
  # There are a couple of ways we can do this. We can call DoSearch() on the
  #  regex below, which is slow, or we can use grep -P which is fast (but
  #  might not be portable).
  if(!PageExists($Page)) {
    print $q->p("That doesn't appear to be a valid page.");
    return;
  }
  my $searchparam = $Page;
  $searchparam =~ s/_/[ _]/g;
  $Param{'search'} = '\[\['.$searchparam.'[|\]]';
  print "<h2>Pages that link to '<a href=\"${ShortUrl}$Page\">$Page</a>'</h2>";
  chomp(my @files = `grep -Prl '$Param{'search'}' $PageDir`);
  s/$PageDir\/.{1}\/// for @files;
  print "<ul>";
  foreach (@files) {
    print "<li><a href=\"${ShortUrl}$_\">$_</a></li>";
  }
  print "</ul>";
}

sub DoDownload {
  my %F = GetPage(GetParam('page'),GetParam('revision',''));
  if($F{text} =~ m/^#FILE (\S+) ?(\S+)?\n/) {
    # We've got a raw file
    my @lines = split(/\n/,$F{text});
    shift @lines;
    $F{text} = join("\n", @lines);
    my %headers = ( -type=>$1 );
    $headers{-Content_Encoding} = $2 if $2;
    print $q->header(%headers);
    require MIME::Base64;
    print MIME::Base64::decode($F{text});
  } else {
    ErrorPage(400, "Something terribly wrong has happend, and I'll be honest,".
      " I've got nothing...");
  }
  return;
}

sub DoRobotsTxt {
  my $contents = FileToString("$DataDir/robots.txt");
  print "Content-type: text/plain\n\n";
  print $contents;
}

sub DoSearchShortCode {
  my $search = shift;
  my @searchextras;
  return unless $search;
  if($search =~ /|/) {
    @searchextras = split(/|/,$search);
    shift @searchextras;
  }
  my $searchtext = $search; $searchtext =~ s/ /+/g;
  return "<a href=\"$Url?do=search;search=$searchtext\" ".
    "title=\"Search for '$searchtext'\">$search</a>";
}

sub DoSearch {
  ## NOTE: /x was removed from the match regex's below as it broke search
  ##   for terms that included spaces... Not sure why I had /x to begin with.

  # First, get a list of all files...
  my @files;
  my $search = UnquoteHTML(GetParam('search',''));
  if($search eq '') {
    print "<p>What in the world are you searching for!?</p>";
    return;
  }
  my $altsearch = ReplaceSpaces($search);
  # Should we show summaries?
  my $showsummary = GetParam('showsummary',1);
  if($showsummary !~ /\d/) {	# Is numeric?
    $showsummary = 1;
  }
  #quotemeta($search);
  #quotemeta($altsearch);
  my %result;
  # Get the list of files whos file names match
  @files = grep(/.*?($search|$altsearch).*?/i,ListAllPages());
  # Search the innards of the files
  open my($FILES), "grep -Erli '($search|$altsearch)' $PageDir 2>/dev/null |";
  while(<$FILES>) {
    push @files, $1 if m#^$PageDir/.{1}/(.*)$#;
  }
  # Sort by last modification time
  # NOTE: This is not going to work, seeing as how we strip the directory info
  s#^$PageDir/.*?/## for @files;
  close($FILES);
  print "<p>Search results for &quot;$search&quot;</p>";
  foreach my $file (@files) {
    my $fn = $file;
    my $linkedtopage;
    my $matchcount;
    $fn =~ s#^$PageDir/.*?/##;
    my %F = GetPage($fn);
    if($fn =~ m/.*?($search|$altsearch).*?/i) {
      $linkedtopage = 1;
      $result{$fn} = '<small>Last modified '.
	(FriendlyTime($F{ts}))[$TimeZone]."</small><br/>";
    }
    # If it's an uploaded file, we're not going to search it's contents.
    next if $F{text} =~ m/^#FILE /;
    while($F{text} =~ m/(.{0,75}($search|$altsearch).{0,75})/gsi) {
      if(!$linkedtopage) {
	$linkedtopage = 1;
	$result{$fn} = '<small>Last modified '.
	  (FriendlyTime($F{ts}))[$TimeZone]."</small><br/>";
      }
      if($matchcount == 0) { $result{$fn} .= " . . . "; }
      my $res = QuoteHTML($1); 
      $res =~ s#(.*?)($search|$altsearch)(.*?)#$1<strong>$2</strong>$3#gsi;
      $result{$fn} .= "$res . . . ";
      $matchcount++;
    }
  }
  # Now sort them by value...
  my @keys = sort {length $result{$b} <=> length $result{$a}} keys %result;
  foreach my $key (@keys) {
    print "<big><a href='$Url$key'>$key</a></big><br/>";
    if($showsummary) {
      print $result{$key}."<br/>";
    } else {
      print "".(split("<br/>",$result{$key}))[0]."<br/>";
    }
    print "<br/>";
  }
  print scalar(@keys)." pages found.";
  if((scalar(@keys) == 0) and CanEdit()) {
    print $q->em("Perhaps you'd like to ".
      CommandLink('edit',ReplaceSpaces($search),
	"create a page called ".ReplaceSpaces($search),
	"Create page ".ReplaceSpaces($search))."?");
  }
}

sub SearchForm {
  my $ret;
  my $search = UnquoteHTML(GetParam('search',0));
  $ret = "<form class='searchform' action='$Url' method='get'>".
    "<input type='hidden' name='do' value='search' />".
    "<input type='text' name='search' size='40' placeholder='Search' ";
  if($search) {
    $ret .= "value='$search' ";
  }
  $ret .= "/> <input type='submit' value='Search' /></form>";
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
  return $html; #$q->escapeHTML($html);
}

sub UnquoteHTML {
  my $text = shift;
  return $q->unescapeHTML($text);
}

sub DoHistory {
  my $author; my $summary; my %f;
  my $topone = " checked";
  if(PageExists($Page)) {
    %f = GetPage($Page);
    my $currentday = YMD($f{ts});
    my $linecount = (split(/\n/,$f{text}));
    my $wordcount = @{[ $f{text} =~ /\S+/g ]};
    my $scharcount = length($f{text}) - (split(/\n/,$f{text}));
    my $charcount = $scharcount - ($f{text} =~ tr/ / /);
    print "<p><strong>History of $Page</strong><br/>".
      "The most recent revision number of this page is $f{'revision'}. ";
    if($CountPageVisits) {
      print "It has been viewed ".Commify(GetPageViewCount($Page))." time(s). ";
    }
    print "It was last modified ".(FriendlyTime($f{'ts'}))[$TimeZone].
      " by ".QuoteHTML($f{author}).". ".
      "There are ".Commify($linecount)." lines of text, ".Commify($wordcount).
      " words, ".Commify($scharcount)." characters with spaces and ".
      Commify($charcount)." without. ".
      "The total page size (including metadata) is ".Commify((stat("$PageDir/$ShortDir/$Page"))[7])." bytes.";
    print "</p>";
    # If the page is set for deletion, let them know
    if($f{text} =~ m/^DeletedPage\n/) {
      print $q->p($q->em("This page is scheduled to be deleted after ".
	$q->strong((FriendlyTime($f{ts} + $PurgeDeletedPage))[$TimeZone])));
    }
    print $q->p(CommandLink('links',$Page,"See all pages that link to $Page"));
    print "<form action='$Url' method='get'>";
    print "<input type='hidden' name='do' value='diff' />";
    print "<input type='hidden' name='page' value='$Page' />";
    print "<input type='submit' value='Compare' />";
    print "<table><tr><td colspan='3'><strong>$currentday</strong></td></tr>";
    print "<tr valign='top'><td><input type='radio' name='v1' value='cur'>".
      "</td><td><input type='radio' name='v2' value='cur' checked></td>";
    print "<td>" . HM($f{ts}) . " (current) ".
      "<a href=\"$Url$Page\">Revision " . $f{revision} . "</a>";
    if(PageExists(ReplaceSpaces($f{author}))) {
      print " . . . . <a href=\"$Url" . QuoteHTML($f{author}) . "\">".
        QuoteHTML($f{author}) . "</a>";
    } else {
      print " . . . . ".QuoteHTML($f{author});
    }
    print " ($f{ip}) &ndash; " . QuoteHTML($f{summary}) . "</td></tr>";

    if($ArchiveDir and $ShortDir and -d "$ArchiveDir/$ShortDir") {
      my @history = (glob("$ArchiveDir/$ShortDir/$Page.*"));
      # This sort MUST be done by file mod time the way archive is currently
      #  laid out (file.x, file.xx, etc).
      @history = sort { -M $a <=> -M $b } @history;
      foreach my $c (@history) {
	# This next line needs to use ReadDB as it references a full path
	%f = ReadDB($c); #GetPage($c);
	my $nextrev;
        my $day = YMD($f{ts});
        if($day ne $currentday) {
	  $currentday = $day;
	  print "<tr><td colspan='3'><strong>$day</strong></td></tr>";
	}
	if($f{revision} == 1) {
	  $nextrev = '';
	} else {
	  $nextrev = 'v1='.($f{revision} - 1).';v2='.$f{revision};
	}
	print "<tr valign='top'><td><input type='radio' name='v1'".
	  "value='$f{revision}'$topone></td><td><input type='radio' name='v2'".
	  " value='$f{revision}'></td>";
	if($topone) { $topone = ''; }
	print "<td>".HM($f{ts})." ".
	  "<input type=\"button\" onClick=\"location.href='$Url?do=".
	  "edit;page=$Page;revision=$f{revision};summary=".
	  "Revert to Revision ".$f{revision}." (".
	  (FriendlyTime($f{ts}))[$TimeZone].")'\" ".
	  "value=\"Revert\"> ".
	  CommandLink('',$Page,"Revision $f{revision}",
	    "View revision $f{revision}","revision=$f{revision}");
	if(PageExists(QuoteHTML($f{author}))) {
	  print " . . . . <a href=\"$Url" . QuoteHTML($f{author}) . "\">".
	    QuoteHTML($f{author}) . "</a>";
	} else {
	  print " . . . . ".QuoteHTML($f{author});
	}
        print " ($f{ip}) &ndash; " . QuoteHTML($f{summary}) . "</td></tr>";
      }
    }
    print "</table><input type='submit' value='Compare'></form>";
  } else {
    print "<p>No log entries found.</p>";
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
  my %F;
  # First off, we need to save a temp file...
  my $tempfile = $Page.".".$UserName;
  # Save contents to temp file
  $F{revision} = GetParam('revision');
  $F{text} = UnquoteHTML(GetParam('text'));
  $F{summary} = UnquoteHTML(GetParam('summary'));
  $F{template} = GetParam('template');
  WriteDB("$TempDir/$tempfile", \%F);
}

sub ReDirect {
  my ($loc,$status) = @_;
  if(defined $status) {
    print $q->redirect(-uri=>$loc, -status=>$status, %HTTPHeader);
  } else {
    print $q->redirect(-uri=>$loc, %HTTPHeader);
  }
}

sub DoPostingSpam {
  # Someone submitted the red herring form!
  my $redir = $Url;
  $redir .= GetParam('file')."?do=spam";
  ReDirect($redir);
}

sub DoPostingLogin {
  SetCookie(GetParam('user'), GetParam('pass'));
  ReDirect($Url."?do=admin");
}

sub DoPostingEditing {
  my $redir;
  if(CanEdit()) {
    # Set user name if not already done
    my ($u, $p) = ReadCookie();
    if($u ne GetParam('uname') or !$u) {
      SetCookie(GetParam('uname'), $p);
    }
    if(GetParam('whattodo') eq "Cancel") {
      UnLock(GetParam('file'));
      my @tfiles = (glob("$TempDir/".GetParam('file').".*"));
      foreach my $file (@tfiles) { unlink $file; }
    } elsif(GetParam('whattodo') eq "Preview") {
      Preview(GetParam('file'));
      $redir = 1;
    } else {
      # We need to check for locks, first!
      if(-f "$TempDir/$Page.lock") {
	chomp(my @lock = FileToArray("$TempDir/$Page.lock"));
	my ($u, $p) = ReadCookie();
	if(($lock[0] ne $UserIP) or ($lock[1] ne $u)) {
	  # Not the right user
	  ErrorPage(409,"This file is locked by another user. ".
	    "Please try again.");
	  return;
	}
      }
      if(GetParam('text') =~ m/^#FILE /) {
	ErrorPage(403,"File uploads can only be done through the upload page.");
	return;
      }
      if(PassesSpamCheck()) {
	WritePage(GetParam('file'), GetParam('text'), GetParam('uname'));
      } else {
        DoPostingSpam();
        return;
      }
    }
  }
  if($redir) {
    ReDirect($Url."?do=edit;page=".GetParam('file'));
  } else {
    ReDirect($Url.GetParam('file'));
  }
}

sub DoPostingDiscuss {
  if(CanDiscuss()) {
    # Check for uploading file
    if(GetParam('text') =~ m/^#FILE /) {
      ErrorPage(403,"File uploads can only be done through the upload page.");
      return;
    }
    if(GetParam('whattodo') eq "Preview" or PassesSpamCheck()) {
      # Set user name if not already done
      my ($u, $p) = ReadCookie();
      if($u ne GetParam('uname') or !$u) {
	SetCookie(GetParam('uname'), $p);
      }
      if(GetParam('whattodo') eq "Save") {
	if(-f "$TempDir/".GetParam('file').".$UserIP") {
	  unlink "$TempDir/".GetParam('file').".$UserIP";
	}
	AppendPage(GetParam('file'), GetParam('text'), GetParam('uname'),
	  GetParam('url'));
      } elsif(GetParam('whattodo') eq "Preview") {
	StringToFile(GetParam('text')."\n\n".GetSignature(GetParam('uname'),
	  GetParam('url')).GetDiscussionSeparator(),
	  "$TempDir/".GetParam('file').".$UserIP");
      } else {
	# What!?
      }
    } else {
      DoPostingSpam();
    }
  }
  ReDirect($Url.GetParam('file')."#discuss-form");
}

sub DoPostingBlockList {
  if(IsAdmin()) {
    StringToFile(GetParam('blocklist'), $BlockedList);
  }
  ReDirect($Url."?do=admin;page=block");
}

sub DoPostingBannedContent {
  if(IsAdmin()) {
    StringToFile(GetParam('bannedcontent'), $BannedContent);
  }
  ReDirect($Url."?do=admin;page=bannedcontent");
}

sub DoPostingCSS {
  if(IsAdmin()) {
    StringToFile(GetParam('css'), "$DataDir/style.css");
  }
  ReDirect($Url."?do=admin;page=css");
}

sub DoPostingRobotsTxt {
  if(IsAdmin()) {
    StringToFile(GetParam('robotstxt'), "$DataDir/robots.txt");
  }
  ReDirect($Url."?do=admin;page=robotstxt");
}

sub DoPostingUpload {
  if(GetParam('whattodo') eq "Cancel") {
    ReDirect($Url.GetParam('file'));
    return;
  }
  if(CanEdit() and CanUpload()) {
    my $file = $q->upload('fileupload');
    my $type = $q->uploadInfo(GetParam('fileupload'))->{'Content-Type'};
    unless(CanUpload($type)) {
      ErrorPage(415, "Sorry, that file type is not allowed.");
      return;
    }
    my $rs = $/;
    local $/ = undef;
    my $contents = <$file>;
    my $encoding = 'gzip' if substr($contents,0,2) eq "\x1f\x8b";
    eval { require MIME::Base64; $_ = MIME::Base64::encode($contents) };
    my $cont = "#FILE $type $encoding\n$_";
    local $/ = $rs;
    WritePage(GetParam('file'), $cont, $UserName);
  }
  ReDirect($Url.GetParam('file'));
}

sub DoPosting {
  SetParam('do','posting');
  my $action = GetParam('doing');
  my $file = GetParam('file', '<'.GetParam('doing','not specified').'>');
  # Remove all slashes from file name (if any)
  $file =~ s!/!!g;
  # Remove any leading periods
  $file =~ s/^\.+//g;
  $Page = $file;
  # Now set the param to its sanitized value
  SetParam('file',$file);
  if($action and $PostingActions{$action}) {	# Does it exist?
    &{$PostingActions{$action}};		# Run it
  }
}

sub DoVisit {
  # Log a visit to the visitor log
  my $mypage = (GetParam('do') eq 'search') ? GetParam('search','') : $Page;
  $mypage =~ s/ /+/g;
  if(GetParam('revision') and !$PageRevision) {
    $PageRevision = GetParam('revision');
  }
  if($MaxVisitorLog > 0) {
    my $logentry = "$UserIP\t$TimeStamp\t$mypage\t".GetParam('do','').
      "\t$PageRevision\t$HTTPStatus\t$UserName";
    open my($LOGFILE), '>>', $VisitorLog;
    flock($LOGFILE, LOCK_EX);		# Lock, exclusive
    seek($LOGFILE, 0, SEEK_END);	# In case data was appeded after lock
    print $LOGFILE "$logentry\n";
    close($LOGFILE);			# Lock is removed upon close
  }
  if($CountPageVisits and PageExists($Page) and !GetParam('do',0)) {
    my %f = ReadDB($PageVisitFile);
    if(defined $f{$Page}) {
      $f{$Page}++;
    } else {
      $f{$Page} = 1;
    }
    WriteDB($PageVisitFile, \%f);
  }
}

sub DoMaintPurgeTemp {
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

sub DoMaintPurgeRC {
  # Remove old RC entries
  # First, read the RC file
  chomp(my @rclines = FileToArray($RecentChangesLog));
  my @newrc;
  # Determine cutoff
  my $cutoff = $TimeStamp - $PurgeRC;
  # Walk through the entries, and remove them if they are older...
  foreach my $entry (@rclines) {
    if((split(/\t/,$entry))[4] > $cutoff) {
      push @newrc, $entry;
    }
  }
  my $rcout = join("\n",@newrc) . "\n";
  if(@newrc != @rclines) {	# Only write out if there's a difference!
    StringToFile($rcout, $RecentChangesLog);
  }
}

sub DoMaintPurgeOldRevs {
  # Purge old revisions...
  # If -1, simply exit as the admin wants to keep all revisions
  if($PurgeArchives == -1) { return; }
  # Determine the timestamp for removal
  my $RemoveTime = $TimeStamp - $PurgeArchives;
  # Get list of files
  my @files = glob("$ArchiveDir/*/*.*");
  # Walk through each file and remove if it's older...
  foreach my $f (@files) {
    if((stat("$f"))[9] <= $RemoveTime) { unlink $f; }
  }
}

sub DoMaintTrimVisit {
  # Trim visitor log...
  # Open file and lock it...
  chomp(my @lf = FileToArray($VisitorLog));	# Read in
  if(scalar @lf > $MaxVisitorLog) {
    open my($LOGFILE), '>', $VisitorLog or return;	# Return if can't open
    flock($LOGFILE,LOCK_EX) or return;	# Exclusive lock or return
    seek($LOGFILE, 0, SEEK_SET);	# Beginning
    @lf = reverse(@lf);
    my @new = @lf[0 .. ($MaxVisitorLog - 1)];
    @lf = reverse(@new);
    seek($LOGFILE, 0, SEEK_SET);	# Return to the beginning
    print $LOGFILE "" . join("\n", @lf) . "\n";
    close($LOGFILE);
  }
}

sub DoMaintDeletePages {
  # Delete pages that are marked "DeletedPage" and older than $PurgeDeletedPage
  my @list;
  my @files;
  my @archives;
  my $RemoveTime = $TimeStamp - $PurgeDeletedPage;
  @list = ListDeletedPages();
  # Go through @list, see what is over $PurgeDeletedPage
  foreach my $listitem (@list) {
    my %f = GetPage($listitem);
    if($f{ts} < $RemoveTime) { push @files, $listitem; }
  }
  if(@files) {
    foreach my $file (@files) {
      my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
      unlink "$PageDir/$archive/$file";
      @archives = grep { /^$ArchiveDir\/$archive\/$file.\d+/ } 
	glob("$ArchiveDir/$archive/$file.*");
      foreach (@archives) {
	unlink $_;
      }
      # Remove entries from rc.log
      chomp(my @rclines = FileToArray($RecentChangesLog));
      my @newrc = grep(!/^\d{14}\t$file\t.*$/, @rclines);
      my $rcout = join("\n",@newrc) . "\n";
      if(@newrc != @rclines) {      # Only write out if there's a difference!
	StringToFile($rcout, $RecentChangesLog);
      }
    }
    RebuildIndex();	# Removes the deleted page from the page index
  }
}

sub DoMaint {
  # Run each maintenance task
  foreach my $key (keys %MaintActions) {	# Step through list, and...
    &{$MaintActions{$key}};		# Execute
  }
}

sub StringToFile {
  my ($string, $file) = @_;
  if($file =~ /^([-\@\w.\/]+)$/) {
    $file = $1;
  } else { die "StringToFile: Bad data in '$file'"; }
  open my($FILE),'>', $file or push @Messages,
    "StringToFile: Can't write to $file: $!";
  flock($FILE,LOCK_EX);		# Exclusive lock
  seek($FILE, 0, SEEK_SET);	# Beginning
  print $FILE $string;
  close($FILE);
}

sub AppendStringToFile {
  # Appends string to file
  my ($string, $file) = @_;
  my $current = FileToString($file);
  $current .= "\n$string";
  StringToFile($current, $file);
}

sub FileToString {
  my $file = shift;
  return join("\n", FileToArray($file));
}

sub FileToArray {
  my $file = shift;
  my @return;
  open my($FILE), '<', $file or push @Messages,
    "FileToArray: Can't read from $file: $!";
  chomp(@return = <$FILE>);
  close($FILE);
  s/\r//g for @return;
  return @return;
}

sub GetDiff {
  my ($old, $new) = @_;
  my %OldFile = ReadDB("$ArchiveDir/$ShortDir/$old");
  my %NewFile;
  if(($new =~ m/\.\d+$/) and (-f "$ArchiveDir/$ShortDir/$new")) {
    %NewFile = ReadDB("$ArchiveDir/$ShortDir/$new");
  } else {
    %NewFile = ReadDB("$PageDir/$ShortDir/$new");
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
  # If there are no more arguments, assume we want most recent diff
  if(!GetParam('v1') and !GetParam('v2')) {
    my %F = GetPage($Page);
    print "Showing changes to the most recent revision";
    print HTMLDiff($F{diff});
    print "<hr/>";
    if(defined &Markup) {
      print Markup($F{text});
    } else {
      print $F{text};
    }
  } else {
    my %rv;
    if(!GetParam('v1')) {
      SetParam('v1', GetParam('v2'));
    }
    foreach my $v ('v1', 'v2') {
      if(GetParam($v) ne 'cur') { $rv{$v} = GetParam($v); }
    }
    my %F;
    my $oldrev = "$Page.$rv{v1}";
    my $newrev = defined $rv{v2} ? "$Page.$rv{v2}" : "$Page";
    print "<p>Comparing revision $rv{v1} to ".
      (defined $rv{v2} ? $rv{v2} : "current") . " of page ".
      "<a href=\"$Url$Page\">$Page</a></p>";
    print HTMLDiff(GetDiff($oldrev, $newrev));
    print "<hr/>";
    if(($newrev =~ m/\.\d+$/) and (-f "$ArchiveDir/$ShortDir/$newrev")) {
      %F = ReadDB("$ArchiveDir/$ShortDir/$newrev");
    } else {
      %F = ReadDB("$PageDir/$ShortDir/$newrev");
    }
    if($F{text} !~ m/^#FILE /) {
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
  if($count < 1) {
    push @files, $DefaultPage;
    $count = 1;
  }
  my $randompage = int(rand($count));
  ReDirect($Url.$files[$randompage]);
}

sub PageExists {
  my ($pagename, $revision) = @_;
  # $archive will be the 1-letter dir under /archive that we're writing to
  my $archive = substr($pagename,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  if($revision and $revision !~ m/\d+/) {
    $revision = '';
  }
  if($revision and -f "$ArchiveDir/$archive/$pagename.$revision") {
    return 1;
  } elsif(-f "$PageDir/$archive/$pagename" and !$revision) {
    return 1;
  } else {
    return 0;
  }
}

sub DiscussCount {
  # Returns the number of comments on a Discuss page
  my $pg = shift;
  $pg = $pg ? $pg : $Page;
  if(PageExists("${DiscussPrefix}${pg}")) {
    my $DShortDir = substr($DiscussPrefix,0,1); $DShortDir =~ tr/[a-z]/[A-Z]/;
    my %DiscussPage = ReadDB("$PageDir/$DShortDir/${DiscussPrefix}${pg}");
    my @comments = split(GetDiscussionSeparator(), $DiscussPage{text});
    return scalar(@comments);
  } else {
    return 0;
  }
}

sub DoSpam {
  # Someone posted spam, now tell them about it.
  print "It appears that you are attempting to spam $Page. ".
    "Please don't do that.";
}

sub IsBlocked {
  if(!-f $BlockedList) { return 0; }
  foreach my $blocked (FileToArray($BlockedList)) {
    next if $blocked =~ /^#/;
    if($UserIP =~ m/$blocked/) { return 1; }
  }
  return 0;
}

sub ReplaceSpaces {
  my $replacetext = shift;
  $replacetext =~ s/\s/_/g;
  return $replacetext;
}

sub StripMarkup {
  # Returns only alphanumeric... essentially wiping out any characters that
  #  might be used in the markup syntax.
  my $ret = shift;
  $ret =~ s/[^a-zA-Z0-9 _-]//g;
  return $ret;
}

sub ErrorPage {
  (my $code, my $message) = @_;
  my %codes = (
    400 => '400 Bad Request',
    403 => '403 Forbidden',
    404 => '404 Not Found',
    409 => '409 Conflict',
    415 => '415 Unsupported Media Type',
    500 => '500 Internal Server Error',
    501 => '501 Not Implemented',
    503 => '503 Service Unavailable',
  );

  my $header;
  if($codes{$code}) {
    $header = "Status: $codes{$code}\n";
    $HTTPStatus = $codes{$code};
  }
  $header .= "Content-type: text/html\n\n";
  print $header;
  print "<html><head><title>$codes{$code}</title></head><body>";
  print '<h1 style="border-bottom: 2px solid rgb(0,0,0); font-size:medium; margin: 4ex 0px 1ex; padding:0px;">'.$codes{$code}.'</h1>';
  print "<p>$message</p>";
  print '</body></html>';
  #exit 1;
}

sub DoSurgeProtection {
  # We need to check if there have been a large number of requests
  # If neither of the variables are defined, or if they are 0, get out of here
  return 0 unless $SurgeProtectionTime or $SurgeProtectionCount;
  # If the user is an admin, let's go ahead and forgive them
  return 0 if IsAdmin();
  # Get the time in the past we're starting to look
  my $spts = $TimeStamp - $SurgeProtectionTime;
  # Now, count the elements that match
  chomp(my @counts = split(/\n/,`grep ^$UserIP $VisitorLog | awk '\$2>$spts'`));
  if($#counts >= $SurgeProtectionCount) {
    # Surge protection has been triggered! Give an error page and bug out.
    return 1;
  } else {
    return 0;
  }
}

sub IsDiscussionPage {
  # Determines if the current page is a discussion page
  if($Page =~ m/^$DiscussPrefix/ and $DiscussPrefix ne '') {
    return 1;
  } else {
    return 0;
  }
}

sub CommandLink {
  my ($do, $pg, $text, $title, @extras) = @_;
  my $ret;
  $ret = $Url;
  if($pg) { $ret .= $pg; }
  $ret .= "?";
  $ret .= "do=$do" if $do;
  if($do and @extras) { $ret .= ";"; }
  $ret .= join(';',@extras) if @extras;
  return $q->a({-href=>$ret, -title=>$title, -rel=>'nofollow'}, $text);
}

sub AdminLink {
  my ($pg, $text, @extras) = @_;
  my $ret;
  $ret = $Url . "?do=admin";
  $ret .= ";page=$pg" if $pg;
  $ret .= ";".join(';',@extras) if @extras;
  return $q->a({-href=>$ret, -rel=>'nofollow'}, $text);
}

sub DoRequest {
  # Blocked?
  if(IsBlocked()) {
    #$HTTPStatus = "Status: 403 Forbidden\n";
    #print $HTTPStatus . "Content-type: text/html\n\n";
    #print '<html><head><title>403 Forbidden</title></head><body>'.
    #  "<h1>Forbidden</h1><p>You've been banned. Please don't come back.</p>".
    #  "</body></html>";
    ErrorPage(403, "You've been banned. Please don't come back.");
    return;
  }

  # Surge protection
  if(DoSurgeProtection()) {
    ErrorPage(503, "You've attempted to fetch more than $SurgeProtectionCount pages in $SurgeProtectionTime seconds.");
    return;
  }

  # Can view?
  unless(CanView()) {
    ReDirect($Url."?do=admin;page=password");
    return;
  }

  # Raw handler?
  if(IsRawHandler(GetParam('do','')) and $Commands{GetParam('do')}) {
    &{$Commands{GetParam('do')}};
    return;
  }

  # Are we receiving something?
  if(GetParam('doing')) {
    DoPosting();
    return;
  }

  # Command does not exist? Let's die.
  if(GetParam('do') and !$Commands{GetParam('do')}) {
    ErrorPage(501,"The action '".GetParam('do')."' has not been registered.");
    return;
  }

  # Seeking a revision?
  my $rev = GetParam('revision','');
  if($rev and $rev !~ m/\d+/) { $rev = ''; }

  # Check if page exists or not, and not calling a command
  if(!PageExists($Page, $rev) and !GetParam('do') and !$Commands{GetParam('do')}) {
    $HTTPStatus = "404 Not Found";
  }

  # Build $SearchPage
  $SearchPage = $PageName;    # SearchPage is PageName with + for spaces
  $SearchPage =~ s/Search for: //;
  $SearchPage =~ s/ /+/g;     # Change spaces to +

  # HTTP Header
  if($HTTPStatus) {
    $HTTPHeader{'-status'} = $HTTPStatus
  }

  print $q->header(%HTTPHeader);

  # Header
  #print Interpolate($Header);
  DoHeader();
  # This is where the magic happens
  if(GetParam('do') and $Commands{GetParam('do')}) {
    &{$Commands{GetParam('do')}};
  } else {
    if(!PageExists($Page)) {
      print $NewPage;
    } else {
      %Filec = GetPage($Page, $rev);
      if($rev and !PageExists($Page, $rev)) {
	print $q->p("That revision of ".$q->a({-href=>"$Url$Page"}, $Page).
	  " does not exist!");
      }
      if($Filec{template} == 1) {
	print $q->p({-style=>"font-style: italic; color: red;"},
	  "This page is a template, and likely doesn't contain any useful ".
	  "information.");
      }
      if($Filec{text} =~ m/^DeletedPage\n/) {
	print $q->p($q->em("This page is scheduled to be deleted after ".
	  $q->strong((FriendlyTime($Filec{ts} + $PurgeDeletedPage))[$TimeZone])));
      }
      if($rev and PageExists($Page, $rev)) {
	print $q->p({-style=>"font-weight: bold;"}, 
	  "You are viewing Revision $Filec{revision} of ".
	  $q->a({-href=>"$Url$Page"}, $Page).$q->hr);
      }
      if($Filec{text} =~ m/^#FILE /) {
	print $q->p("This page contains a file:");
	print $q->pre(CommandLink('download',$Page,
          ($Filec{filename}) ? $Filec{filename} : $Page, 'View file',
          (GetParam('revision')) ? 'revision='.GetParam('revision') : ''));
      } elsif(exists &Markup) {	# If there's markup defined, do markup
	print Markup($Filec{text});
      } else {
	print join("\n", $Filec{text});
      }
    }
    if($Filec{ts}) {
      $MTime = "Last modified: ".(FriendlyTime($Filec{ts}))[$TimeZone]." by ".
	$Filec{author} . "<br/>";
    }
    DoSpecialPage();
  }
  if($Debug) {
    $DebugMessages = join("<br/>", @Messages);
  }
  # Footer
  DoFooter();
}

## START
Init();		# Load
DoRequest();	# Handle the request
DoVisit();	# Log visitor
DoMaint();	# Run maintenance commands
1;		# In case we're being called elsewhere

# Everything below the DATA line is the default CSS

__DATA__
html
{
  font-family: sans-serif;
  font-size: 1em;
}

body
{
  padding:0;
  margin:0;
}

pre
{
  overflow: auto;
  word-wrap: break-word; /*normal;*/
  /*border: 1px solid rgb(204, 204, 204);
  border-radius: 2px 2px 2px 2px;
  box-shadow: 0px 0px 0.5em rgb(204, 204, 204) inset;*/
  margin-left: 1em;
  padding: 0.7em 1em;
  font-family: Consolas,"Andale Mono WT","Andale Mono","Bitstream Vera Sans Mono","Nimbus Mono L",Monaco,"Courier New",monospace;
  font-size: 1em;
  direction: ltr;
  text-align: left;
  /*background-color: rgb(251, 250, 249);
  color: rgb(51, 51, 51);*/
}

#container
{
  /*margin: 0 30px;*/
  background: #fff;
}

#header
{
  /*background: #ccc;*/
  background: rgb(230, 234, 240); /*rgb(243,243,243);*/
  border:1px solid rgb(221,221,221);
  padding: 15px;
  color: rgb(68, 119, 255);
}

#header h1
{
  margin: 0;
  display:inline;
  color: rgb(68, 119, 255);
  font-size: 20pt;
}

#header a {
  text-decoration: none;
  color: rgb(68, 119, 255);
}

#header h1 a
{
  color: rgb(68, 119, 255);
  text-decoration:none;
}

#header a:hover {
  color: green;
  text-decoration: underline;
}

#searchbox {
  float:right;
  clear:left;
}

.navigation
{
  float: left;
  width: 100%;
  background: #333;
  /*background:rgb(214, 228, 249);*/
}

.navigation ul
{
  margin: 0;
  padding: 0;
}

.navigation ul li
{
  list-style-type: none;
  display: inline;
}

.navigation li a
{
  display: block;
  float: left;
  padding: 5px 10px;
  color: #fff;
  text-decoration: none;
  border-right: 1px solid #fff;
}

.navigation li a:hover {
  background: rgb(129, 187, 242);/*#383;*/
  color: #000;
}

.navigation li a.active {
  background: rgb(129, 187, 242);
  color: #000;
}

#identifier {
  float:right;
  font-size:0.9em;
  color:white;
  padding:5px;
}

#content
{
  clear: left;
  padding: 20px;
  text-align:justify;
  position:relative;
  font-size: 1.05em;
}

#content img
{
  padding:5px;
  margin:10px;
  /*border:1px solid rgb(221,221,221);
  background-color: rgb(243,243,243);
  border-radius: 3px 3px 3px 3px;*/
}

#content a
{
  color:rgb(68, 119, 255);
  text-decoration: none;
}

#content a:hover
{
  text-decoration: underline;
  color:green;
}

#content a.external:hover
{
  text-decoration: underline;
  color:red;
}

#content h2
{
  color: #000;
  font-size: 160%;
  margin: 0 0 .5em;
}

#content hr {
  border:none;
  color:black;
  background-color:#000;
  height:2px; 
  margin-top:2ex;
}

#markup-help
{
  border: 1px solid #8CACBB;
  background: #EEEEFF;
  padding: 10px;
  margin-top: 20px;
  font-size: 0.9em;
  font-family: "Courier New", Courier, monospace;
}

#markup-help dt
{
  font-weight: bold;
}

#footer
{
  /*background: #ccc;
  text-align: right;*/
  background:rgb(230, 234, 240); /*rgb(243,243,243);*/
  border:1px solid rgb(221,221,221);
  padding: 15px;
  height: 1%;
  clear:left;
}

#mtime {
  color:gray;
  font-size:0.75em;
  float:right;
  font-style: italic;
}

#content .toc {
  /*float:right;*/
  background-color: rgb(230, 234, 240);
  padding:5px;
  margin:10px;
  border: 1px solid rgb(221,221,221);
  border-radius: 3px 3px 3px 3px;
  /*font-size:0.9em;*/
  position:absolute;
  top:0;
  right:0;
}

textarea {
  border-color:black;
  border-style:solid;
  border-width:thin;
  padding: 3px;
  width: 100%;
}

input {
  border-color:black;
  border-style:solid;
  border-width:thin;
  padding: 3px;
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

.admin {
  background-color: #333;
  width:250px;
  /*position: relative;
  float: left;*/
}

.admin ul {
  margin: 0;
  padding: 0;
  list-style-type: none;
}

.admin ul li a {
  text-decoration: none;
  color: white !important;
  padding: 10px;
  /*background-color: #47F;*/
  display: block;
  border-bottom: 1px solid #fff;
}

.admin ul li.current a, .admin ul li a:hover {
  color: #000 !important;
  background-color: rgb(129,187,242);
  text-decoration: none !important;
}
