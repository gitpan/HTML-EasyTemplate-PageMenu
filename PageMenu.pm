package HTML::EasyTemplate::PageMenu;
use HTML::TokeParser;
use strict;
use Cwd;
use warnings;
use URI::Escape;


our $VERSION = 0.1;		# 07/05/2001

=head1 NAME

HTML::EasyTemplate::PageMenu - make an HTML menus of your page.

=head1 DESCRIPTION

Provide an easy means of creating from a page's elements a representative block of HTML suitable for use as a substitution item in an HTML::Easytemplate, or as freestanding mark-up.

=head1 SYNOPSIS

Add links to C<TARGET> elements in C<HTML>; print the modified doc, followed by the modified C<MENU>:

	use HTML::EasyTemplate::PageMenu;
	my $m = new HTML::EasyTemplate::PageMenu (
		'HTML'			=> 'test.html',
		'TARGET'		=>	['H1','H2',],
	);
	print $m->{HTML},"\n";
	print $m->{MENU},"\n";

Add the following lines to the above for a menu in an HTML::EasyTemplate, as C<TEMPLATEITEM name='menu1'> (based on the example provided in C<HTML::EasyTemplate>):

	use HTML::EasyTemplate;
	my $TEMPLATE = new HTML::EasyTemplate( $m->{HTML} );
	$TEMPLATE -> process('fill', {'menu' => $m->{MENU}} );
	$TEMPLATE -> save( 'E:/a/dir','new2.html');
	print "Saved the document with a menu as <$TEMPLATE->{ARTICLE_PATH}>\n";
	__END__


=head1 DEPENDENCIES

	Cwd;
	HTML::TokeParser;
	URI::Escape;
	strict;
	warnings;

=head1 CONSTRUCTOR METHOD (new)

The method expects a package/class referemnce as it's first parameter.  Following that, arguments should be passed in the form of an anonymous hash or as name/value pairs:

	my $m = new HTML::EasyTemplate::PageMenu (
			'arg1'=>'val1','arg2'=>'val2',
	);

or:

	my $m = new HTML::EasyTemplate::PageMenu (
			{'arg1'=>'val1','arg2'=>'val2',}
	);

=head2 ARGUMENTS

=item HTML

As an argument: the page to process: either a scalar representing the path to a file, or a reference to a scalar that is the document to be parsed.

Then initiated as a public instance variable containing the modified HTML the object was called with (ie. with anchors inserted).

=item TARGET

Array of case-insensitive scalars that represent the elements that contain text to be used in the menu (typically C<[H1,H2]>).

=item LIST_START, LIST_END

HTML to wrap around the menu output.

Default is C<UL> element.

=item ARTICLE_START, ARTICLE_END

HTML to wrap around each menu item.

Default is C<LI> element.

=cut


sub new { my ($class) = (shift);
	my %args;
	my $self = {};
	bless $self, $class;
	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }

	# Set default values for public instance variables
	$self->{LIST_START}		= '<UL>';
	$self->{LIST_END}		= '</UL>';
	$self->{ARTICLE_START}	= '<LI>';
	$self->{ARTICLE_END}	= '</LI>';
	# Private instance variables
	$self->{ANCHORS}		= [];	# Array of 2-slot arrays where 0,1 == menu-text/anchor-name
	$self->{MENU}			= '';	# A fragment of HTML that is the menu: see method 'create_fragment'

	# Set/overwrite public slots with user's values
	foreach (keys %args) {	$self->{uc $_} = $args{$_} }
	# Useage failures
	warn "Please supply the 'HTML' parameter." and return undef unless exists $self->{HTML};
	warn "Please supply the 'TARGET' parameter list as an array!" and return undef unless exists $self->{TARGET};

    if (not ref $self->{HTML}) {
		local *IN;
		open IN, $self->{HTML} or warn "$class->new couldn't open input file <$self->{HTML}>" and return undef;
		read IN, $self->{HTML}, -s IN;
		close IN;
    }

	$self->{HTML} = ${$self->_anchorise};
	$self->create_fragment;

	return $self;
}



=head2 METHOD create_fragment

Sets and returns C<$self->{MENU}> - a fragment of HTML that is the menu of links which refers to the anchors embedded in the page by the constructor.

=cut

sub create_fragment { my $self = shift;
	$self->{MENU} = $self->{LIST_START};
	foreach (@{$self->{ANCHORS}}){
		$self->{MENU} .= $self->{ARTICLE_START}
					  .  '<A href="#' . $_->[1] . '">'
					  .  $_->[0]
					  .  '</A>';
	}
	$self->{MENU} .= $self->{LIST_START};
	return $self->{MENU};
}




=head2 PRIVATE METHOD _anchorise

Parses the document looking for elements to use as menu items: adds an anchor before each, and stores them internally for future use in building the menu.

Returns undef on failure, reference to scalar of adjusted HTML on success.

=cut

sub _anchorise { my $self = shift;
	warn "Usage: \$self->_anchorise requires \$self->{TARGET} to be set." and return undef unless exists $self->{TARGET};
	my $new_html = "";						# Our return value
	my $targets =  join ' ',@{$self->{TARGET}};
	my $p = new HTML::TokeParser(\$self->{HTML});
	my $token;
	my @targets_stack;

	while ($token = $p->get_token){
		if (@$token[0] eq 'S' and $targets=~/@$token[1]/i){
			push @targets_stack,@$token[1];		# Remember what we've found
		}
		elsif (@$token[0] eq 'E' and $targets=~/@$token[1]/i){
			pop @targets_stack; 				# Forget this token
		}

		if (@$token[0] eq 'T' and $#targets_stack>-1){
			$p->unget_token($token);
			my $text = $p->get_trimmed_text;
			my $escd = uri_escape($text);
			$new_html .= '<A name="'. $escd . '"></A>'."$text ";
			push @{$self->{ANCHORS}},[$text,$escd];
		}
		elsif (@$token[0] eq 'T'){				# Else just adds literal version of token
			$new_html .= $p->get_trimmed_text;
		}
		elsif (@$token[0] eq 'S') {
			$new_html .= @$token[4];
		}
		elsif (@$token[0] eq 'E') {
			$new_html .= @$token[2];
		}
		elsif (@$token[0] =~ /^[CD]$/) {
			$new_html .= @$token[1];
		}
		elsif (@$token[0] eq 'PI') {
			$new_html .= @$token[2];
		}
		else {
			die "Unexpected behaviour from HTML::TokeParser: unknown token object format!   ";
		}
	}
	return \$new_html;
}









1; # Return a true value for 'use'

=head1 TODO

=item *

Add a method to add to employ C<HTML::EasyTemplate?

=head1 SEE ALSO

L<HTML::EasyTemplate>
L<HTML::EasyTemplate::DirMenu>

=head1 AUTHOR

Lee Goddard (LGoddard@CPAN.org)

=head1 COPYRIGHT

Copyright 2000-2001 Lee Goddard.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

