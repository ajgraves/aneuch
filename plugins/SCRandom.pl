#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0060';     # Require 0.60 or higher.
RegPlugin('SCRandom.pl', 'Random page link shortcode');

RegShortCode('random',\&DoShortCodeRandom);
RegShortCode('randomdl',\&DoShortCodeRandomDirect);
RegSpecialPage('Random',\&DoRandomPage);

sub DoShortCodeRandom {
  my $text = shift;
  #return '<iframe width="560" height="315" src="https://www.youtube.com/embed/'.$text.'" frameborder="0" allowfullscreen></iframe>';
  return CommandLink('random',$Page,($text ? $text : 'Random Page'), 'Navigate to a random page');
}

sub DoShortCodeRandomDirect {
  # This code pretty much taken directly from DoRandom() in aneuch.pl. Will provide
  #  a direct link to a random page.
  my @files = ListAllPages();
  my $count = @files;
  if($count < 1) {
    push @files, $DefaultPage;
    $count = 1;
  }
  my $randompage = int(rand($count));
  return $q->a({-href=>$Url.$files[$randompage], -title=>'randomly selected page'}, ReplaceUnderscores($files[$randompage]));
}

sub DoRandomPage {
  my $i;
  my $count = GetParam('count',20);
  if($count !~ /\d+/) { $count = 20; }
  print '<form role="form" class="form-inline">'.
    $q->div({-class=>'input-group'},
      $q->textfield(-name=>'count', -placeholder=>'Enter a new count',
	-class=>'form-control'),
      $q->span({-class=>'input-group-btn'},
	'<button type="submit" class="btn btn-default">Go!</button>'
      )
    ).
    '</form>';
  print $q->p("Here are $count random pages for you to check out:");
  print '<ol>';
  for($i=0;$i<$count;$i++) {
    print $q->li(DoShortCodeRandomDirect());
  }
  print '</ol>';
}
