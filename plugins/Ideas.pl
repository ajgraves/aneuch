#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0060';     # Require 0.40 or higher.
RegPlugin('Ideas.pl', 'Idea tracker for Aneuch');
my $IdeasPrefix = 'Ideas_';
my $IdeasPage = 'Ideas';
my $IdeaSummaryLength = 2000;
my $DefaultRecent = 1;

sub DoPostingIdeas {
  # Can't edit? Error 403
  unless(CanEdit()) {
    ErrorPage(403,"You can't post notes. Sorry.");
    return;
  }
  #my $pn = $NotesPrefix.$TimeStamp;
  # NOTE: This needs to be fixed, as it will overwrite a page with the same name
  #my $pn = SanitizeFileName(GetParam('title', ''));
  #if($pn eq '') { $pn = $TimeStamp; }
  #if(PageExists($NotesPrefix.$pn)) {
  #  $pn .= '_'.$TimeStamp;
  #}
  my $pn = $NotesPrefix.$TimeStamp; #.$pn;
  # Page already exists? Error 409
  if(PageExists($pn)) {
    ErrorPage(409,"Something happened and I tried to save a page that ".
      "already exists. Please go back and try again.");
    return;
  }
  my $pagetext = UnquoteHTML(GetParam('note',''));
  if(GetParam('title')) {
    $pagetext = "=".UnquoteHTML(GetParam('title',''))."\n".$pagetext;
  }
  SetParam('summary', "$UserName created a quick note.");
  #WritePage($pn, UnquoteHTML(GetParam('note','')), $UserName);
  WritePage($pn, $pagetext, $UserName);
  ReDirect($Url.$pn);
}

sub DoIdeaEntryForm {
  print Form('idea','post','',
    $q->div({-class=>'form-group'},
      $q->textfield(-name=>'title',-placeholder=>'Title (optional)', 
	-class=>'form-control')
    ),
    $q->div({-class=>'form-group'},
      $q->textarea(-name=>'note', -rows=>20, -cols=>100, -placeholder=>'Note',
	-class=>'form-control')
    ),
    $q->submit(-class=>'btn btn-default', -value=>'Note it!').
      " ".CommandLink('listnotes',$Page,'List all saved notes')
  );
}

sub IdeasShowRecentLink {
  my $recent = shift;
  if($recent) {
    #print $q->p(CommandLink('listnotes', $NotesPage, 'Show oldest first', 'Sort by date ascending', 'recent=0'));
    print CommandLink('listnotes', $NotesPage, 'Show oldest first', 'Sort by date ascending', 'recent=0');
  } else {
    #print $q->p(CommandLink('listnotes', $NotesPage, 'Show newest first', 'Sort by date descending', 'recent=1'));
    print CommandLink('listnotes', $NotesPage, 'Show newest first', 'Sort by date descending', 'recent=1');
  }
}

sub IdeasShowCreateLink {
  print $q->a({-href=>$Url.$NotesPage}, "Create a new note");
}

sub IdeasHeader {
  my $recent = shift;
  my @notes = IdeasList();
  print '<p>';
  IdeasShowCreateLink();
  print ' | ';
  IdeasShowRecentLink($recent);
  print ' | Showing '.scalar(@notes).(scalar(@notes) eq 1 ? " note" : " notes");
  print '</p>';  
}

sub DoCommandListNotes {
  my @notes = IdeasList();
  my $recent = GetParam('recent',$DefaultRecent);
  IdeasHeader($recent);
  print "<br/>";
  if($recent) { @notes = reverse @notes; }
  foreach(@notes) {
    my $fn = $_;
    my %F = GetPage($fn);
    print "<big><a href='${Url}${fn}'>".ReplaceUnderscores($fn).
      "</a></big><br/>";
    print "<small>Last modified ".
      (FriendlyTime($F{ts}))[$TimeZone]."</small><br/>";
    if(length($F{text}) > $NoteSummaryLength) {
      print QuoteHTML(substr($F{text},0,$NoteSummaryLength))." . . .";
    } else {
      print QuoteHTML($F{text});
    }
    print "<br/><br/>";
  }
  IdeasHeader($recent);
}

sub IdeasList {
  return grep(/^$IdeasPrefix.*/,ListAllPages());
}

sub DashboardIdeas {
  print $q->h3('Ideas');
  my @notes = IdeasList();
  print $q->p("There ".(scalar(@notes) eq 1 ? "is " : "are ").
    AdminLink('listideas',Commify(scalar(@notes)).
      (scalar(@notes) eq 1 ? "idea" : "ideas")).
    " saved.");
}

sub DoIdeaPageLink {
  #print $q->a({-href=>$Url.$NotesPage}, "&larr; Go back to $NotesPage");
  print '<p>';
  print "<br/>".CommandLink('listideas',$NotesPage,"&larr; Go back to the ideas list").' | '.
    $q->a({-href=>$Url.$IdeasPage}, "Create a new note").' | ';
  my @notes = IdeasList();
  my $index = 0;
  ++$index until $notes[$index] eq $Page or $index > $#notes;
  if($index > 0) {
    print $q->a({-href=>$Url.$notes[0]},'&laquo; Oldest idea').' | ';
    print $q->a({-href=>$Url.$notes[$index - 1]},'&lsaquo; Previous idea');
  }
  if($index > 0 and $index < $#notes) { print ' | '; }
  if($index < $#notes) {
    print $q->a({-href=>$Url.$notes[$index + 1]},'Next idea &rsaquo;').' | ';
    print $q->a({-href=>$Url.$notes[$#notes]},'Newest idea &raquo;');
  }
  print '</p>';
}

RegSpecialPage($IdeasPage, \&DoIdeaEntryForm);
RegSpecialPage("^$IdeasPrefix.*", \&DoIdeaPageLink);
RegPostAction('idea', \&DoPostingIdeas);
RegCommand('listideas', \&DoCommandListIdeas, 'was viewing all saved <strong>ideas</strong>');
RegAdminPage('listideas', 'Show ideas', \&DoCommandListIdeas);
RegDashboardItem(\&DashboardIdeas);
