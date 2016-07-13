#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0050';     # Require 0.40 or higher.
RegPlugin('Categories.pl', 'Will create a page called Categories that lists all categories on the wiki.');
my $CategorySummaryLength = 2000;
my $CategoriesPage = 'Categories';

sub DoCategoryPage {
  print $q->p('Category listing:');
  print "<p>";
  foreach $cat (ListAllCategories()) {
    my $label = $cat; $label =~ s/^Category//;
    $label =~ s/([A-Z])/ $1/g; $label = Trim($label);
    #print $q->a({-href=>"$Url?do=search;search=$cat",
    print $q->a({-href=>"$Url?do=category;category=$cat",
      -title=>"Find pages in the \"$label\" category"}, $label);
    print $q->br();
  }
  print "</p>";
}

sub ListAllCategories {
  my $search = '\tCategory[\w+]';
  #my @catlisting = split(/\n/, `grep -Pr '$search' $PageDir | awk '{print \$2}' | sort | uniq`);
  my @catlisting = split(/\n/, `grep -Prh '$search' $PageDir | sed "s/\\t//" | tr " " "\\n" | sort | uniq`);
  return @catlisting;
}

sub DoCommandCategory {
  my $category = GetParam('category');
  my $returnlink = $q->a({-href=>$Url.$CategoriesPage,
    -title=>"Return to category list"}, "&larr; $CategoriesPage");
  print $q->p($returnlink);
  my @pages = split(/\n/, `grep -lr '$category' $PageDir | sort | uniq`);
  s#^$PageDir/.{1}/## for @pages;
  print $q->p(scalar(@pages)." page(s) categorized as $category");
  foreach my $fn (@pages) {
    my %F = GetPage($fn);
    print "<big><a href='${Url}${fn}'>$fn</a></big><br/>";
    print "<small>Last modified ".
      (FriendlyTime($F{ts}))[$TimeZone]."</small><br/>";
    if(length($F{text}) > $CategorySummaryLength) {
      print QuoteHTML(substr($F{text},0,$CategorySummaryLength))." . . .";
    } else {
      print QuoteHTML($F{text});
    }
    print "<br/><br/>";
  }
  print $q->p(scalar(@pages)." page(s) categorized as $category");
  print $q->p($returnlink);
}

sub DoShortCodeCategory {
  my $text = shift;
  return $q->a({-href=>"$Url?do=category;category=$text",
      -title=>"Find pages in the $text category"}, $text);
}

RegSpecialPage($CategoriesPage, \&DoCategoryPage);
RegCommand('category', \&DoCommandCategory, 'was viewing pages categorized as %s');
RegShortCode('category',\&DoShortCodeCategory);

if($PageName eq "category" and GetParam('do') eq "category") {
  $PageName = GetParam('category');
  $PageName =~ s/^Category/Category /;
  $Page = GetParam('category');
}
