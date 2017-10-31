#!/usr/bin/perl -wT
## **********************************************************************
## Copyright (c) 2012-2017, Aaron J. Graves (cajunman4life@gmail.com)
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
     $PurgeDeletedPage, $VERSIONID, @DashboardItems, $CookieTime, $SpamLogging, 
     %Prefs, $HasReadPrefs);

my %srvr = (
  80 => 'http://',	443 => 'https://',
);

$VERSION = '0.60';	# Set version number
$VERSIONID = '0060';	# Version ID

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
  # Define settings
  $DataDir = '/tmp/aneuch' unless $DataDir;	# Location of docs
  $DefaultPage = 'HomePage' unless $DefaultPage; # Default page
  @Passwords = qw() unless @Passwords;		# No password by default
  $SiteMode = 0 unless $SiteMode;		# 0=All, 1=Discus only, 2=None
  # Discussion page prefix
  $DiscussPrefix = 'Discuss_' unless defined $DiscussPrefix;
  $SiteName = 'Aneuch' unless $SiteName;	# Default site name
  $CookieName = 'Aneuch' unless $CookieName;	# Default cookie name
  $CookieTime = 31556926 unless $CookieTime; # 1 year cookie expiration
  $TimeZone = 0 unless $TimeZone;		# Default to GMT, 1=localtime
  $LockExpire = 60*5 unless $LockExpire;	# 5 mins, unless set elsewhere
  $Debug = 0 unless $Debug;			# Assume no debug
  $MaxVisitorLog = 1000 unless $MaxVisitorLog;	# Keep at most 1000 entries in
						#  visitor log
  $RemoveOldTemp = 60*60*24*7 unless $RemoveOldTemp; # > 7 days
  $PurgeRC = 60*60*24*14 unless $PurgeRC;	# > 14 days
  $PurgeArchives = -1 unless $PurgeArchives;	# Default to keep all!
  $Theme = "" unless $Theme;		# No theme by default
  $FancyUrls = 1 unless defined $FancyUrls;	# Use fancy urls w/.htaccess
  # If $FancyUrls, remove $ShortScriptName from $ShortUrl
  if(($FancyUrls) and ($ShortUrl =~ m/$ShortScriptName/)) {
    $ShortUrl =~ s/$ShortScriptName//;
    $Url =~ s/$ShortScriptName//;
  } else {
    $ShortUrl .= "/";
    $Url .= "/";
  }
  $NewComment = 'Add your comment here.' unless $NewComment;
  # $SurgeProtectionTime is the number of seconds in the past to check hits
  $SurgeProtectionTime = 20 unless defined $SurgeProtectionTime;
  # $SurgeProtectionCount is the number of hits in the defined amount of time
  $SurgeProtectionCount = 20 unless defined $SurgeProtectionCount;
  # Count the number of visits to each page
  $CountPageVisits = 1 unless defined $CountPageVisits;
  $UploadsAllowed = 0 unless $UploadsAllowed;	# Do not allow uploads
  # The list of allowable uploads (MIME types)
  @UploadTypes = qw(image/gif image/png image/jpeg) unless @UploadTypes;
  # Blog pattern
  $PurgeDeletedPage = 60*60*24*14 unless $PurgeDeletedPage; # > 2 weeks
  # Spam logging
  $SpamLogging = 0 unless $SpamLogging; # Off
  # Have preferences been read? No, of course not.
  $HasReadPrefs = 0;

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
  #$Page =~ s/^\/{1,}//;
  #$Page = QuoteHTML($Page);
  if($Page ne SanitizeFileName($Page)) {
    $Page = SanitizeFileName($Page);
    ReDirect($Url.$Page);
    exit 0;
  }
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
  #$PageName =~ s/_/ /g;		# Change underscore to space
  $PageName = ReplaceUnderscores($PageName);

  $ShortDir = substr($Page,0,1);	# Get first letter
  $ShortDir =~ tr/[a-z]/[A-Z]/;		# Capitalize it

  # New page and new comment default text
  $NewPage = "This page doesn't exist." unless $NewPage;

  # Discuss, edit links
  if(!GetParam('do') or GetParam('do') eq "revision") {
    if($DiscussPrefix) {
      if($Page !~ m/^$DiscussPrefix/) {	# Not a discussion page
	$DiscussLink = $Url . $DiscussPrefix . $Page;
	$DiscussText = $DiscussPrefix;
	$DiscussText =~ s/_/ /g;
	$DiscussText .= ReplaceUnderscores($Page) . " (".DiscussCount().")";
	$DiscussText = '<a title="'.$DiscussText.'" href="'.$DiscussLink.'">'.
	  $DiscussText.'</a>';
      } else {				# Is a discussion page
	$DiscussLink = $Page;
	$DiscussLink =~ s/^$DiscussPrefix//;	# Strip discussion prefix
	$DiscussText = ReplaceUnderscores($DiscussLink);
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
  ($UserIP) = ($UserIP =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/);
  ($UserName) = &ReadCookie;
  # Get the hostname
  eval 'use Socket; $Hostname = gethostbyaddr(inet_aton($UserIP), AF_INET);';
  $Hostname = $UserIP unless $Hostname;
  # Set the username (unless it's already set)
  if(!$UserName) {
    $UserName = ($Hostname and $Hostname ne '.') ? $Hostname : $UserIP;
  }

  # Navbar
  #$NavBar = "<ul id=\"navbar\">";
  #$NavBar = "<ul class=\"nav navbar-nav\">";
  foreach ($DefaultPage, 'RecentChanges', @NavBarPages) {
    $NavBar .= '<li><a href="'.$Url.ReplaceSpaces($_).'" title="'.$_.'"';
    if($Page eq ReplaceSpaces($_)) {
      $NavBar .= ' class="active"';
    }
    $NavBar .= '>'.$_.'</a></li>';
  }
  #$NavBar .= "</ul>";

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
  # Download for files
  RegCommand('download', \&DoDownload, 'downloaded the file %s');
  # Raw viewer
  RegCommand('view', \&DoView, 'viewed the file %s');
  # robots.txt support
  RegCommand('robotstxt', \&DoRobotsTxt, 'was getting %s');
  # Remove revisions
  RegCommand('rmrev', \&DoRemoveRevision, 
    'was purging a revision of page %s');

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
  if($SpamLogging) {
    RegAdminPage('spamlog', "View spam log", \&DoAdminSpamLog);
  }

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
  RegPostAction('quickedit', \&DoPostingQuickedit);	# Quick edit

  # Register raw handlers
  RegRawHandler('download');
  RegRawHandler('view');
  RegRawHandler('random');
  RegRawHandler('robotstxt');
  RegRawHandler('spam');

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
    # Default header!
    print <<EOF;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <meta name="generator" content="Aneuch $VERSION" />
    <title>$PageName - $SiteName</title>

    <!-- Bootstrap -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" 
	integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css"
	integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" 
	integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous">
    </script>

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
    <style type="text/css">
EOF
    print DoCSS();
    print <<EOF;
    </style>
  </head>
  <body>

    <nav class="navbar navbar-inverse navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="$Url">$SiteName</a>
        </div>
        <div id="navbar" class="collapse navbar-collapse">
          <ul class="nav navbar-nav">
EOF
    my $counter = 1;
    foreach ($DefaultPage, 'RecentChanges', @NavBarPages) {
      print '<li><a href="'.$Url.ReplaceSpaces($_).'" title="'.$_.'"';
      if($Page eq ReplaceSpaces($_)) {
	print ' class="active"';
      }
      print '>'.$_.'</a></li>';
      $counter++;
      if($counter == 3) {
	print '<li class="dropdown">'.
          '<a href="#" class="dropdown-toggle" data-toggle="dropdown" '.
	  'role="button" aria-haspopup="true" aria-expanded="false">More '.
	  '<span class="caret"></span></a>'.
          '<ul class="dropdown-menu">';
      }
    }
    my $search = GetParam('search','');
    print <<EOF;
            </ul></li>
          </ul>
EOF
    print SearchForm();
    print <<EOF;
        </div><!--/.nav-collapse -->
      </div>
    </nav>

    <div class="container"
EOF
    if((CanEdit()) and (!IsDiscussionPage()) and (!GetParam('do'))) {
      print " ondblclick=\"window.location.href='$Url?do=edit;page=$Page'\"";
    }
    print '>';
    print '      <div class="aneuch-content">'.
      '        <div class="page-header">'.
      '          <h1>';
    if(PageExists($Page)) {
      print "<a title=\"Search for references to $SearchPage\" ".
	"rel=\"nofollow\" href=\"$Url?do=search;search=".
	"$SearchPage\">$PageName</a>";
    } else {
      print "$PageName";
    }
    print '          </h1>'.
      '        </div>';
    # end of default theme header
  } else {
    # Not the default
    if(-f "$ThemeDir/$Theme/head.pl") {
      do "$ThemeDir/$Theme/head.pl";
    } elsif(-f "$ThemeDir/$Theme/head.html") {
      print Interpolate(FileToString("$ThemeDir/$Theme/head.html"));
    }
  }
}

sub DoFooter {
  if(!$Theme or !-d "$ThemeDir/$Theme") {
    # Default theme footer
    print <<EOF;
      </div> <!-- /aneuch-content -->
    </div> <!-- /container -->

    <nav class="navbar navbar-default">
      <div class="container">
	<div class="navbar-header">
          <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#footernavbar" aria-expanded="false" aria-controls="navbar">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
	  <span class="visible-xs navbar-brand">Page Actions</span>
        </div>
        <div id="footernavbar" class="collapse navbar-collapse">
          <ul class="nav navbar-nav">
EOF
    # If we want discussion pages
    if($DiscussPrefix) {
      print "<li>$DiscussText</li>";
    }
    print <<EOF;
            <li>$EditText</li><li>$RevisionsText</li><li>$AdminText</li><li>$RandomText</li>
          </ul>
	</div>
      </div>
  </nav>

    <footer class="footer">
      <div class="container">
EOF
    if(PageExists($Page)) {
      print Commify(GetPageViewCount($Page))." view(s).&nbsp;&nbsp;";
    }
print <<EOF;
        $MTime
      </div>
      <div class="container">
        $PostFooter
      </div>
    </footer>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
  </body>
</html>
EOF
    # End of default theme footer
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
  # Unquote
  $href = UnquoteHTML($href);
  if($href =~ m/^mailto:/i) { # Mailto link
    # If the test is the same as the href, we'll want to remove the leading
    #  mailto: portion of the link, so that it's relatively clean output.
    if($same) {
      $text =~ s/^mailto://i;
    }
    $return = $q->a({-class=>'external',-rel=>'nofollow',
      -title=>$href,-href=>$href},$text);
  }
  elsif(($href =~ m/^htt(p|ps):/i) and ($href !~ m/^$url/i)) { # External link!
    $return = $q->a({-class=>'external',-rel=>'nofollow',
      -title=>'External link: '.$href,-target=>'_blank',-href=>$href},$text);
  } else {			# Internal link!
    my $testhref = (split(/#/,$href))[0];
    $testhref = (split(/\?/,$testhref))[0];
    if((PageExists(ReplaceSpaces($testhref))) or ($testhref =~ m/^\?/)
     or (ReplaceSpaces($testhref) =~ m/^$DiscussPrefix/)
     or ($testhref =~ m/^$url/) or ($testhref eq '') or (!CanEdit())) {
      $return = "<a title='".ReplaceSpaces($href)."' href='";
      if(($href !~ m/^$url/) and ($href !~ m/^[#\?]/)) {
	$return .= $Url.ReplaceSpaces($href);
      } else {
	$return .= $href;
      }
      $return .= "'>".$text."</a>";
    } else {
      $return = "[<span style=\"border-bottom: 1px dashed #FF0000;\">".
	"$text</span>".
	CommandLink('edit', SanitizeFileName($href), '?',
	  "Create page \"".SanitizeFileName($href)."\"")."]";
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
    $return .= "$Url".ReplaceSpaces($img)."?do=view\" ";
  } else {
    $return .= "$img\" ";
  }
  if($alt) {
    $return .= "alt=\"$alt\" ";
  }
  $return .= 'class="img-responsive';
  if($align) {
    $return .= " pull-$align";
  }
  $return .= '" />';
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
  my $blockquote = 0;		# Blockquote
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

    # Start blockquote?
    if(!$blockquote and $line =~ m/^\s{4}/) {
      $blockquote = 1;
      push @build, "<blockquote>";
    }

    # Start UL
    if($line =~ m/^[\s\t]*(\*{1,})[ \t]/) {
      if(!$openul) { $openul=1; }
      $ulstep=length($1);
      if($ulstep > $ulistlevel) {
        until($ulistlevel == $ulstep) { push @build, "<ul>"; $ulistlevel++; }
      } elsif($ulstep < $ulistlevel) {
        until($ulistlevel == $ulstep) { push @build, "</ul>"; $ulistlevel--; }
      }
    }

    # Start OL
    if($line =~ m/^[\s\t]*(#{1,})/) {
      if(!$openol) { $openol=1; }
      $olstep=length($1);
      if($olstep > $olistlevel) {
        until($olistlevel == $olstep) { push @build, "<ol>"; $olistlevel++; }
      } elsif($olstep < $olistlevel) {
        until($olistlevel == $olstep) { push @build, "</ol>"; $olistlevel--; }
      }
    }

    # End UL
    if(($openul) && ($line !~ m/^[\s\t]*\*{1,}[ \t]/)) {
      $openul=0;
      until($ulistlevel == 0) { push @build, "</ul>"; $ulistlevel--; }
    }

    # End OL
    if(($openol) && ($line !~ m/^[\s\t]*#{1,}/)) {
      $openol=0;
      until($olistlevel == 0) { push @build, "</ol>"; $olistlevel--; }
    }

    # End blockquote?
    if($blockquote and $line !~ m/^\s{4}/) {
      $blockquote = 0;
      push @build, "</blockquote>";
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

    # <tt>/<samp>
    $line =~ s#\`{1}(.*?)\`{1}#<samp>$1</samp>#g;

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
    if($prevblank and ($build[$i] !~ m/^<(h|div|blockquote|ol|ul|li)/) and ($build[$i] ne '')) {
      $prevblank = 0;
      if((!$openp) and ($build[$i] !~ m!^</!)) {
        $build[$i] = "<p>".$build[$i];
        $openp = 1;
      }
    }
    if(($build[$i] =~ m!^</blockquote>$!) and ($openp)) {
      $build[$i-1] .= "</p>"; $openp = 0;
    }
    if(($build[$i] =~ m/^<(h|div|blockquote|ol|ul|li)/) || ($build[$i] eq '')) {
      $prevblank = 1;
      if(($i > 0) and ($build[$i-1] !~ m/^<(h|div)/) and ($openp)) {
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

  print '<br/><button type="button" class="btn btn-xs btn-info" data-toggle="collapse" '.
    'data-target="#discuss-help">Show markup help</button>';
  #print $q->div({-class=>'collapse', -id=>'discuss-help'}, MarkupHelp());
  print '<div id="discuss-help" class="collapse">';

  print '<div class="well" id="markup-help"><dl>'.
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

  print '</div>';
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
    if($Page =~ m/^$spage$/) {
      #print '<div class="markup-content">';
      &{$SpecialPages{$spage}};
      #print '</div>';
      return;
    }
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

sub GetPrefs {
  my ($prefix, $name) = @_;
  if(!$HasReadPrefs) {
    %Prefs = ReadDB($DataDir.'/preferences');
    $HasReadPrefs = 1;
  }
  # Are we looking for the available namespace? If so, return the list.
  if(($name eq '*') or ($name eq '')) {
    my @allkeys = keys %Prefs;
    my @ns = grep { $_ =~ /$prefix\./ } @allkeys;
    # Remove the prefix from the namespace list.
    s/^$prefix\.// for @ns;
    return @ns;
  } else {
    # Otherwise return the one value.
    return $Prefs{"$prefix.$name"};
  }
}

sub SetPrefs {
  my ($prefix, $name, $value) = @_;
  if(!$HasReadPrefs) {
    # Call GetPrefs on a random variable. We don't care what it is.
    GetPrefs('Aneuch','Test');
  }
  $Prefs{"$prefix.$name"} = $value;
  # Now save our changes
  WriteDB($DataDir.'/preferences', \%Prefs);
}

sub DelPrefs {
  my ($prefix, $name) = @_;
  if(!$HasReadPrefs) {
    # Call GetPrefs on a random variable. We don't care what it is.
    GetPrefs('Aneuch','Test');
  }
  delete $Prefs{"$prefix.$name"};
  WriteDB($DataDir.'/preferences', \%Prefs);
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

sub SanitizeFileName {
  my $file = shift;
  $file = ReplaceSpaces(Trim($file));
  # Remove double dots
  while($file =~ m/\.\./) {
    #$file =~ s/\/[^\/]*\/\.\.//;
    $file =~ s/\.+//;
  }
  # Remove leading underscores
  while($file =~ m/^_/) {
    $file =~ s/^_+//;
  }
  $file =~ s/[^a-zA-Z0-9._~#-]//g;
  return $file;
}

sub InitDirs {
  # Sets the directories, and creates them if need be.
  ($DataDir) = ($DataDir =~ /^([-\/\w.]+)$/); # Untaint
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
  my ($user, $pass, $exp) = @_;
  $exp ||= $CookieTime;  
  #my $matchedpass = grep(/^$pass$/, @Passwords); # Did they provide right pass?
  my $matchedpass = 0;
  foreach my $p (@Passwords) {
    if($pass eq $p) { $matchedpass = 1; }
  }
  my $cookie = $user if $user;		# Username first, if they gave it
  if($matchedpass and $user) {		# Need both...
    $cookie .= ':' . $pass;
  }
  my $futime = gmtime($TimeStamp + $exp)." GMT";	# Now + expiration time
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
  #return scalar(grep(/^$p$/, @Passwords));
  my $matchedpass = 0;
  foreach my $password (@Passwords) {
    if($p eq $password) { $matchedpass = 1; }
  }
  return $matchedpass;
}

sub CanEdit {
  # If lock is set, return false automatically
  if(-f "$DataDir/lock") { return 0; }
  my ($u, $p) = ReadCookie();
  #my $matchedpass = grep(/^$p$/, @Passwords);a
  my $matchedpass = 0;
  foreach my $password (@Passwords) {
    if($p eq $password) { $matchedpass = 1; }
  }
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
    } elsif(GetParam('doing') eq 'login') {
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
    print $q->div({-class=>'alert alert-warning'},
      "Note: This page is defined as a special page, ".
      "and as such its final state may be different from what you see here.");
  }

  if($preview) {
    #print $q->div({-class=>'alert alert-warning'},Markup($contents));
    print $q->div({-class=>'panel panel-primary'},
      $q->div({-class=>'panel-heading'},
	$q->h3({-class=>'panel-title'},'Preview')
      ),
      $q->div({-class=>'panel-body'},
	$q->div({-class=>'markup-content'},Markup($contents))
      )
    );
  }

  if($canedit) {
    print RedHerringForm();
    # Template select
    print StartForm('get', '').
      $q->div({-class=>'row'}, $q->div({-class=>'col-md-3'},
      $q->div({-class=>'form-group'},
	$q->hidden(-name=>'do', -value=>'edit'),
	$q->hidden(-name=>'page', -value=>$Page),
	$q->label({-for=>'use_templates'},'Use template: '),
	$q->popup_menu(-name=>'use_template', -values=>\@templates,
	  -onchange=>'this.form.submit()', -class=>'form-control'),
	$q->hidden(-name=>'clear', -value=>1)
      )));
    print $q->end_form();
  }

  # This has to be done outside of the if($canedit) otherwise it won't be
  #  there for non-editing users.
  print '<div class="form-group">';
  #  '<div class="row">',
  #    '<div class="col-md-12">';

  if($canedit) {
    # Main edit form
    print StartForm();
    my $doing = (GetParam('upload')) ? 'upload' : 'editing';
    print $q->hidden(-name=>'doing', -value=>$doing),
	  $q->hidden(-name=>'file', -value=>$Page),
	  $q->hidden(-name=>'revision', -value=>$revision);
    if(-f "$PageDir/$ShortDir/$Page") {
      print $q->hidden(-name=>'mtime', -value=>(stat("$PageDir/$ShortDir/$Page"))[9]);
    }
  }
  if(GetParam('upload')) {
    print $q->p("File to upload: ".$q->filefield(-name=>'fileupload',
      -size=>50, -maxlength=>100, -class=>"form-control"));
  } else {
    print $q->textarea(-name=>'text', -cols=>'100', -rows=>'25',
      -class=>'form-control', -default=>$contents);
  }
  print '</div>'; # /col-md-12
  #  '</div>'.     # /row
  #  '</div>';     # /form-group

  # For templates
  print $q->div({-class=>'form-group'},
    #$q->div({-class=>'row'},
    #  $q->div({-class=>'col-md-12'},
	$q->checkbox(-name=>'template', -checked=>$template, -value=>'1',
	  -label=>'Is this page a template?',
	  -title=>'Check this to save this page as a template',
	  -class=>'form-control')
	#)
      #)
    );

  if($canedit) {
    # Set a lock
    if($preview or SetLock()) {

      print $q->div({-class=>'form-group'},
	#$q->div({-class=>'row'},
	#  $q->div({-class=>'col-md-12'},
	    $q->label({-for=>'summary'},"Summary:"),
	    $q->textarea(-name=>'summary',
	      -cols=>'100', -rows=>'2', -class=>'form-control',
	      -placeholder=>'Edit summary (required)', -default=>$summary)
	#  )
	#)
      );

      print $q->div({-class=>'form-group'},
        #$q->div({-class=>'row'},
	#  $q->div({-class=>'col-md-4'},
	    $q->label({-for=>'uname'},"User name:"),
	    $q->textfield(-name=>'uname',-size=>'30', -value=>$UserName, 
	      -class=>'form-control')
	  #),
      );
      print $q->div({-class=>'form-group'},
	  #$q->div({-class=>'col-md-4'},
	    AntiSpam()
	  #),
      );
      print '<div class="form-group">';
	  #$q->div({-class=>'col-md-4'},
	  #  $q->div({-class=>'btn-group'},
      if(GetParam('upload')) {
	print $q->submit(-name=>'whattodo', -value=>'Upload', -class=>'btn btn-success').' ';
      } else {
	print $q->submit(-name=>'whattodo', -value=>'Save', -class=>'btn btn-success').' '.
	$q->submit(-name=>'whattodo', -value=>'Preview', -class=>'btn btn-primary').' ';
      }
      print $q->submit(-name=>'whattodo', -value=>'Delete', -class=>'btn btn-danger'),
	" ".$q->submit(-name=>'whattodo', -value=>'Cancel', -class=>'btn btn-warning');
      print '</div>';
    }

    print $q->end_form;
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
  #$pg =~ m/^([^\\\/]+)$/; $pg = $1;
  ($pg) = ($pg =~ /^([a-zA-Z0-9._~#-]*)$/);
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
  $file = SanitizeFileName($file);
  ($TempDir) = ($TempDir =~ /^([-\/\w.]+)$/);
  ($file) = ($file =~ /^([a-zA-Z0-9._~#-]*)$/);
  ($UserName) = ($UserName =~ /^([a-zA-Z0-9._~#-]*)$/);
  if(-f "$TempDir/$file.$UserName") {	# Remove preview files
    unlink "$TempDir/$file.$UserName";
  }
  # $archive will be the 1-letter dir under /archive that we're writing to
  my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  ($archive) = ($archive =~ /^([A-Z0-9]{1})$/);
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
    # Untaint $TempDir. This is a little bit of a flub though, because
    #  there shouldn't be any way an end-user can modify $TempDir, so we're
    #  assuming that $TempDir is absolutely fine.
    my ($TD) = ($TempDir =~ /^([-\/\w.]+)$/g);
    $diff = `diff $TD/old $TD/new`;
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
  #open my($FILE), '>:encoding(UTF-8)', $filename or push @Messages,
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
  # Untaint $TempDir. Because an end-user shouldn't be able to modify this,
  #  we're assuming that it's perfectly clean.
  my ($TD) = ($TempDir =~ /^(.*)$/g);
  my $diff = `diff $TD/old $TD/new`;
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
  #my @files = (glob("$PageDir/*/*"));
  #s#^$PageDir/.*?/## for @files;
  #@files = sort(@files);
  my @files;
  my $force = shift;
  $force ||= 0;
  if($force) {
    @files = (glob("$PageDir/*/*"));
    s#^$PageDir/.*?/## for @files;
    @files = sort(@files);
  } else {
    @files = sort(FileToArray("$DataDir/pageindex"));
  }
  return @files;
}

sub ListAllFiles {
  my @files;
  my ($PD) = ($PageDir =~ /^(.*)$/g);
  open my($FL), "grep -rli '^text: #FILE ' $PD 2>/dev/null |";
  while(<$FL>) {
    push @files, $1 if m#^$PageDir/.{1}/(.*)$#;
  }
  close($FL);
  @files = sort @files;
  return @files;
}

sub ListAllTemplates {
  my @templates;
  my ($PD) = ($PageDir =~ /^(.*)$/g);
  open my($FL), "grep -rli '^template: 1' $PD 2>/dev/null |";
  while(<$FL>) {
    push @templates, $1 if m#^$PageDir/.{1}/(.*)$#;
  }
  close($FL);
  @templates = sort @templates;
  return @templates;
}

sub ListDeletedPages {
  my @list;
  my ($PD) = ($PageDir =~ /^(.*)$/g);
  open my($FILES), "grep -rli '^text: DeletedPage' $PD 2>/dev/null |";
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
  print Form('login','post','',
    $q->div({-class=>'row'},
      $q->div({-class=>'col-md-4'},''),
      $q->div({-class=>'col-md-4'},
	$q->div({-class=>'panel panel-default'},
	  $q->div({-class=>'panel-heading'},
	    $q->h3({-class=>'panel-title'},'Login')
	  ),
	  $q->div({-class=>'panel-body'},
	    $q->div({-class=>'form-group'},
	    $q->label({-for=>'user'}, 'Username:'),
	    $q->textfield(-name=>'user',-value=>$u,-maxlength=>30,
	      -class=>'form-control')
	    ),
	    $q->div({-class=>'form-group'},
	      $q->label({-for=>'pass'}, 'Password:'),
	      $q->password_field(-name=>'pass',-value=>$p,-class=>'form-control'),
	    ),
	    $q->submit(-value=>'Go',-class=>'btn btn-success pull-right')
          ),
	),
      ),
      $q->div({-class=>'col-md-4'},''),
    )
  );
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
    print "<li>".$q->a({-href=>$Url.$pg}, ReplaceUnderscores($pg));
    if($CountPageVisits) {
      print " <small><em>(".Commify(GetPageViewCount($pg))." views)</em></small>";
    }
    print "</li>";
  }
  print "</ol></p>";
}

sub RebuildIndex {
  my @files = ListAllPages(1);
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
    #$_ = m/^([^\\\/]+)$/; $_ = $1;
    ($_) = ($_ =~ /^([a-zA-Z0-9._~#-]*)$/);
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
    #print "<p>Are you sure you want to clear the visitor log? ".
    #  "This cannot be undone.</p>";
    #print $q->p(AdminLink('clearvisits', "YES", 'confirm=yes')."&nbsp;&nbsp;".
    #  $q->a({-href=>"javascript:history.go(-1)"},"NO"));
    Confirm('Are you sure you want to clear the visitor log? This cannot be undone.',
      AdminURL('clearvisits', 'confirm=yes'),
      AdminURL('clearvisits')
    );
  }
}

sub DoAdminListVisitors {
  my $lim;
  # If we're getting 'limit='... (to limit by IP)
  if(GetParam('limit',0)) {
    $lim = GetParam('limit');
  }
    print StartForm('get', 'form-inline').
      $q->hidden(-name=>'do', -value=>'admin', -override=>1),
      $q->hidden(-name=>'page', -value=>'visitors', -override=>1),
      $q->div({-class=>'input-group'},
	$q->textfield(-name=>'limit', -size=>40, -value=>$lim, 
	  -class=>'form-control'),
	$q->span({-class=>'input-group-btn'},
	  '<button type="submit" class="btn btn-default">Search</button>'
	)
      );
      #$q->submit(-class=>'btn btn-default', -value=>'Search');
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
    $pg = ReplaceUnderscores($pg);
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
    my $msg;
    if(-f "$DataDir/lock") {
      $msg = "Are you sure you want to unlock the site?";
    } else {
      $msg = "Are you sure you want to lock the site?";
    }
    Confirm($msg,
      AdminURL('lock', 'confirm=yes'),
      AdminURL('lock')
    );
  }
}

sub DoAdminBlock {
  my $blocked = FileToString($BlockedList);
  my @bl = split(/\n/,$blocked);
  print "<p><strong>".
    Commify(scalar(grep { length($_) and $_ !~ /^#/ } @bl)).
    "</strong> user(s) blocked. Add an IP address, one per line, ".
    "Lines that begin with '#' are considered comments and ignored.</p>";
  print Form('blocklist','post','',
    $q->div({-class=>'form-group'},
      $q->textarea(-name=>'blocklist', -rows=>30, -cols=>100, 
	-default=>$blocked, -class=>'form-control')
    ),
    $q->submit(-class=>'btn btn-success', -value=>'Save')
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
  print Form('bannedcontent', 'post','',
    $q->div({-class=>'form-group'},
      $q->textarea(-name=>'bannedcontent', -rows=>30, -cols=>100,
        -default=>$content, -class=>'form-control')
    ),
    $q->submit(-class=>'btn btn-success', -value=>'Save')
  );
}

sub DoAdminCSS {
  if(GetParam('action') eq "restore") {
    if(GetParam('confirm') eq "yes") {
      unlink "$DataDir/style.css";
      print "<p>Default stylesheet has been restored.</p>";
    } else {
      #print "<p>Are you sure you want to restore the default CSS? This cannot".
	#" be undone.</p>";
      #print $q->p(AdminLink('css','YES','action=restore','confirm=yes').
	#"&nbsp;&nbsp;".$q->a({-href=>'javascript:history.go(-1)'},"NO"));
      Confirm('Are you sure you want to restore the default CSS? This cannot be undone.',
	AdminURL('css','action=restore','confirm=yes'),
	AdminURL('css')
      );
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
    print Form('css','post','',
      $q->div({-class=>'form-group'},
	$q->textarea(-name=>'css', -rows=>30, -cols=>100, 
	  -default=>$content, -class=>'form-control')
      ),
      $q->submit(-class=>'btn btn-success', -value=>'Save')
    );
  }
}

sub DoAdminListFiles {
  print $q->p("Here is a list of pages that contain uploaded files:");
  #print "<ul>";
  print '<div class="list-group">';
  foreach (ListAllFiles()) {
    #print $q->li($q->a({-href=>$Url.$_}, ReplaceUnderscores($_)));
    print $q->a({-href=>$Url.$_, -class=>'list-group-item',
      -title=>$_}, ReplaceUnderscores($_));
  }
  #print "</ul>";
  print '</div>';
}

sub DoAdminListTemplates {
  # Get a list of templates
  print $q->p("Here is a list of pages that are marked as templates:");
  #print "<ul>";
  print '<div class="list-group">';
  foreach (ListAllTemplates()) {
    #print $q->li($q->a({-href=>$Url.$_}, ReplaceUnderscores($_)));
    print $q->a({-href=>$Url.$_, -class=>'list-group-item',
      -title=>$_}, ReplaceUnderscores($_));
  }
  #print "</ul>";
  print '</div>';
}

sub DoAdminRobotsTxt {
  my $content = FileToString("$DataDir/robots.txt");
  print $q->p("For more information about robots.txt, see <a href=\"http://www.robotstxt.org/\">http://www.robotstxt.org/</a>");
  print Form('robotstxt', 'post','',
    $q->div({-class=>'form-group'},
      $q->textarea(-name=>'robotstxt', -rows=>30, -cols=>100, 
	-default=>$content, -class=>'form-control')
    ),
    $q->submit(-class=>'btn btn-success', -value=>'Save')
  );
}

sub DoAdminPlugins {
  # Plugin manager!
  # Do we have an action and plugin?
  my $pi = GetParam('plugin');
  my $act = GetParam('act');
  ($pi) = ($pi =~ /^([a-zA-Z0-9._~#-]*)$/);
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
  #print "<ul>";
  print '<div class="list-group">';
  foreach my $plugin (sort @alist) {
    #print $q->li(AdminLink('plugins',$_,"plugin=$_",'act=disable').
    #  ' - '.$Plugins{$_});
    #print AdminLink('plugins',
    #  '<h4 class="list-group-item-heading">'.$plugin.'</h4>'.
    #  '<p class="list-group-item-text">'.$Plugins{$plugin}.'</p>',
    #  "plugin=$plugin",'act=disable');
    print $q->a({-href=>$Url.'?do=admin;page=plugins;plugin='.$plugin.
      ';act=disable', -class=>'list-group-item', 
      -title=>'Click to disable '.$plugin},
      '<h4 class="list-group-item-heading">'.$plugin.'</h4>'.
      '<p class="list-group-item-text">'.$Plugins{$plugin}.'</p>');
  }
  #print "</ul>";
  print '</div>';
  print $q->h3('Disabled');
  #print "<ul>";
  print '<div class="list-group">';
  foreach my $plugin (sort @dlist) {
    #print $q->li(AdminLink('plugins',$_,"plugin=$_",'act=enable'));
    print $q->a({-href=>$Url.'?do=admin;page=plugins;plugin='.$plugin.
      ';act=enable', -class=>'list-group-item', 
      -title=>'Click to enable '.$plugin},
      '<h4 class="list-group-item-heading">'.$plugin.'</h4>');
  }
  #print "</ul>";
  print '</div>';
}

sub DoAdminDeleted {
  # Force delete?
  if(GetParam('force',0)) {
    my $dp = SanitizeFileName(GetParam('force',''));
    unless(GetParam('confirm','no') eq 'yes') {
      # Ask for confirmation
      #print $q->p("Are you sure you want to delete $dp? ".
	#AdminLink('deleted', 'YES', 'force='.$dp, 'confirm=yes')." ".
	#AdminLink('deleted', 'NO'));
      Confirm("Are you sure you want to delete the page \"$dp\"?",
	AdminURL('deleted', "force=$dp", 'confirm=yes'),
	AdminURL('deleted')
      );
    } else {
      # Delete the page
      DoMaintDeletePages($dp);
      print $q->p('Page deleted. '.AdminLink('deleted', 'Go back'));
    }
    return;
  }
  # Otherwise, list
  my @deleted = ListDeletedPages();
  print $q->p("Here is a list of pages that are pending delete:");
  print "<ul>";
  foreach my $item (@deleted) {
    my %f = GetPage($item);
    print $q->li($q->a({-href=>$Url.$item}, $item).
      " to be deleted after ".
      (FriendlyTime($f{ts} + $PurgeDeletedPage))[$TimeZone].
      " <button type='button' class='btn btn-xs btn-danger' onClick='location.href=\"".
      AdminURL('deleted', 'force='.$item)."\"'>Delete</button>"
    );
  }
  print "</ul>";
}

sub DoAdminSpamLog {
  # Shows the spam log if $SpamLogging is enabled.

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
    ' and '.
    AdminLink('templates',Commify(scalar(ListAllTemplates()))." templates")."."
  );
  print Form('quickedit', 'post', 'form-inline',
    $q->div({-class=>'input-group'},
      #$q->label({-for=>'thepage'},"Quick edit page:"),
      $q->textfield(-name=>'thepage',-size=>'30',-class=>'form-control',
	-placeholder=>'Enter page name'),
      $q->span({-class=>'input-group-btn'},
	'<button type="submit" class="btn btn-primary">Create/Edit</button>'
      )
    ),
    #$q->submit(-value=>'Create/Edit',-class=>'btn btn-default')
  );
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
  print Form('login','post', 'form-inline',
    $q->hidden(-name=>'user', -value=>$u).
    $q->hidden(-name=>'pass', -value=>'').
    $q->submit(-class=>'btn btn-danger', -value=>'Log out')
  );

  # Do dashboard items
  foreach (@DashboardItems) {
    &{$_};
  }
}

sub Confirm {
  my ($question, $yes, $no) = @_;
  print $q->p($question);
  print '<button type="button" class="btn btn-lg btn-success" onClick="'.
    "location.href='$yes'\">YES</button>&nbsp;&nbsp;";
  print '<button type="button" class="btn btn-lg btn-danger" onClick="'.
    "location.href='$no'\">NO</button>";
}

sub DoAdmin {
  # Set default page
  if($Page eq 'admin') {
    $Page = (IsAdmin()) ? 'dashboard' : 'password';
  }

  my $adminlink = "$Url?do=admin;page=";

  if(IsAdmin()) {
  print '<div class="row"><div class="col-sm-3">';
  #print '<div class="list-group">';
  print '<div class="sidebar-nav">';
  print '<div class="navbar navbar-default" role="navigation">';
  print <<EOF;
	<div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".sidebar-navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <span class="visible-xs navbar-brand">Administration menu</span>
        </div>
        <div class="navbar-collapse collapse sidebar-navbar-collapse">
          <ul class="nav navbar-nav">
EOF
  if($Page eq 'password') {
    print $q->li({class=>'active'},AdminLink('password','Authenticate'));
    #print $q->a({-class=>'list-group-item active', -href=>$adminlink.
    #  'password'},"Authenticate");
  } else {
    print $q->li(AdminLink('password','Authenticate')) unless IsAdmin();
    #print $q->a({-class=>'list-group-item', -href=>$adminlink.'password'},
    #  'Authenticate') unless IsAdmin();
  }
  if(IsAdmin()) {
    if($Page eq 'dashboard') {
      print $q->li({class=>'active'},AdminLink('dashboard','Dashboard'));
      #print $q->a({-class=>'list-group-item active', -href=>$adminlink.
	#'dashboard'}, 'Dashboard');
    } else {
      print $q->li(AdminLink('dashboard','Dashboard'));
      #print $q->a({-class=>'list-group-item', -href=>$adminlink.'dashboard'},
	#'Dashboard');
    }
    my %al = reverse %AdminList;
    foreach my $listitem (sort keys %al) {
      next if $listitem eq '';
      if($Page eq $al{$listitem}) {
	print $q->li({class=>'active'},AdminLink($al{$listitem},$listitem));
	#print $q->a({-class=>'list-group-item active', -href=>$adminlink.
	#  $al{$listitem}}, $listitem);
      } else {
	print $q->li(AdminLink($al{$listitem},$listitem));
	#print $q->a({-class=>'list-group-item', -href=>$adminlink.
	#  $al{$listitem}}, $listitem);
      }
    }
  }
  print '</ul>';
  print '</div></div></div></div>';
  #print '</div>'; #End of admin menu, now print page
  #print "</td><td style='padding-left:20px;'>";
  #print '<div style="padding-left:10px;">';
  print '<div class="col-sm-9">';
  } # End of if IsAdmin block for menu

  if($Page and $AdminActions{$Page}) {
    if($Page eq 'password' or IsAdmin()) {
      &{$AdminActions{$Page}};
    }
  }
  #print '</div>';
  #print '<div style="clear:both;"></div>'; #End of admin
  #print '</td></tr></table>';
  if(IsAdmin()) {
  print '</div></div>';
  }
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
  my ($method, $class) = @_;
  $method ||= 'post';
  $class ||= '';
  return $q->start_multipart_form(-method=>$method, -action=>$ScriptName,
    -role=>'form', -class=>$class);
}

sub Form {
  my ($doing, $method, $class, @elements) = @_;
  my $return;
  $return = StartForm($method, $class);
  $return .= $q->hidden(-name=>'doing', -value=>$doing);
  foreach (@elements) {
    $return .= $_ . "\n";
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
    #return $q->hidden(-name=>'session',
    #  -value=>unpack("%32W*", $question) % 65535).$q->br.$q->br.
    #  "$question&nbsp;".$q->textfield(-name=>'answer', -size=>'30').'&nbsp;';
    return $q->div({-class=>'form-group'},
      $q->hidden(-name=>'session', -value=>unpack("%32W*", $question) % 65535),
      $q->label({-for=>'answer'}, $question),
      $q->textfield(-name=>'answer', -size=>30, -class=>'form-control')
    );
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
      return $c;
    }
  }
  return 0;
}

sub WriteSpamLog {
  my ($Event, $Data) = @_;
  # Return if we're not logging spam events
  return unless $SpamLogging;

  # Build log entry
  my $LogEntry = "$UserIP\t$TimeStamp\t$Page\t".GetParam('do','').
    "\t$PageRevision\t$HTTPStatus\t$UserName\t$Event\t$Data";

  # Now save it to the log
  AppendStringToFile($LogEntry, "$DataDir/spam.log");
}

sub PassesSpamCheck {
  # Checks to see if the form submitted passes all spam checks. Returns 1 if
  #  passed, 0 otherwise.
  my $session = GetParam('session');
  my $answer = GetParam('answer');

  if(IsAdmin()) { return 1; }	# If admin, assume passed.
  # Check BannedContent
  my $bc = IsBannedContent();
  if($bc) { WriteSpamLog('BannedContent', $bc); return 0; }
  # If there are no questions, assume passed
  if(!%QuestionAnswer) { return 1; }
  # If the form was sumbitted without "question" or if it wasn't defined, fail
  if(!$session) { WriteSpamLog('Session','Undefined'); return 0; }
  # If the form was submitted without the answer or it wasn't defined, fail
  if(!$answer or Trim($answer) eq '') {
    WriteSpamLog('Answer','Missing/undefined');
    return 0;
  }
  # Check the answer against the question asked
  my %AnswerQuestions = reverse %QuestionAnswer;
  $answer = lc($answer);
  if((!exists $AnswerQuestions{$answer}) or (!defined $AnswerQuestions{$answer})) {
    WriteSpamLog('QuestionAnswer','Missing/undefined/incorrect');
    return 0;
  }
  my $question = $AnswerQuestions{$answer};
  # "Checksum" of the question
  my $qcs = unpack("%32W*",$question) % 65535;
  # If checksum doesn't match, don't pass
  if($qcs != $session) { WriteSpamLog('Checksum','Mismatch'); return 0; }
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
    ($Page) = ($Page =~ /^([a-zA-Z0-9._~#-]*)$/);
    # If the preview is older than 10 seconds, remove it and don't display it
    if((stat("$TempDir/$Page.$UserIP"))[9] < ($TimeStamp - 10)) {
      unlink "$TempDir/$Page.$UserIP";
    } else {
      $newtext = UnquoteHTML(FileToString("$TempDir/$Page.$UserIP"));
      #print "<div class=\"preview\">".Markup($newtext)."</div>";
      print $q->div({-class=>'alert alert-warning'},Markup($newtext));
      my @ta = split(/\n\n/,$newtext); pop @ta;
      $newtext = join("\n\n", @ta);
    }
  }
  print RedHerringForm();
  #print "<p id=\"discuss-form\"></p><form action='$ScriptName' method='post'>
  #  <input type='hidden' name='doing' value='discuss' />
  #  <input type='hidden' name='file' value='$Page' />
  #  <textarea name='text' style='width:100%;' placeholder='$NewComment'"; 
  #  print" cols='80' rows='10'>$newtext</textarea><br/><br/>
  #  Name: <input type='text' name='uname' size='30' value='$UserName' /> 
  #  URL (optional): <input type='text' name='url' size='50' />";
  #print AntiSpam();
  #print " <input type='submit' name='whattodo' value='Save' />
  #  <input type='submit' name='whattodo' value='Preview' /></form>";

  print Form('discuss', 'post', '',
    $q->div({-class=>'form-group'},
      $q->hidden(-name=>'file', -value=>$Page),
      $q->textarea(-name=>'text', -placeholder=>$NewComment, -cols=>80, 
	-rows=>10, -default=>$newtext, -class=>'form-control') 
    ),
    $q->div({-class=>'form-group'},
      $q->label({-for=>'uname'},'Name: '),
      $q->textfield(-name=>'uname', -size=>30, -value=>$UserName, 
	-class=>'form-control')
    ),
    $q->div({-class=>'form-group'},
      $q->label({-for=>'url'},'URL (optional): '),
      $q->textfield(-name=>'url', -size=>50, -class=>'form-control')
    ),
    AntiSpam(),
    $q->submit(-name=>'whattodo', -value=>'Save', -class=>'btn btn-success'),
    $q->submit(-name=>'whattodo', -value=>'Preview', -class=>'btn btn-primary')
  );

  #print '<script language="javascript" type="text/javascript">'.
  #  "function ShowHide() {
	#document.getElementById('discuss-help').style.display = (document.getElementById('discuss-help').style.display == 'none') ? 'block' : 'none';
	#document.getElementById('showhidehelp').innerHTML = (document.getElementById('showhidehelp').innerHTML == 'Show markup help') ? 'Hide markup help' : 'Show markup help';
	#return true; }".
  #  '</script>';
  #print "<br/><a title=\"Markup help\" id=\"showhidehelp\"".
  #  "href=\"#discuss-form\" onclick=\"ShowHide();\">".
  #  "Show markup help</a>";
  #print "<br/><div id=\"discuss-help\" style=\"display:none;\">";
  #print $q->button({-data-toggle=>'collapse', -data-target=>'#discuss-help',
  #  -class=>'btn btn-info'}, 'Show markup help');
  #print '<br/><button type="button" class="btn btn-xs btn-info" data-toggle="collapse" '.
  #  'data-target="#discuss-help">Show markup help</button>';
  #print $q->div({-class=>'collapse', -id=>'discuss-help'}, MarkupHelp());
  #print '<div id="discuss-help" class="collapse">';
  MarkupHelp();
  #print "</div>";
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
    print "<a href='$Url$ent[1]'>".ReplaceUnderscores($ent[1])."</a> . . . . ";
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
  # Untaint $Param{'search'} and $PageDir. $PageDir should not be able to be
  #  modified by an end-user, however $Param{'search'} might be tainted.
  my ($PD) = ($PageDir =~ /^(.*)$/g);
  my ($PS) = ($Param{'search'} =~ /^(.*)$/g);
  chomp(my @files = `grep -Prl '$PS' $PD`);
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
    my $filename = (($F{filename}) ? $F{filename} : GetParam('page'));
    #my %headers = ( -type=>'application/x-download;name='.$filename,
    #  #-attachment=>$filename);
    #  -Disposition=>'attachment;filename='.$filename );
    my %headers = ( -type=>'application/octet-stream;name='.$filename,
      -attachment=>$filename,
      -disposition=>'attachment;filename='.$filename );
    $headers{-Content_Encoding} = $2 if $2;
    print $q->header(%headers);
    require MIME::Base64;
    print MIME::Base64::decode($F{text});
  } else {
    ErrorPage(400, "Something terribly wrong has happend, and I'll be honest,".
      " I've got nothing...");
  }
}

sub DoView {
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

sub DoRemoveRevision {
  my $revision = GetParam('revision',0);
  if(!$revision) {
    print $q->p('No revision passed');
    return;
  }
  my $archive = substr($Page,0,1); $archive =~ tr/[a-z]/[A-Z]/;
  if(!CanEdit()) {
    print $q->p("You can't edit this item.");
    return;
  }

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
  # Untaint the variables
  my ($S) = ($search =~ /^(.*)$/g);
  my ($AS) = ($altsearch =~ /^(.*)$/g);
  my ($PD) = ($PageDir =~ /^(.*)$/g);
  # Search the innards of the files
  #open my($FILES), "grep -Erli '($search|$altsearch)' $PageDir 2>/dev/null |";
  open my($FILES), "grep -Erli '($S|$AS)' $PD 2>/dev/null |";
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
      $res =~ s#(.*?)($search|$altsearch)(.*?)#$1<strong><mark>$2</mark></strong>$3#gsi;
      $result{$fn} .= "$res . . . ";
      $matchcount++;
    }
  }
  # Now sort them by value...
  my @keys = sort {length $result{$b} <=> length $result{$a}} keys %result;
  foreach my $key (@keys) {
    my $restitle = ReplaceUnderscores($key);
    $restitle =~ s#(.*?)($search|$altsearch)(.*?)#$1<strong><mark>$2</mark></strong>$3#gsi;
    print "<big><a href='$Url$key'>$restitle</a></big><br/>";
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
      CommandLink('edit',SanitizeFileName($search),
	"create a page called ".SanitizeFileName($search),
	"Create page ".SanitizeFileName($search))."?");
  }
}

sub SearchForm {
  my $ret;
  my $search = UnquoteHTML(GetParam('search',''));
  #$ret = StartForm('get', 'form-inline').
  #  $q->hidden(-name=>'do', -value=>'search', -override=>1).
  #  $q->textfield(-name=>'search', -size=>'40', -placeholder=>'Search',
  #    -value=>$search).
  #  $q->submit(-value=>'Search').'</form>';

  $ret = '<form action="'.$Url.'" method="get" class="navbar-form navbar-right">'.
    '<input type="hidden" name="do" value="search">'.
    '<div class="input-group">'.
    '<input type="text" placeholder="Search" name="search" value="'.$search.'" class="form-control">'.
    '<span class="input-group-btn">'.
    '<button type="submit" class="btn btn-success">Search</button>'.
    '</span></div></form>';

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

sub HumanReadableSize {
  my $bytes = shift;
  my $count = 0;
  my @un = qw(B KB MB GB TB);

  while ($bytes > 1024) {
    $bytes = $bytes / 1024;
    $count++;
  }
  $bytes = sprintf "%.2f", $bytes;
  return $bytes .' '. $un[$count];
}

sub DoHistory {
  my $author; my $summary; my %f;
  my $topone = " checked";
  if(PageExists($Page)) {
    %f = GetPage($Page);
    my $isupload = 0;
    if($f{text} =~ m/#FILE /) { $isupload = 1; }
    my $currentday = YMD($f{ts});
    my ($linecount, $wordcount, $scharcount, $charcount);
    unless($isupload) {
      $linecount = (split(/\n/,$f{text}));
      $wordcount = @{[ $f{text} =~ /\S+/g ]};
      $scharcount = length($f{text}) - (split(/\n/,$f{text}));
      $charcount = $scharcount - ($f{text} =~ tr/ / /);
    }
    print "<p><strong>History of ".
      $q->a({-href=>$Url.$Page}, $Page)."</strong><br/>".
      "The most recent revision number of this page is $f{'revision'}. ";
    if($CountPageVisits) {
      print "It has been viewed ".Commify(GetPageViewCount($Page))." time(s). ";
    }
    print "It was last modified ".(FriendlyTime($f{'ts'}))[$TimeZone].
      " by ".QuoteHTML($f{author}).". ";
    unless($isupload) {
      print "There are ".Commify($linecount)." lines of text, ".Commify($wordcount).
        " words, ".Commify($scharcount)." characters with spaces and ".
        Commify($charcount)." without. ";
    }
    print "The total page size (including metadata) is ".
      Commify((stat("$PageDir/$ShortDir/$Page"))[7])." bytes (";
    # Show human readable format
    print HumanReadableSize((stat("$PageDir/$ShortDir/$Page"))[7]);
    print ")</p>";
    # If the page is set for deletion, let them know
    if($f{text} =~ m/^DeletedPage\n/) {
      print $q->p($q->em("This page is scheduled to be deleted after ".
	$q->strong((FriendlyTime($f{ts} + $PurgeDeletedPage))[$TimeZone])));
    }
    print $q->p(CommandLink('links',$Page,"See all pages that link to $Page"));
    print "<form action='$Url' method='get'>";
    print "<input type='hidden' name='do' value='diff' />";
    print "<input type='hidden' name='page' value='$Page' />";
    print "<input type='submit' value='Compare' class='btn btn-info' />";
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
	print "<td>".HM($f{ts})." ";
	if(CanEdit()) {
	  print "<input type=\"button\" onClick=\"location.href='$Url?do=".
	  "edit;page=$Page;revision=$f{revision};summary=".
	  "Revert to Revision ".$f{revision}." (".
	  (FriendlyTime($f{ts}))[$TimeZone].")'\" ".
	  "value=\"Revert\" class=\"btn btn-xs btn-warning\"> ".
	  "<input type=\"button\" onClick=\"location.href='$Url?do=".
	  "rmrev;page=$Page;revision=$f{revision}'\" value=\"Delete\" ".
	  'class="btn btn-xs btn-danger"> '.
	  CommandLink('',$Page,"Revision $f{revision}",
	    "View revision $f{revision}","revision=$f{revision}");
	}
	if(PageExists(QuoteHTML($f{author}))) {
	  print " . . . . <a href=\"$Url" . QuoteHTML($f{author}) . "\">".
	    QuoteHTML($f{author}) . "</a>";
	} else {
	  print " . . . . ".QuoteHTML($f{author});
	}
        print " ($f{ip}) &ndash; " . QuoteHTML($f{summary}) . "</td></tr>";
      }
    }
    print "</table><input type='submit' value='Compare' class='btn btn-info'/></form>";
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
  # UnquoteHTML() needs to be called for password, otherwise special
  #  characters will cause problems.
  SetCookie(GetParam('user'), UnquoteHTML(GetParam('pass')));
  ReDirect($Url."?do=admin");
}

sub DoPostingEditing {
  my $redir;
  my @redirparams;
  if(CanEdit()) {
    # Set user name if not already done
    my ($u, $p) = ReadCookie();
    if($u ne GetParam('uname') or !$u) {
      SetCookie(GetParam('uname'), $p);
    }
    if(GetParam('whattodo') eq "Cancel") {
      UnLock(GetParam('file'));
      my @tfiles = (glob("$TempDir/".GetParam('file').".*"));
      foreach my $file (@tfiles) { 
	($file) = ($file =~ /^([-\/\w.]+)$/);
	unlink $file;
      }
    } elsif(GetParam('whattodo') eq "Preview") {
      Preview(GetParam('file'));
      $redir = 1;
    } elsif(GetParam('whattodo') eq "Delete") {
      push @redirparams, "text=DeletedPage";
      push @redirparams, "summary=Marking page for deletion";
      push @redirparams, "clear=1";
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
    ReDirect($Url."?do=edit;page=".GetParam('file').';'.join(';',@redirparams));
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
    StringToFile(UnquoteHTML(GetParam('bannedcontent')), $BannedContent);
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
  if(GetParam('whattodo') eq "Delete") {
    ReDirect($Url.GetParam('file').'?do=edit;'.
      'text=DeletedPage;summary=Marking page for deletion;clear=1');
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

sub DoPostingQuickedit {
  my $page = SanitizeFileName(GetParam('thepage'));
  ReDirect($Url.$page."?do=edit");
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
    open my($VISITFILE), '>', $PageVisitFile or return; # Return if can't open
    flock($VISITFILE, LOCK_EX) or return; # Exclusive lock or return
    seek($VISITFILE, 0, SEEK_SET); # Beginning
    if(defined $f{$Page}) {
      $f{$Page}++;
    } else {
      $f{$Page} = 1;
    }
    #WriteDB($PageVisitFile, \%f);
    foreach my $key (sort keys %f) {
      #$f{$key} =~ s/\n/\n\t/g;
      #$f{$key} =~ s/\r//g;
      print $VISITFILE "$key: ".$f{$key}."\n";
    }
    close($VISITFILE);
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
      ($file) = ($file =~ /^([-\/\w.]+)$/);
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
    if((stat("$f"))[9] <= $RemoveTime) { 
      ($f) = ($f =~ /^([-\/\w.]+)$/);
      unlink $f;
    }
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
    #my @new = @lf[0 .. ($MaxVisitorLog - 1)];
    $#lf = $MaxVisitorLog - 1;
    #@lf = reverse(@new);
    @lf = reverse(@lf);
    seek($LOGFILE, 0, SEEK_SET);	# Return to the beginning
    print $LOGFILE "" . join("\n", @lf) . "\n";
    close($LOGFILE);
  }
}

sub DoMaintDeletePages {
  # Delete pages that are marked "DeletedPage" and older than $PurgeDeletedPage
  my $param = shift;
  my @list;
  my @files;
  my @archives;
  my $RemoveTime = ($param) ? $TimeStamp : $TimeStamp - $PurgeDeletedPage;
  unless($param) {
    @list = ListDeletedPages();
    # Go through @list, see what is over $PurgeDeletedPage
    foreach my $listitem (@list) {
      my %f = GetPage($listitem);
      if($f{ts} < $RemoveTime) { push @files, $listitem; }
    }
  } else {
    if(PageExists($param)) { push @files, $param; }
  }
  if(@files) {
    foreach my $file (@files) {
      ($file) = ($file =~ /([a-zA-Z0-9._~#-]*)$/);
      my $archive = substr($file,0,1); $archive =~ tr/[a-z]/[A-Z]/;
      ($archive) = ($archive =~ /^([A-Z0-9]{1})$/);
      unlink "$PageDir/$archive/$file";
      @archives = grep { /^$ArchiveDir\/$archive\/$file.\d+/ } 
	glob("$ArchiveDir/$archive/$file.*");
      foreach (@archives) {
	$_ =~ /^([-\/\w.]+)$/;
	unlink $1;
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
  # Untaint $TempDir. This is a little bit of a flub though, because
  #  there shouldn't be any way an end-user can modify $TempDir, so we're
  #  assuming that $TempDir is absolutely fine.
  my ($TD) = ($TempDir =~ /^(.*)$/g);
  my $diff = `diff $TD/old $TD/new`;
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
    s#^&[lg]t; ##gm for ($o,$n);
    if($o and $n) {
      $return .= "<div class='alert alert-danger'>$o</div><p><strong>to</strong></p>\n".
	"<div class='alert alert-success'>$n</div><hr/>";
    } else {
      if($h =~ m/Added:/) {
	$return .= "<div class='alert alert-success'>";
      } else {
	$return .= "<div class='alert alert-danger'>";
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
      "<a href=\"$Url$Page\">$Page</a> ";
      print '('.(defined $rv{v2} ? 'revision '.$rv{v2} :
	'the current revision').' is displayed below)</p>';
    if(($newrev =~ m/\.\d+$/) and (-f "$ArchiveDir/$ShortDir/$newrev")) {
      %F = ReadDB("$ArchiveDir/$ShortDir/$newrev");
    } else {
      %F = ReadDB("$PageDir/$ShortDir/$newrev");
    }
    if($F{text} !~ m/^#FILE /) {
      print HTMLDiff(GetDiff($oldrev, $newrev));
      print "<hr/>";
      if(defined &Markup) {
	print Markup($F{text});
      } else {
	print $F{text};
      }
    } else {
      print "<p>You are comparing uploaded files, this functionality is not supported.</p>";
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
  $pagename = SanitizeFileName(ReplaceSpaces($pagename));
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
  #print "It appears that you are attempting to spam $Page. ".
  #  "Please don't do that.";
  ErrorPage(403, "It appears that you are attempting to spam $Page. ".
    "Please don't do that.");
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

sub ReplaceUnderscores {
  my $replacetext = shift;
  $replacetext =~ s/_/ /g;
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
    401 => '401 Unauthorized',
    403 => '403 Forbidden',
    404 => '404 Not Found',
    409 => '409 Conflict',
    415 => '415 Unsupported Media Type',
    429 => '429 Too Many Requests',
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
  # Untaint $UserIP, $VisitorLog and $spts.
  my ($UIP) = ($UserIP =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/g);	# nnn.nnn.nnn.nnn
  my ($VL) = ($VisitorLog =~ /^(.*)$/g);		# Safe
  ($spts) = ($spts =~ /^(\d*)$/g);			# numeric
  # Now, count the elements that match
  chomp(my @counts = split(/\n/,`grep ^$UIP $VL | awk '\$2>$spts'`));
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
  if($do ne '' and scalar(@extras) > 0) { $ret .= ";"; }
  $ret .= join(';',@extras) if @extras;
  return $q->a({-href=>$ret, -title=>$title, -rel=>'nofollow'}, $text);
}

sub AdminURL {
  my ($pg, @extras) = @_;
  my $ret;
  $ret = $Url . "?do=admin";
  $ret .= ";page=$pg" if $pg;
  $ret .= ";".join(';',@extras) if @extras;
  print STDERR "$ret\n";
  return $ret;
}

sub AdminLink {
  my ($pg, $text, @extras) = @_;
  return $q->a({-href=>AdminURL($pg, @extras), -rel=>'nofollow'},
    $text);
}

sub DoRequest {
  # Blocked?
  if(IsBlocked()) {
    ErrorPage(403, "You've been banned. Please don't come back.");
    return;
  }

  # Surge protection
  if(DoSurgeProtection()) {
    ErrorPage(429, "You've attempted to fetch more than $SurgeProtectionCount pages in $SurgeProtectionTime seconds.");
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
    my $content;
    if(!PageExists($Page)) {
      $content = $NewPage;
    } else {
      %Filec = GetPage($Page, $rev);
      if($rev and !PageExists($Page, $rev)) {
	print $q->div({-class=>'alert alert-danger'},
	  $q->p("That revision of ".$q->a({-href=>"$Url$Page"}, $Page).
	    " does not exist!"));
      }
      if($Filec{template} == 1) {
	print $q->div({-class=>'alert alert-info'},
	  $q->p("This page is a template, and likely doesn't contain any useful ".
	    "information."));
      }
      if($Filec{text} =~ m/^DeletedPage\n/) {
	print $q->div({-class=>'alert alert-danger'},
	  $q->p($q->em("This page is scheduled to be deleted after ".
	    $q->strong((FriendlyTime($Filec{ts} + $PurgeDeletedPage))[$TimeZone]))));
      }
      if($rev and PageExists($Page, $rev)) {
	print $q->div({-class=>'alert alert-warning'}, $q->p({-style=>"font-weight: bold;"}, 
	  "You are viewing Revision $Filec{revision} of ".
	  $q->a({-href=>"$Url$Page", -title=>'View the newest version'}, $Page)));
	if(IsSpecialPage()) {
	  print $q->div({-class=>'alert alert-danger'},
	    "This page is registered as a special page, however you are ".
	    "viewing a previous revision of the page. As such, the ".
	    "special page function will not be triggered.");
	}
      }
      if($Filec{text} =~ m/^#FILE /) {
	print $q->p("This page contains a file:");
	#print $q->pre(CommandLink('download',$Page,
        #  ($Filec{filename}) ? $Filec{filename} : $Page, 'View file',
        #  (GetParam('revision')) ? 'revision='.GetParam('revision') : ''));
	print $q->pre((($Filec{filename}) ? $Filec{filename} : $Page).' ('.
	  CommandLink('view',$Page,
	    'View', 'View the file',
	    (GetParam('revision')) ? 'revision='.GetParam('revision') : '').
	  ', '.
	  CommandLink('download',$Page,
            'Download', 'Download the file',
            (GetParam('revision')) ? 'revision='.GetParam('revision') : '').
	  ')');
      } elsif(exists &Markup) {	# If there's markup defined, do markup
	$content = Markup($Filec{text});
	#print Markup($Filec{text});
      } else {
	$content = join("\n", $Filec{text});
	#print join("\n", $Filec{text});
      }
      #if(GetParam('search',0)) {
	#my $search = GetParam('search');
	#my $altsearch = ReplaceSpaces($search);
	#$content =~ s!($search|$altsearch)!<span style="background: yellow;">$1</span>!gsi;
      #}
      #print $q->div({-class=>'markup-content'},$content);
    }
    print '<div class="markup-content">'."\n";
    print $content;
    DoSpecialPage();
    print '</div>';
    if($Filec{ts}) {
      $MTime = "Last modified: ".(FriendlyTime($Filec{ts}))[$TimeZone]." by ".
	$Filec{author} . "<br/>";
    }
    #DoSpecialPage();
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
body {
  /* padding-top: 50px;
  margin-bottom: 60px; */
}

.container {
  margin-left: 15px;
  margin-right: 15px;
  width: 97%;
}

.markup-content {
  /*text-align: justify;*/
}

.aneuch-content {
  padding: 40px 15px;
  /*text-align: center;*/
  /*text-align: justify;*/
  font-size: 1.1em;
}

.aneuch-content blockquote {
  font-size: 1em !important;
}

/*.aneuch-content textarea {
  padding: 3px;
  width: 100%;
}*/

/*.aneuch-content a
{
  color:rgb(68, 119, 255);
  text-decoration: none;
}*/

.markup-content a:hover
{
  text-decoration: underline;
  color:green;
}

.markup-content a.external:hover
{
  text-decoration: underline;
  color:red;
}

.footer {
  /*position: absolute;
  bottom: 0;*/
  width: 100%;
  /* Set the fixed height of the footer here */
  /* height: 60px; */
  background-color: #f5f5f5;
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

#markup-help
{
  /*border: 1px solid #8CACBB;
  background: #EEEEFF;
  padding: 10px;
  margin-top: 20px;*/
  font-size: 0.9em;
  font-family: "Courier New", Courier, monospace;
}

#markup-help dt
{
  font-weight: bold;
}

#markup-help dd
{
  margin-left: 20px;
}

img {
  padding: 10px;
}

@media print {
  .page-header a:link:after, .page-header a:visited:after {
    content: "";
  }
  .footer {
    display: none !important;
  }
}

.page-header h1 {
  font-size: 24px;
}

/* make sidebar nav vertical */ 
@media (min-width: 768px) {
  .sidebar-nav .navbar .navbar-collapse {
    padding: 0;
    max-height: none;
  }
  .sidebar-nav .navbar ul {
    float: none;
  }
  .sidebar-nav .navbar ul:not {
    display: block;
  }
  .sidebar-nav .navbar li {
    float: none;
    display: block;
  }
  .sidebar-nav .navbar li a {
    padding-top: 12px;
    padding-bottom: 12px;
  }
}
