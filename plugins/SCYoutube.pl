#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0050';     # Require 0.40 or higher.
RegPlugin('SCYoutube.pl', 'Youtube shortcode');

RegShortCode('youtube',\&DoShortCodeYoutube);

sub DoShortCodeYoutube {
  my $text = shift;
  return '<iframe width="560" height="315" src="https://www.youtube.com/embed/'.$text.'" frameborder="0" allowfullscreen></iframe>';
}