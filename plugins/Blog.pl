#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0060';	# Require 0.60 or higher
RegPlugin('Blog.pl', 'Blogging features for Aneuch');
our $BlogPattern;

sub DoBlog {
  my $params = shift;
  my $return;
  my $offset = GetParam('offset',0);
  my $limit = GetParam('limit',10);
  #my $upper = $offset+$limit;

  #my @blogpages = glob("$PageDir/*/$BlogPattern");
  my @blogpages = grep(/^$BlogPattern/, ListAllPages());
  my $count = scalar(@blogpages);
  @blogpages = sort { $b cmp $a } @blogpages;
  @blogpages = @blogpages[$offset..$offset+$limit];
  #return join("<br/>",@blogpages);
  if(CanEdit()) {
    $return .= DoBlogForm();
    $return .= $q->p();
  }

  foreach my $page (@blogpages) {
    next if not $page;
    my $pagename = $page; $pagename =~ s/^$BlogPattern//; $pagename =~ s/_/ /g;
    my %f = GetPage($page);
    my $date;
    if($page =~ m/^($BlogPattern)/) {
      $date = $1; $date =~ s/_{1,}$//;
    }
    $return .= $q->div({-class=>'panel panel-default'},
      $q->div({-class=>'panel-heading'},
	$q->h3({-class=>'panel-title',-id=>SanitizeFileName($page)},
	  $q->strong($q->a({-href=>$Url.$page},$pagename))
	),
	$q->small($q->em('Posted on '.$date))
      ),
      $q->div({-class=>'panel-body'},Markup($f{text})),
      $q->div({-class=>'panel-footer'}, $q->small(
	($DiscussPrefix) ? $q->a({-href=>$Url.$DiscussPrefix.$page},
	  'Discuss '.ReplaceUnderscores($page).' ('.DiscussCount($page).')') :
	  '')
      )
    );
  }
  return $return;
}

sub DoBlogForm {
  return Form('blog','post','form-inline',
    $q->div({-class=>'input-group'},
      $q->textfield(-class=>'form-control', -name=>'title', -size=>'40',
        -placeholder=>'Enter blog title'),
      $q->span({-class=>'input-group-btn'},
        '<button type="submit" class="btn btn-primary">New entry</button>')
    )
  );
}

sub DoBlogDashboard {
  print $q->h3('Blog');
  print DoBlogForm();
}

sub DoPostingBlog {
  my $page = GetParam('title');
  if(!$page) {
    ReDirect($Url);
    return;
  }
  chomp(my $date = `date +%Y-%m-%d`);
  ReDirect($Url.'?do=edit;page='.$date.'_'.SanitizeFileName($page));
}

RegShortCode('blog', \&DoBlog);
$BlogPattern = '\d{4}-\d{2}-\d{2}_' unless defined $BlogPattern;
RegDashboardItem(\&DoBlogDashboard);
RegPostAction('blog', \&DoPostingBlog);
