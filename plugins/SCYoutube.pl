#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0050';     # Require 0.40 or higher.
RegPlugin('SCYoutube.pl', 'Youtube shortcode');

RegShortCode('youtube',\&DoShortCodeYoutube);

sub DoShortCodeYoutube {
  my $text = shift;
  #return '<iframe width="560" height="315" src="https://www.youtube.com/embed/'.$text.'" frameborder="0" allowfullscreen></iframe>';
  #return '<div class="embed-responsive embed-responsive-16by9">'.
  #  '<iframe class="embed-responsive-item" frameborder="0" allowfullscreen '.
  #  'src="https://www.youtube.com/embed/'.$text.'></iframe></div>';
  return $q->div({-class=>'row'},
    $q->div({-class=>'col-sm-6'},
      $q->div({-class=>'embed-responsive embed-responsive-16by9'},
	'<iframe class="embed-responsive-item" frameborder="0" '.
	  'allowfullscreen src="https://www.youtube.com/embed/'.$text.'">'.
	  '</iframe>'
      )
    )
  );
}
