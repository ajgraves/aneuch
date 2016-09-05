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
  if(Trim(GetParam('note')) eq '') {
    ReDirect($Url.SanitizeFileName(UnquoteHTML(GetParam('file',$DefaultPage))));
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
  return $q->div({-class=>'panel panel-primary'},
    $q->div({-class=>'panel-heading'},
      $q->h3({-class=>'panel-title'},'Enter new notes')
    ),
    $q->div({-class=>'panel-body'},
      Form('booknote','post','',
	$q->div({-class=>'form-group'},
	  $q->hidden(-name=>'file', -value=>$Page),
	  $q->textarea(-name=>'note', -rows=>10, -cols=>100, 
	    -class=>'form-control')
        ),
	$q->submit(-class=>'btn btn-default', -value=>'Note it!')
      )
    )
  );
}

RegPostAction('booknote', \&DoPostingBookNotes);
RegShortCode('booknote', \&DoSCBookNote);
