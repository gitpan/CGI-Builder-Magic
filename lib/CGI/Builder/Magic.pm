package CGI::Builder::Magic ;
$VERSION = 1.12 ;
          
; use strict
; use Carp
; $Carp::Internal{+__PACKAGE__}++
; $Carp::Internal{'CGI::Builder::Magic::_'}++

; use File::Spec
; use Template::Magic

; my $print_code

; sub CGI::Builder::Magic::_::tm_print
   { my $s = shift
   ; my $l = $s->tm_lookups
   ; $l  &&= [ $l ] unless ref $l eq 'ARRAY'
   ; push @$l, scalar $s->page_error if defined %{$s->page_error}
   ; push @$l, { $CGI::Builder::NAME => $s->cs->id } if defined $$s{cs}
   ; push @$l, $s->tm_lookups_package
   ; $s->tm->nprint( template => $s->tm_template
                   , lookups  => $l
                   )
   }
   
; BEGIN
   { $print_code = sub{ shift()->CGI::Builder::Magic::_::tm_print(@_) }
   }

; use Object::groups
      ( { name       => 'tm_new_args'
        , default
          => sub
              { { value_handlers => [ $_[0]
                                      ->CGI::Builder::Magic::_::lookup_CODE()
                                    , 'HTML'
                                    ]
                , markers        => 'HTML'
                }
              }
        }
      )

; use Object::props
      ( { name       => 'tm_lookups'
        }
      , { name       => 'tm_template'
        , default    => sub
                         { $_[0]->page_name
                         . $_[0]->page_suffix
                         }
        }
      , { name       => 'tm_lookups_package'
        , default    => sub{ ref($_[0]) . '::Lookups' }
        }
      , { name       => 'tm'
        , default    => sub{ shift()->tm_new(@_) }
        }
      , { name       => 'page_suffix'
        , default    => '.html'
        }
      , { name       => 'page_content'
        , default    => sub{ return $print_code }
        }
      )
      
; sub tm_new
   { Template::Magic->new( %{$_[0]->tm_new_args} )
   }

; sub CGI::Builder::Magic::_::lookup_CODE     # value handler
   { my ($s) = @_
   ; sub
      { my ($z) = @_
      ; if ( ref $z->value eq 'CODE'
           && $z->location eq $s->tm_lookups_package
           )
         { $z->value = $z->value->($s, @_)
         ; $z->value_process
         ; 1
         }
      }
   }

; sub page_content_check
   { my $s = shift
   ; my $status = $s->isa('Apache::CGI::Builder')
                ? '404 Not Found'
                : '204 No Content'
   ; my $t = $s->tm_template
   ; $t = $s->tm_template = File::Spec
                            ->file_name_is_absolute( $t )
                            ? $t
                            : File::Spec->catfile( $s->page_path
                                                 , $t
                                                 )
   ; if (  not( length $s->page_content )
        || (  $s->page_content eq $print_code
           && not -f $t
           )
        )
      { $s->header( -status => $status )
            unless defined $s->header->{-status}
      ; return 0
      }
   ; 1
   }

; 1

__END__

=head1 NAME

CGI::Builder::Magic - CGI::Builder and Template::Magic integration

=head1 VERSION 1.12

The latest versions changes are reported in the F<Changes> file in this distribution. To have the complete list of all the extensions of the CBF, see L<CGI::Builder/"Extensions List">

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder    >= 1.12
    Template::Magic >= 1.0

=item CPAN

    perl -MCPAN -e 'install CGI::Builder::Magic'

If you want to install all the extensions and prerequisites of the CBF, all in one easy step:

    perl -MCPAN -e 'install Bundle::CGI::Builder::Complete'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

    # just include it in your build
    
    use CGI::Builder
    qw| CGI::Builder::Magic
      |;

=head1 DESCRIPTION

This module transparently integrates C<CGI::Builder> and C<Template::Magic> in a very handy, powerful and flexible framework that can save you a lot of coding, time and resources.

With this module, you don't need to produce the C<page_content> within your page handlers anymore (unless you want to); you don't even need to manage a template system yourself (unless you want to).

If you use a template system on your own (i.e. not integrated in a CBF extension), you will have to write all this code explicitly:

=over

=item *

create a page handler for each page as usual

=item *

create a new template object and assign a new template file

=item *

find the runtime values and assign them to the template object

=item *

run the template process and set the C<page_content> to the produced output

=back

You can save all that by just including this module in your build, because it implements an internal transparent and automagic template system that even without your explicit intervention is capable of finding the correct template and the correct runtime values to fill it, and generates the page_content automagically. With this module you can even eliminate the page handlers that are just setting the page_content, because the page is auto-magically sent by the template system.

