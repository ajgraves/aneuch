#!/usr/bin/perl
## WARNING: This plugin is extremely powerful. Because it injects raw HTML
##  into a page, this could easily lead to XSS and other vulnerabilities.
##  By default, only an administrator can create a new snippet. This should
##  be little comfort to you, however. Use this plugin with caution!
package Aneuch;
return unless $Aneuch::VERSIONID >= '0060';	# Require 0.60 or higher.
RegPlugin('Snippets.pl', 'publish snippets of code for your wiki');

sub DoSnippet {
  my $code = shift;
  $code = ReplaceSpaces($code);
  return GetPrefs('Snippets',$code);
}

sub DoAdminSnippet {
  my $snippet = GetParam('snippet');
  if($snippet) {	# Editing a snippet
    if($snippet eq 'NEW') { $snippet = ''; }
    my $content = ($snippet) ? GetPrefs('Snippets',$snippet) : '';
    print Form('snippet','post', '',
      $q->div({-class=>'form-group'},
	$q->label({-for=>'snippetname'},"Name: "),
	$q->textfield(-name=>'snippetname', -size=>40, -default=>$snippet,
	  -class=>'form-control', -placeholder=>'Name your snippet')
      ),
      $q->div({-class=>'form-group'},
	$q->label({-for=>'snippetcode'},
	  "Code: (to delete the snippet, clear out the code and save)"),
	$q->textarea(-name=>'snippetcode', -columns=>80, -rows=>20,
	  -default=>$content, -class=>'form-control', 
	  -placeholder=>'Snippet contents')
      ),
      $q->submit(-class=>'btn btn-success', -value=>'Save'), " ",
      $q->input({-type=>'button', -onClick=>
	'location.href="'.AdminURL('snippet').'"', 
	-class=>'btn btn-primary', -value=>'Return to menu'})
    );
    return;
  }
  # Otherwise, main interface
  print $q->p("Here are your snippets:");
  my @snippets = GetPrefs('Snippets');
  print '<div class="list-group">';
  foreach $snip (sort @snippets) {
    print $q->a({-href=>$Url."?do=admin;page=snippet;snippet=$snip",
      -class=>'list-group-item'}, $snip);
  }
  print '</div>';
  print $q->button(-value=>'New Snippet', -class=>'btn btn-success',
    -onClick=>"location.href='$ShortUrl?do=admin;page=snippet;snippet=NEW'");
}

sub DoPostingSnippet {
  if(IsAdmin()) {
    my $name = ReplaceSpaces(GetParam('snippetname'));
    if(Trim($name) ne '') {
      my $code = UnquoteHTML(GetParam('snippetcode'));
      if($code eq '') {
	DelPrefs('Snippets',$name);
      } else {
	SetPrefs('Snippets',$name,$code);
      }
    }
  }
  ReDirect(AdminURL('snippet'));
}

RegShortCode('snippet', \&DoSnippet);
RegAdminPage('snippet', 'Manage snippets', \&DoAdminSnippet);
RegPostAction('snippet', \&DoPostingSnippet);
