#!perl -w
; use strict
; use Test::More tests => 1
; use CGI
; our $CS

; BEGIN
   { if ( eval { require CGI::Builder::Session } )
      { $CS = 1
      ; eval { require './t/TestS.pm' }
            || require './TestS.pm'
      ; chdir './t'
      }
   }
   
    

; SKIP:
   { skip("CGI::Builder::Session is not installed", 1)
     unless $CS

   ; my $ap1 = TestSess->new(page_name =>'sess')
   ; my $o1 = $ap1->capture('process')
   ; ok(  $$o1 =~ /start-->.{32}<--end/i )
   }

