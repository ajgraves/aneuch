#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0050';     # Require 0.40 or higher.
RegPlugin('Notes.pl', 'Quick notes for Aneuch');
my $NotesPrefix = 'QuickNote_';
my $NotesPage = 'QuickNotes';
my $NoteSummaryLength = 2000;
my $DefaultRecent = 1;

sub DoPostingNotes {
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

sub DoNoteEntryForm {
  print Form('note','post','',
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

sub NotesShowRecentLink {
  my $recent = shift;
  if($recent) {
    #print $q->p(CommandLink('listnotes', $NotesPage, 'Show oldest first', 'Sort by date ascending', 'recent=0'));
    print CommandLink('listnotes', $NotesPage, 'Show oldest first', 'Sort by date ascending', 'recent=0');
  } else {
    #print $q->p(CommandLink('listnotes', $NotesPage, 'Show newest first', 'Sort by date descending', 'recent=1'));
    print CommandLink('listnotes', $NotesPage, 'Show newest first', 'Sort by date descending', 'recent=1');
  }
}

sub NotesShowCreateLink {
  print $q->a({-href=>$Url.$NotesPage}, "Create a new note");
}

sub NotesHeader {
  my $recent = shift;
  my @notes = NotesList();
  print '<p>';
  NotesShowCreateLink();
  print ' | ';
  NotesShowRecentLink($recent);
  print ' | Showing '.scalar(@notes).(scalar(@notes) eq 1 ? " note" : " notes");
  print '</p>';  
}

sub DoCommandListNotes {
  my @notes = NotesList();
  my $recent = GetParam('recent',$DefaultRecent);
  NotesHeader($recent);
  print "<br/>";
  if($recent) { @notes = reverse @notes; }
  foreach(@notes) {
    my $fn = $_;
    my %F = GetPage($fn);
    print "<big><a href='${Url}${fn}'>$fn</a></big><br/>";
    print "<small>Last modified ".
      (FriendlyTime($F{ts}))[$TimeZone]."</small><br/>";
    if(length($F{text}) > $NoteSummaryLength) {
      print QuoteHTML(substr($F{text},0,$NoteSummaryLength))." . . .";
    } else {
      print QuoteHTML($F{text});
    }
    print "<br/><br/>";
  }
  NotesHeader($recent);
}

sub NotesList {
  return grep(/^$NotesPrefix.*/,ListAllPages());
}

sub DashboardNotes {
  print $q->h3('Quick Notes');
  my @notes = NotesList();
  print $q->p("There ".(scalar(@notes) eq 1 ? "is " : "are ").
    AdminLink('listnotes',Commify(scalar(@notes))." quick ".
      (scalar(@notes) eq 1 ? "note" : "notes")).
    " saved.");
}

sub DoNotePageLink {
  #print $q->a({-href=>$Url.$NotesPage}, "&larr; Go back to $NotesPage");
  print '<p>';
  print "<br/>".CommandLink('listnotes',$NotesPage,"&larr; Go back to the notes list").' | '.
    $q->a({-href=>$Url.$NotesPage}, "Create a new note").' | ';
  my @notes = NotesList();
  my $index = 0;
  ++$index until $notes[$index] eq $Page or $index > $#notes;
  if($index > 0) {
    print $q->a({-href=>$Url.$notes[0]},'&laquo; Oldest note').' | ';
    print $q->a({-href=>$Url.$notes[$index - 1]},'&lsaquo; Previous note');
  }
  if($index > 0 and $index < $#notes) { print ' | '; }
  if($index < $#notes) {
    print $q->a({-href=>$Url.$notes[$index + 1]},'Next note &rsaquo;').' | ';
    print $q->a({-href=>$Url.$notes[$#notes]},'Newest note &raquo;');
  }
  print '</p>';
}

RegSpecialPage($NotesPage, \&DoNoteEntryForm);
RegSpecialPage("^$NotesPrefix.*", \&DoNotePageLink);
RegPostAction('note', \&DoPostingNotes);
RegCommand('listnotes', \&DoCommandListNotes, 'was viewing all saved <strong>quick notes</strong>');
RegAdminPage('listnotes', 'Show notes', \&DoCommandListNotes);
RegDashboardItem(\&DashboardNotes);
