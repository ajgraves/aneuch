#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0040';     # Require 0.40 or higher.
RegPlugin('Links.pl', 'Will add a form to page "Links" that makes maintaining a link list super easy!');

sub DoLinkPage {
  return unless IsAdmin();
  print $q->a({-name=>'bottom'});
  print $q->hr();
  print $q->p('Create a new link:');
  print Form('pl_link','post','',
    $q->div({-class=>'row'},
      $q->div({-class=>'col-md-4'},
	$q->div({-class=>'form-group'},
	  $q->label({-for=>'url'},'URL: '),
	  $q->textfield(-name=>'url', -class=>'form-control')
	),
	$q->div({-class=>'form-group'},
	  $q->label({-for=>'title'},'Title: '),
	  $q->textfield(-name=>'title', -class=>'form-control')
        ),
	$q->div({-class=>'form-group'},
	  $q->label({-for=>'description',},'Description: '),
	  $q->textfield(-name=>'description', -class=>'form-control')
	),
	$q->submit(-class=>'btn btn-default', -value=>'Save'),
      )
    )
  );
}

sub DoPostingLink {
  ReDirect($Url.'Links') unless IsAdmin();
  my $title = UnquoteHTML(GetParam('title',''));
  my $url = GetParam('url','');
  my $description = UnquoteHTML(GetParam('description',''));
  if(!$url) {
    ErrorPage(400, "URL field is required!");
    return;
  }
  my $link = "[[$url";
  $link .= "|$title" if $title;
  $link .= "]]";
  if($description) {
    $link .= " - $description";
  }
  #AppendPage('Links', "$link\n\n", $UserName);
  my %p = GetPage('Links');
  $p{text} .= "$link\n\n";
  SetParam('summary', "Added new link '$url'");
  WritePage('Links', $p{text}, $UserName);
  ReDirect($Url.'Links#bottom');
}

RegSpecialPage('Links', \&DoLinkPage);
RegPostAction('pl_link', \&DoPostingLink);
