#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0060';     # Require 0.60 or higher.
RegPlugin('Clip.pl', 'Article clipping for Aneuch');
my $SecretKey = 'bd20340540ab48c3eb911e8bf77abdd7c3e845dffc5e1963808ca967e26ed64a';

sub DoPostingClip {
  my $canedit = CanEdit();

  if(GetParam('secret') eq $SecretKey) { $canedit = 1; }

  # Can't edit? Error 403
  unless($canedit) {
    ErrorPage(403,"You can't post notes. Sorry.");
    return;
  }
  my $pn = GetParam(SanitizeFileName('title'),$TimeStamp);
  # Page already exists? Error 409
  if(PageExists($pn)) {
    ErrorPage(409,"Something happened and I tried to save a page that ".
      "already exists. Please go back and try again.");
    return;
  }
  my $pagetext = UnquoteHTML(GetParam('clip',''));
  if(GetParam('title')) {
    $pagetext = "=".UnquoteHTML(GetParam('title',''))."\n".$pagetext;
  }
  if(GetParam('url')) {
    $pagetext .= "\nPosted from [[".GetParam('url')."]]";
  }
  SetParam('summary', "$UserName created the page from an article at ".GetParam('url'));
  #WritePage($pn, UnquoteHTML(GetParam('note','')), $UserName);
  WritePage($pn, $pagetext, $UserName);
  ReDirect($Url.$pn);
}

RegPostAction('Clip', \&DoPostingClip);
