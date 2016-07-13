#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0050';     # Require 0.40 or higher.
RegPlugin('SCDownloadView.pl', 'Registers the "Download" and "View" shortcodes');

RegShortCode('download',\&DoShortCodeDownload);
RegShortCode('view',\&DoShortCodeView);

sub DoShortCodeDownload {
  my $text = shift;
  return CommandLink('download',ReplaceSpaces($text),$text,
    'Download file "'.ReplaceSpaces($text).'"');
}

sub DoShortCodeView {
  my $text = shift;
  return CommandLink('view',ReplaceSpaces($text),$text,
    'View file "'.ReplaceSpaces($text).'"');
}