#!perl -w
; use strict
; use Test::More tests => 1
; use CGI

; our $CS

; BEGIN
   { chdir './t'
   ; if ( eval { require CGI::Session } )
      { $CS = 1
      ; require 'TestS.pm'
      }
   }
   
    

; SKIP:
   { skip("CGI::Session is not installed", 1)
     unless $CS

   ; my $ap1 = TestSess->new(page_name =>'sess')
   ; my $o1 = $ap1->capture('process')
   ; ok(  $$o1 =~ /start-->.{32}<--end/i )
   }