This module uses Template::Magic specially for these advantages:

=over

=item *

L<Template::Magic|Template::Magic> is a module that can auto-magically look up the runtime values in packages, hashes and blessed objects

=item *

It has the simplest possible template syntax (idiot-proof), and it is written in pure perl (no compiler needed), so it is perfect to be used by (commercial) user-customizable CGI applications.

=item *

It uses minimum memory because it prints the output while it is produced, avoiding to collect in memory the whole (and sometime huge) content.

=back

The integration with Template::Magic allows you to move all the output-related stuff out of the page handlers,  producing a cleaner and easiest to maintain CBB.

B<Note>: All the CBF extensions are fully mod_perl 1 and 2 compatible (i.e. you can use them under both CGI and mod_perl). Anyway, an extremely powerful combination with this extension is the L<Apache::CGI::Builder|Apache::CGI::Builder>, that can easily implement a sort of L<Perl Side Include|"APACHE::CGI::Builder (Perl Side Include)"> (sort of easier, more powerful and flexible "Server Side Include").

=head2 Example

    package WebApp ;
    use CGI::Builder
    qw| CGI::Builder::Magic
      | ;
    
    # no need to setup page handlers to set the page_content
    # just setup the package where Template::Magic will looks up
    # the run time valuess
    
    package WebApp::Lookups ;
    
    # this value will be substituted to each
    # 'app_name' label in EACH TEMPLATE that include it
    our $app_name = 'WebApp 1.0' ;
    
    # same for each 'Time' label
    sub Time { scalar localtime }
    
    # and same for each 'ENV_table' block
    sub ENV_table
    {
      my ($self,        # $self is your WebApp object
          $zone) = @_ ; # $zone is the Template::Magic::Zone object
      my @table ;
      while (my @line = each %ENV)
      {
        push @table, \@line
      }
      \@table ;
    }

An auto-magically used template (it contains the 'ENV_table block', and the 'app_name' and 'Time' labels)

    <html>
    
    <head>
    <meta http-equiv=content-type content="text/html;charset=iso-8859-1">
    <title>ENVIRONMENT</title>
    <style media=screen type=text/css><!--
    td   { font-size: 9pt; font-family: Arial }
    --></style>
    </head>
    
    <body bgcolor=#ffffff>
    <table border=0 cellpadding=3 cellspacing=1 width=100%>
    <tr><td bgcolor=#666699 nowrap colspan=2><font size=3 color=white><b>ENVIRONMENT</b></font></td></tr>
    <!--{ENV_table}-->
    <tr valign=top>
    <td bgcolor=#d0d0ff nowrap><b>the key goes here</b></td>
    <td bgcolor=#e6e6fa width=100%>the value goes here</td>
    </tr>
    <!--{/ENV_table}-->
    </table>
    Generated by <!--{app_name}--> - <!--{Time}-->
    </body>
    
    </html>

=head2 How it works

This module implements a default value for the C<page_content> property: a CODE reference that produces and print the page content by using an internal C<Template::Magic> object with HTML syntax.

Since the C<page_content> property is set to its own default value before the page handler is called, the page handler can completely (and usually should) avoid to produce any output.

    sub PH_myPage
    {
      ... do_something_useful ...
      ... no_need_to_set_page_content ...
      ... returned_value_will_be_ignored ...
    }

This module just calls the page handler related with the C<page_name>, but it does not expect any returned value from it.

An ideal organized Magic application uses the page handler only if the application has something special to do for any particular page. The output production is usually handled auto-magically by the template system.

The output will be generated internally by the merger of the template file and the runtime values that are looked up from the C<FooBar::Lookup> package ('FooBar' is not literal, but stands for your application namespace plus the '::Lookups' string).

In simplest cases you can also avoid to create the page handler for certain pages: by default the template with the same page name will be used to produce the output.

This does not mean that you cannot do things otherwise when you need to. Just create a page handler and set there all the properties that you want to override:

   sub PH_mySpecialPage
   {
     my $s = shift ;
     $s->tm_lookups = { special_key => 'that' } ;
     $s->tm_template = '/that/special/template' ;
   }

Since the page handler sets the C<tm_lookups> and the C<tm_template> properties, the application will add a special hash to the usual lookup, and the template system will print with a specific template and not with the default 'mySpecialPage.html'.

If some page handler needs to produce the output on its own (completely bypassing the template system) it can do so by setting the C<page_content> property as usual (i.e. with the page content or with a reference to it)

   sub PH_mySpecialPage
   {
     my $s = shift ;
      ... do_something_useful ...
     # will bypass the template system
     $s->page_content  = 'something';
     $s->page_content .= 'something more';
   }

