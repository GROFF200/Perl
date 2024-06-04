#!/usr/local/bin/perl

require 'c:\\tools\\url_get.pl';

#----------------------------------------------------------------------
# Description:  This program takes as an argument a starting HTML file.
#    It then verifies all the links in that file and all the files that
#    are called by those files.  This program will not verify links 
#    that refer to servers other than the local server.  Be sure to 
#    set the SERVER and PORT parameters.
#----------------------------------------------------------------------

# Declare global variables.

local($SERVER,$PORT) = ("www.skytel.com","1188");    # All CAPS means constant
local($DEFAULT_FILE) = ("index.html");
local($g_start_file,@g_problems,@g_visited_files);   # g_<var> means global
local($g_verified_anchors);
local($g_server_root);

#if (@ARGV != 1)
#{
#   print "Usage: www_links.pl <starting_html>\n";
#   exit;
#}

$g_server_root = `pwd`;
chop $g_server_root;
$g_start_file = "$ARGV[0]";
@g_visited_files = ();
@g_problems = ();
@g_verified_anchors = ();

#----------------------------------------------------------------------
#                           MAIN PROGRAM            
#----------------------------------------------------------------------
print "\nSearching $start_file, please wait...\n";

#(-r $g_start_file) ?
#(&visit_html($g_start_file,0)) :
#   (print "You nut! I can't even open $g_start_file!\n");

&visit_html($g_start_file, 0);

if (@g_problems)
{
   print "\n------------------------------\n";
   print "Possible Problems Encountered:\n";
   print "------------------------------\n";
   &print_list(@g_problems);
}

print "\nFinished.\n";

#----------------------------------------------------------------------
#                            SUBROUTINES
#----------------------------------------------------------------------

#---------------------------------------------------
# print_list : Simple routine to print the elements
#   of an array.
#---------------------------------------------------
sub print_list
{
   local(@list) = @_;
   local($element);

   foreach $element (@list)
   {
      print "$element\n";
   }
}

#---------------------------------------------------
# visit_html : This routine takes as arguments the
#   name of a file and a recursion level.  The level
#   indicator is used in producing the output
#   report.  The file is retrieved, and then all of
#   the HTML tags I need are extracted.  If the tag
#   is an .html or .map file, then it is also
#   visited.
#---------------------------------------------------
sub visit_html
{
   local($file,$recursion_level) = @_;
   local($path_only,$file_only);
   local($server,$port,$new_file);
   local(@tags,@contents,$content);

   if (grep(/^$file$/,@g_visited_files))
   {
      return;
   }

   push(@g_visited_files,$file);

   ($path_only,$file_only) = &split_path($file);

   @contents = &read_file($file);
   $content = join(" ",@contents);

   @tags = &get_tags($content,$file_only);

   foreach $tag (@tags)
   {
      if ($tag =~ /mailto:/)
      {
         &add_to_prob($file,$tag) if ($tag eq "mailto:");
      }
      else
      {
         #($server,$port,$new_file) = &parse_url($tag,$path_only);
         #&add_to_prob($file,$tag);
         &handle_new_file($file,$tag,$tag,$recursion_level+1);
      }
   }
}

#---------------------------------------------------
# add_to_prob : Takes the original file name and
#   the tag and inserts them in to the problems
#   list.
#---------------------------------------------------
sub add_to_prob
{
   local($file,$tag) = @_;

   $file =~ s/$g_server_root//;
   push(@g_problems,"$file -> $tag");
}

#---------------------------------------------------
# handle_new_file : This routine takes a new file
#   pulled from a HTML tag, and will either hand
#   it off to visit_html or take care of it some
#   other way.
#---------------------------------------------------
sub handle_new_file
{
   local($old_file,$new_file,$tag,$recursion_level) = @_;
   local($path_only,$file_only);

   if ($new_file=~ /.zip/ || $new_file=~ /.mid/)
   {
        return;
   }
   else
   {
        &visit_html($new_file,$recursion_level);
   }
}

#---------------------------------------------------
# anchor_valid : This routine confirms that a page
#   anchor exists in the document.
#---------------------------------------------------
sub anchor_valid
{
   local($file) = @_;
   local(@contents,$content,$anchor,$return_code);

   $return_code = 1;
   $file =~ s/\*/\\\*/g;
   $file =~ s/\?/\\\?/g;

   unless (grep(/^$file$/,@g_verified_anchors))
   {
      $file =~ s/#([^\/]+)$//;
      $anchor = $1;
      $anchor =~ s/\*/\\\*/g;
      $anchor =~ s/\?/\\\?/g;

      if (-r $file)
      {
         @contents = &read_file($file);
         $content = join(" ",@contents);

         if ($content =~ /<a\s+.*name\s*=\s*"*$anchor"*>/i)
         {
            push(@g_verified_anchors,"$file#$anchor");
         }
         else
         {
            $return_code = 0;
         }
      }
      else
      {
         $return_code = 0;
      }
   }
   $return_code;
}

#---------------------------------------------------
# split_path : Takes as an argument the full path
#   name of a file.  It returns as two seperate 
#   arguments the path and file name.
#---------------------------------------------------
sub split_path
{
   local($path) = @_;
   local($file_only);

   $path =~ s/([^\/]*)$//;
   $file_only = $1;

   $path = "." if ($path eq "");
   chop $path if ($path =~ /\/$/);

   ($path,$file_only);
}
   
