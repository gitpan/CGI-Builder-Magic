#!perl -w
; use strict
; use Test::More tests => 2
; use CGI

; our $DFV

; BEGIN
   { chdir './t'
   ; if ( eval { require CGI::Builder::DFVCheck } )
      { $DFV = 1
      ; require 'TestD.pm'
      }
   }
   
    

; SKIP:
   { skip("CGI::Builder::DFVCheck is not installed", 2)
     unless $DFV

   ; my $ap1 = TestDFV->new()
   ; my $o1 = $ap1->capture('process')
   ; ok(  $$o1 =~ /start--><span.+<--end/i )
   
   ; my $ap2 = TestDFV->new(page_name => 'dfv')
   ; my $o2 = $ap2->capture('process')
   ; ok(  $$o2 =~ /start--><--end/i )
   }