For the 'mySpecialPage' page, the application will not use the template system at all, because the C<page_content> property was set to the output.

B<Note>: For former CGI::Application users: the returned value of any page handler will be ALWAYS ignored, so set explicitly the C<page_content> property when needed.

=head2 Lookups

=head3 *::Lookups package

This is a special package that your application should define to allow the internal Template::Magic object to auto-magically look up the run time values.

The name of this package is contained in the L<"tm_lookups_package"> property. The default value for this property is 'FooBar::Lookup' where 'FooBar' is not literal, but stands for your CBB namespace plus the '::Lookups' string, so if you define a CBB package as 'WebApp' you should define a 'WebApp::Lookups' package too (or set the C<tm_lookup_package> property with the name of the package you will use as the lookup).

In this package you should define all the variables and subs needed to supply any runtime value that will be substituted in place of the matching label or block in any template.

The lookup is confined to the C<*::Lookups> package on purpose. It would be simpler to use the same CBB package, but this would extend the lookup to all the properties, methods and handlers of your CBB and this might cause conflict and security holes. So, by just adding one line to your CBB, (e.g. 'package FooBar::Lookups;') you can separate your CBB from the lookup-allowed part of it.

B<Note>: Obviously you can also put the C<*::Lookup> package in its own '.pm' file, thus making it simply loadable from different CBBs.

=head3 *::Lookups subs

The subs in the C<*::Lookups> package are executed by the template lookup whenever a label with the same identifier is found. They receive your application object ($self) in $_[0], so even if they are defined in a different package, they are just like the other methods in your class.

The subs will receive the C<Template::Magic::Zone> object as $_[1], so you can interact with the zone as usual (see L<Template::Magic>)

Usually a sub in the *::Lookup package is an ending point and should not need to call any other subs in the same *::Lookup package. If you feel the need to do otherwise, you probably should re-read L<Template::Magic> because you are trying to do something that Template::Magic is already doing auto-magically. Anyway, if you found some esoteric situation that I never thinked about, you can do *::Lookup subs callable from the same package by just making your CBB package a subclass of *::Lookup package by adding a simple C<push our @ISA, 'FooBar::Lookups';> statement in it.

=head3 How to add lookup locations

If you want the C<Template::Magic> object to look up in some more location, e.g. if you want the object to loookup in the param hash and in %ENV, you can choose beetween a couple of solutions: you can use the C<tm_lookups> property or the C<tm_new_args> group property.

This is the first option:

    # this will be add as the first lookups
    $s->tm_lookups = [ scalar $s->param ,      # param hash ref
                       \%ENV  ] ;              # %ENV ref

Or you have a second option: add this statement anywhere before using the C<tm> object and before the RESPONSE phase (e.g. in the OH_init(), in the page handler itself)

    # this will be add as the last lookups
    $s->tm_new_args
      ( lookups => [ scalar $s->param ,      # param hash ref
                     \%ENV  ]);              # %ENV ref

B<Note>: The first option uses the temporary lookups capability of Template::Magic object, while the second one uses the constructor array lookups. They have almost the same effect on the output (the difference is just the lookups order). The use of the first has less requirements so try it first. See L<Template::Magic> for more details.

=head2 The template syntax

This module implements a C<Template::Magic::HTML> object, so the used C<markers> are the default HTML markers e.g.:

    <!--{a_block_label}--> content <!--{/a_block_label}-->

and the I<value handlers> are the default HTML handler, so including C<TableTiler> and C<FillInForm> handlers by default. Please, read L<Template::Magic> and L<Template::Magic::HTML>.

=head2 How to organize your CBB

=over

=item 1

Set all the actions common to all pages in the C<OH_init()> handler (as usual)

=item 2

Prepare a template for each page addressed by your application

=item 3

Set the variables or the subs in the C<*::Lookups> package that the internal C<Template::Magic> object will look up (that could be picked up by one or more templates processing)

=item 4

Define just the page handlers that needs to do something special

=item 5

Use the properties default values, that can save you a lot of time ;-)

=back

=head1 SPECIAL INTEGRATIONS

This extension will add some special features to your CBB when some specific extension is included.

=head2 Apache::CGI::Builder (Perl Side Include)

SSI (Server Side Includes) are directives that are placed in HTML pages, and evaluated on the server while the pages are being served. The Apache server uses the C<mod_include> Apache module to process the pages, but you can configure it to process the pages by using your own CBB, that can easily implement a lot of more custom 'directives' in the form of simple labels.

In other words: your own CBB transparently process the pages of a web dir, supplying the dinamic content that will be included in the page just before they are served.

