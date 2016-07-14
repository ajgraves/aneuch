#!/usr/bin/perl
package Aneuch;
return unless $Aneuch::VERSIONID >= '0050';     # Require 0.50 or higher.
RegPlugin('Sitemap.pl', 'Simple sitemap generator');

sub DoSitemap {
  my @pages = ListAllPages();
  print "Content-type: application/xml\n\n";
  print '<?xml version="1.0" encoding="UTF-8"?>'."\n".
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'."\n";
  foreach my $page (@pages) {
    #my %P = GetPage($page);
    my $archive = substr($page,0,1); $archive =~ tr/a-z/A-Z/;
    chomp(my $ts = `grep ^ts: $PageDir/$archive/$page | awk '{print \$2}'`);
    chomp(my $lastmod = `date -d \@$ts +%Y-%m-%d`);
    print "  <url>\n".
      "    <loc>$Url$page</loc>\n".
      "    <lastmod>$lastmod</lastmod>\n".
      "  </url>\n";
  }
  print '</urlset>';
}

sub DashboardSitemap {
  print $q->h3('Sitemap');
  print $q->p('A '.
    $q->a({-href=>$Url.'sitemap.xml'},'sitemap.xml').
    ' file is automatically generated any time it is requested.');
}

RegDashboardItem(\&DashboardSitemap);
RegCommand('sitemap', \&DoSitemap, 'was downloading the sitemap');
RegRawHandler('sitemap');
if($Page eq 'sitemap.xml') { SetParam('do','sitemap'); }
