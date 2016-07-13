#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0050';     # Require 0.50 or higher.
RegPlugin('BookNotes.pl', 'Book notes plugin for Aneuch');

sub DoPostingBookNotes {
  # Can't edit? Error 403
  unless(CanEdit()) {
    ErrorPage(403,"You can't post notes. Sorry.");
    return;
  }
  my $pn = SanitizeFileName(UnquoteHTML(GetParam('file')));
  SetParam('summary', "$UserName added notes about the book.");
  my %F = GetPage($pn);
  chomp(my @text = split(/%booknote%/,$F{text}));
  $text[0] .= "\n".GetParam('note')."\n\n";
  my $newtext = join("%booknote%",@text);
  WritePage($pn, $newtext, $UserName);
  ReDirect($Url.$pn);
}

sub DoSCBookNote {
  return unless(CanEdit());
  return Form('booknote','post',
  $q->hidden(-name=>'file', -value=>$Page),
  "Enter new notes below:<br/>",
  $q->textarea(-name=>'note', -rows=>10, -cols=>100),
  "<br/>".$q->submit('Note it!'));
}

RegPostAction('booknote', \&DoPostingBookNotes);
RegShortCode('booknote', \&DoSCBookNote);