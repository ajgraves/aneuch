#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0040';     # Require 0.40 or higher.
RegPlugin('SCNoticeWarning.pl', 'Shortcodes to add notice and warning blocks to pages');

RegShortCode('notice',\&DoShortCodeNotice);
RegShortCode('warning',\&DoShortCodeWarning);

my $NoticeStyle = "border-width: 1px 1px 1px 10px; border-style: solid; ".
  "border-color: #AAA #AAA #AAA #F28500; ".
  "background: none repeat scroll 0% 0% #FBFBFB; margin: 10px 30px; ".
  "padding:20px;";

my $WarningStyle = "border-width: 1px 1px 1px 10px; border-style: solid; ".
  "border-color: #AAA #AAA #AAA #CC1122; ".
  "background: none repeat scroll 0% 0% #FBFBFB; margin: 10px 30px; ".
  "padding:20px;";

sub DoShortCodeNotice {
  my $text = shift;
  my $return = $q->div({-style=>$NoticeStyle},$text);
  return $return;
}

sub DoShortCodeWarning {
  my $text = shift;
  my $return = $q->div({-style=>$WarningStyle},$text);
  return $return;
}