With this technique B<your application does not need to handle neither page names, nor page handlers, nor template managements>: all that is auto-magically handled by the combination of C<Apache::CGI::Builder> and C<CGI::Builder::Magic> extensions.

Please, take a look at the 'perl_side_include' example in this distribution to understand all the advantages offered by this technique.

=head2 CGI::Builder::Session

When you include in your CBB the CGI::Builder::Session extension, you will have magically available a label that will be substituted with the current session id. The label identifier is the same name contained in the $CGI::Session::NAME variable which is usually 'CGISESSID', unless you have set it otherwise.

   <!--{CGISESSID}-->

E.g.: You can use it to set the value of an hidden field in your forms.

=head2 CGI::Builder::DFVCheck

The CGI::Builder::DFVCheck extension sets the CBF C<page_error> property with the errors found in your forms. CGI::Builder::Magic adds that property to its lookups, so each error found will have its own label defined. See L<" CGI::Builder::DFVCheck"> for more details.

=head1 PROPERTY and GROUP ACCESSORS

This module adds some template properties (all those prefixed with 'tm_') to the standard CBF properties. The default of these properties are usually smart enough to do the right job for you, but you can fine-tune the behaviour of your CBB by setting them to the value you need.

=head2 tm_lookups_package

This property allows you to access and set the name of the package where the Template::Magic object will look up by default. The default value for this property is'FooBar::Lookup' where 'FooBar' is not literal, but stands for your application namespace plus the '::Lookups' string. (i.e. 'WebApp::Lookup').

=head2 tm_lookups

This property allows you to access and set the 'lookups' argument passed to the Template::Magic::nprint() method (see L<Template::Magic/"nprint ( arguments )">)

=head2 tm_template

This property allows you to access and set the 'template' argument passed to the Template::Magic::nprint() method (see L<Template::Magic/"nprint ( arguments )">). Set This property to an absolute path if you want bypass the C<page_path> property.

=head2 CBF changed property defaults

=head3 CBF page_suffix

This module sets the default of the C<page_suffix> to '.html'. You can override it by just setting another suffix of your choice.

=head3 CBF page_content

This module sets the default of the C<page_content> to a CODE reference that produces the page content by using an internal Template::Magic object with HTML syntax (see also L<"How it works">). If you want to bypass the template system in any Page Handler, just explicitly set the C<page_content> to the content you want to send.

=head1 ADVANCED FEATURES

In this section you can find all the most advanced or less used features that document all the details of this module. In most cases you don't need to use them, anyway, knowing them will not hurt.

=head2 tm

This property returns the internal C<Template::Magic> object.

This is not intended to be used to generate the page output - that is generated automagically - but it could be useful to generate other outputs (e.g. messages for sendmail) by using the same template object, thus preserving the same arguments.

B<Note>: You can change the default arguments of the object by using the C<tm_new_args> property, or you can completely override the creation of the internal object by overriding the C<tm_new()> method.

=head2 tm_new()

This method is not intended to be used directly in your CBB. It is used internally to initialize and return the C<Template::Magic> object. You can override it if you know what you are doing, or you can simply ignore it ;-).

=head2 tm_new_args( arguments )

This property group accessor handles the Template::Magic constructor arguments that are used in the creation of the internal Template::Magic object. Use it to add some more lookups your application could need, or finetune the behaviour if you know what are doing (see L<"How to add lookup locations"> and L<Template::Magic/"new ( [constructor_arrays] )">).

B<Note>: You can completely override the creation of the internal object by overriding the C<tm_new()> method.

=head2 CBF overridden methods

=head3 page_content_check

This extension use this method to check if the template file exists before using its template print method, thus avoiding a fatal error when the requested page is not found. Instead of an error, the process will send a '204 No Content' status to the client or a '404 Not Found' status if the CBB is including Apache::CGI::Builder.

B<Important Note>: To make this method work as documented, this extension must override other eventual page_content_check() methods defined in other extension, so it has to be included AFTER Apache::CGI::Builder that defines its own page_content_check():

    use CGI::Builder
    qw| Apache::CGI::Builder
        CGI::Builder::Magic
      |;

B<Note>: You don't need to directly use this method since it's internally called at the very start of the RESPONSE phase. You don't need to override it if you want just to send a different header status, since it sets the status just if it is not defined yet.

=head1 SUPPORT

Support for all the modules of the CBF is via the mailing list. The list is used for general support on the use of the CBF, announcements, bug reports, patches, suggestions for improvements or new features. The API to the CBF is stable, but if you use the CBF in a production environment, it's probably a good idea to keep a watch on the list.

You can join the CBF mailing list at this url:

    http://lists.sourceforge.net/lists/listinfo/cgi-builder-users

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (http://perl.4pro.net)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