#---------------------------------------------------
# parse_url : This routine takes a URL and extracts
#   the server name, port, and path.  If none of
#   these are in the URL, then the defaults are
#   used.
#---------------------------------------------------
sub parse_url
{
   local($url,$pwd) = @_;
   local($server,$port,$path);

   $server = $SERVER;
   $port = $PORT;

   if ($url =~ /http/)
   {
      $url =~ s/http:\/\/([^:\/]+)//;
      $server = $1;
      if ($url =~ s/:(\d+)//)
      {
         $port = $1;
      }
   }
   
   ($url eq "")?
      ($path = "/"):
      ($path = $url);

   # Determine if the base directory is PWD or SERVER_ROOT.

   if ($path =~ /^\//)
   {
      $path = $path;
   }
   else
   {
      $path = "$path";
   }

   # Remove the ".." from directory names.
   while ($path =~ s#[^/]+/\.+/##)
   {};

   ($server,$port,$path);
}

#---------------------------------------------------
# get_tags : This routine takes as an argument one
#   long string that contains the contents of a
#   html file.  The progrogrammed tags are then
#   extracted from this string.
#---------------------------------------------------
sub get_tags
{ 
   local($html,$file) = @_;
   local(@all_tags,@wanted_tags,$tag);

   # Okay, remove everything not protected by brackets <>.
   $html =~ s/[^<]*//;  # Remove everything before first < bracket.
   $html =~ s/(<[^>]*>)[^<]*/\1\n/g; # Keep stuff in <> but remove up to next <.

   # Now $html has only tags in it.
   (@all_tags) = split("\n",$html);

   # Now pull out the tags I am interested in, and return only file name.
   foreach $tag (@all_tags)
   {
      # See if this is an anchor tag.
      if ($tag =~ s/<a\s+.*href\s*=\s*//i)
      {
         $tag = &extract_file_name($tag);
         $tag = $file.$tag if ($tag =~ /^#/);
         push(@wanted_tags,$tag);
      }
      elsif ($tag =~ s/<img\s+.*src\s*=\s*//i)
      {
         $tag = &extract_file_name($tag);
         push(@wanted_tags,$tag);
      }
      elsif ($tag =~ s/<!--\s*#include\s+virtual\s*=\s*//i)
      {
         $tag = &extract_file_name($tag);
         push(@wanted_tags,$tag);
      }
      elsif ($tag =~ s/<\s*form\s+.*action\s*=\s*//i)
      {
         $tag = &extract_file_name($tag);
         push(@wanted_tags,$tag);
      }
   }
   @wanted_tags;
}

#----------------------------------------------------
# add_if_unique : This routine will add an element
#   to a list if it does not already exist.
#----------------------------------------------------
sub add_if_unique
{
   local($element,@list) = @_;

   unless (grep(/^$element$/,@list))
   {
      push(@list,$element);
   }
 
   @list;
}

#----------------------------------------------------
# extract_file_name : This routine takes as an
#   argument a string that contains a file name hidden
#   in it somewhere.  If there are quotes in the
#   string, then the file will be in the first set.
#   Otherwise, just delete everything after the first
#   space.
#----------------------------------------------------
sub extract_file_name
{
   local($file) = @_;

   #if ($file =~ s/"//)
   #{
   #   $file =~ s/".*//;
   #}
   #else
   #{
   #   $file =~ s/\s*//;
   #   $file =~ s/>.*//;
   #}
   if ($file=~ /\"(.*)\"/)
   {
        $file=$1;
   }
   ($file, $trash)=split(/\s+/, $file);
    $file=~ s/\"//ge;    
   $file;
}

#---------------------------------------------------
# read_file : This routine takes as an argument the
#    name of a file.  The contents are returned
#    as the function's return value.
#---------------------------------------------------
sub read_file
{
   local($fname) = @_;
   local(@contents,*FILE,$line);

   #&warning("$fname does not exist, can not open for reading.") if (!(-e $fname));
   $url=$fname;
   $host="www2.netdoor.com/~delonad/";
   print "Url, before processing: $url\n";
   if ($url=~ /\/(.*)/)
   {
   }
   else
   {
        $url="/".$url;
   }
   if ($url=~ /http:/)
   {
        $complete=1;
   }
   else
   {
        $complete=0;
   }
   if ($complete==0)
   {
        $cmd="java SendNT http://$host$url";
   }
   else
   {
       
        ($one, $two, $newhost, $trash)=split(/\//, $url);
        ($oldhost, $trash)=split(/\//, $host);
        if ($oldhost eq $newhost)
        {
             $host="";
             $cmd="java SendNT $url";
        }
        else
        {
              return;
        }
        
   }
   print "Attempting to access URL: $host$url\n";
   $text=`$cmd`;
   if ($text=~ /404 File Not Found/ || $text=~ /Incorrect command/)
   {
        print "Adding problem: $url\n";
        &add_to_prob($url,$url);
   }
   @contents=split(/\n/, $text);
   foreach $line (@contents)
   {
      chop $line;
   }
   @contents;
}

