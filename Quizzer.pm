package My_Utils::Quizzer;

use strict;
use warnings;

use POSIX qw(ceil);
use My_Utils::Scripter;

my @parsed_lines = ();
my %pointers = ();
my @breakpoints = ();
my $num_questions = 0;
my $seed = undef;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT);

	# set the version for version checking
	$VERSION     = 1.00;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(
		&load_quiz
		&get_seed
		&display_all_questions_all_versions
		&choose_questions
		&choose_n_questions
		&choose_n_questions_in_range
		&get_num_questions
		&get_number_of_versions
		&get_random_version
		&get_question
		&display_question
		&get_answer
		&get_answer_length
		&check_answers
		&canonicalize
	);
}

=head1 NAME

functions to create a 100 Facts quiz.  Handles a question database with
different versions for each question, and a scripting language.  And
thus is suitable for testing not just facts but simple "skills".

=head1 SYNOPSIS

	use My_Utils::Quizzer;

	load_quiz('foo.qdb');
	@which_questions = choose_questions();
	foreach $q ( @which_questions )
	{
		$v = get_random_version($q);
		print get_question($q,$v);
		$answer = <STDIN>;
		$correct++ if ( check_answers( $answer, get_answer($q,$v) ) );
	}
	print "You got $correct questions right!\n";

=head1 DESCRIPTION

The C<is_dirty()> function returns the first dirty word found, or 0 if

=head1 AUTHOR AND COPYRIGHT

Graham Mitchell, 2004-07-26

Released under the terms of the GNU General Public License (GPL), or at
your option, the Artistic License.

=cut

# Program to generate random 100 Facts-type quizzes

# begun 2004-07-21
# substantially complete on 2004-07-24
# Scripter.pm functionality pulled out 2004-10-09

########################################################################
#              E X P O R T E D   S U B R O U T I N E S
########################################################################


sub load_quiz($;$)
{
	my $filename;
	( $filename, $seed ) = @_;
	$seed = int(rand 10000) if ( ! defined $seed );
	srand($seed);

	open FILE, "<$filename" or die "Unable to load quiz from \"$filename\": $!\n";
	my @raw_lines = <FILE>;
	close FILE;

	my $scripter = new My_Utils::Scripter;
	my @lines = $scripter->interpret(@raw_lines);

	my ( $line, $q, $v );
	$q=0;

	my $lineno = 0;
	while ( $_ = shift @lines )
	{
		# skip blank lines and comments
		next if ( m/^\s*$/ );
		next if ( m/^#/ );

		# trim leading and trailing whitespace and handle continuations
		&trim($_);
		if ( s/\\$// ) {	# ends in continuation backslash
			$_ .= shift @lines;
			redo; # as per the Camel book
		}
		$line = $_;

		# check for structural tags
		if ( $line =~ m/<QUESTION>/ ) {
			$q++;
			$v=0;
			$line =~ s/<QUESTION>//;
		}
		if ( $line =~ m/<\/QUESTION>/ ) {
			$line =~ s/<\/QUESTION>//;
		}
		if ( $line =~ m/<VERSION>/ ) {
			$line =~ s/<VERSION>//;
			$v++;
			$pointers{ $q }{ "V$v" } = $lineno;
		}
		if ( $line =~ m/<\/VERSION>/ ) {
			$line =~ s/<\/VERSION>//;
		}
		if ( $line =~ m/<ANSWER>/ ) {
			$line =~ s/<ANSWER>//;
			$pointers{ $q }{ "A$v" } = $lineno;
		}
		if ( $line =~ m/<\/ANSWER>/ ) {
			$line =~ s/<\/ANSWER>//;
		}
		if ( $line =~ m/<DONE>/ ) {
			$line =~ s/<DONE>//;
			$pointers{ $q+1 }{ 'DONE' } = $lineno;
		}

		next if ( $line =~ m/^\s*$/ );
		if ( $v == 0 ) {
			$v++;
			$pointers{ $q }{ "V$v" } = $lineno;
		}
		# re-trim and store the current line
		&trim($line);
		push @parsed_lines, $line;
		$lineno++;
	}

	@breakpoints = &find_breakpoints($lineno);
	$num_questions = $q;
}

sub get_seed()
{
	return $seed;
}

sub get_num_questions()
{
	return $num_questions;
}

sub display_all_questions_all_versions()
{
	# display all versions of all questions with answers
	#   for debugging
	for ( my $i=1; $i<=$num_questions; $i++ )
	{
		my $number_of_versions = ( scalar keys %{$pointers{ $i }} ) / 2;
		for ( my $j=1; $j<=$number_of_versions; $j++ )
		{
			print "Skill $i.$j\n";
			&display_question($i,$j);
			print "Answer: ", &get_answer($i,$j), "\n";
		}
	}
}


sub choose_questions()
{
	# passed in nothing;
	#   will choose the square root of the number of questions (rounded
	#   up), and select them from the entire range
	my $num_to_test = ceil( sqrt($num_questions) );
	return &choose_n_questions_in_range($num_to_test,1,$num_questions);
}

sub choose_n_questions($)
{
	my $n = shift @_;
	# passed in number of questions to select only
	return &choose_n_questions_in_range($n,1,$num_questions);
}

sub choose_n_questions_in_range($$$)
{
	my ( $n, $lo, $hi ) = @_;
	# passed in number of questions to select, first legal question number,
	#  and last legal question number.  Returns randomly-ordered array of
	#  question numbers in the given range

	# initialize "already chosen" lookup table
	my $i;
	my %chosen = ();
	for ( $i=$lo; $i<=$hi; $i++ )
	{
		$chosen{ $i } = 0;
	}

	# randomly choose
	my @chosen = ();
	for ( 1 .. $n )
	{
		do {
			$i = $lo + int( rand($hi-$lo+1) );
		} while ( $chosen{$i} == 1 );
		$chosen{$i} = 1;
		push @chosen, $i;
	}

	return @chosen;
}

sub get_number_of_versions($)
{
	my $q = shift @_;
	my $number_of_versions = ( scalar keys %{$pointers{ $q }} ) / 2;
	return $number_of_versions;
}

sub get_random_version($)
{
	my $q = shift @_;
	my $number_of_versions = ( scalar keys %{$pointers{ $q }} ) / 2;
	my $v = 1 + int( rand($number_of_versions) );
	return $v;
}

sub get_question($$)
{
	my ( $q, $v ) = @_;
	# passed in question number and version number
	my $start =  $pointers{ $q }{ "V$v" };
	my $end = &successor($start);

	my $question = '';
	for ( my $cur=$start; $cur < $end; $cur++ )
	{
		$question .= $parsed_lines[$cur] . "\n";
	}
	return $question;
}
	
sub display_question($$)
{
	my ( $q, $v ) = @_;
	# passed in question number and version number
	print &get_question($q,$v);
}

sub get_answer($$)
{
	my ( $q, $a ) = @_;
	# passed in question number and version number
	my $start =  $pointers{ $q }{ "A$a" };
	my $end = &successor($start);

	my $answer = '';
	for ( my $cur=$start; $cur < $end; $cur++ )
	{
		$answer .= $parsed_lines[$cur] . "\n";
	}
	return $answer;
}

sub get_answer_length($$)
{
	my ( $q, $a ) = @_;
	# passed in question number and version number
	my $start =  $pointers{ $q }{ "A$a" };
	my $end = &successor($start);
	return ( $end - $start );
}

sub check_answers($$)
{
	my ( $a, $b ) = @_;
	return 1 if ( &canonicalize($a) eq &canonicalize($b) );
	return 0;
}

sub canonicalize($)
{
	# tries to canonicalize a string by factoring out 
	#     syntactically-insignficant whitespace
	# probably buggy
	my $val = shift @_;
	chomp $val;

	# remove superfluous braces by counting intervening semicolons
	#    (but only if there are some braces and they're evenly paired)
	if ( $val =~ m/{/ && (nmatches($val,'{')==nmatches($val,'}')) )
	{
		my %brace_map = ();

		# make a map of brace pairs
		for ( my $i=0; $i<length($val); $i++ )
		{
			if ( substr($val,$i,1) eq '{' ) {
				my $j = find_match_for('{',$val,$i);
				$brace_map{ $i } = $j unless ( $j == -1 );
			} # else just ignore this char
		}

		# now count statements within each pair of braces
		foreach my $i ( sort { $b <=> $a } keys %brace_map )
		{
			my $j = $brace_map{$i}; # position of matching close brace
			my $n = $j - $i + 1; # number of characters in substring
			if ( count_statements( substr($val,$i,$n) ) == 1 )
			{
				# only one statement between these two braces;
				#  replace both the opening and closing brace with spaces
				substr($val,$i,1) = ' ';
				substr($val,$j,1) = ' ';
			}
		}
	}
		
	# put space at beginning & end, because these regexes don't handle
	#   operators which are right up against the end of the string
	$val = ' ' . $val . ' ';

	# special case: replace "+=1" with "++" and "-=1" with "--"
	$val =~ s/\+=\s*1(\D)/++$1/g;
	$val =~ s/-=\s*1(\D)/--$1/g;

	# special case: replace "][" with "] [" because multidimensional arrays
	#  want it
	$val =~ s/]\[/] [/g;
	# special case: ">-" goes to "> -", and ditto for "<-"
	$val =~ s/>-/> -/g;
	$val =~ s/<-/< -/g;
	$val =~ s/>=-/>= -/g;
	$val =~ s/<=-/<= -/g;

	my @ops = ( # order is significant (longer operators first)
		'++', '--', '<<', '>>', '==', '!=', '<=', '>=',
		'+=', '-=', '*=', '/=', '%=', '&&', '||',
		'(', ')', '[', ']', '->', '+', '-', '*', '/', '%',
		'!', '&', '<', '>', '=', ',', ';',
	);
	# separate tokens by putting # on either side of operators
	#   changes longer operators first, so 'x++' will become
	#   'x#++#' and not 'x#+#+#'
	foreach my $op ( @ops )
	{
		$val =~ s/([^#])(\Q$op\E)([^#])/$1#$2#$3/g;
	}

	$val =~ s/#/ /g;   # change '#' back to single spaces
	&trim($val);       # remove leading and trailing whitespace
	$val =~ s/\s+/ /g; # collapse multiple internal spaces

	return $val;
}


########################################################################
#              I N T E R N A L   S U B R O U T I N E S
########################################################################

sub find_breakpoints($)
{
	my $last_line = shift @_;

	my @breakpoints = ();
	foreach my $k ( sort { $a <=> $b } keys %pointers )
	{
		# print "Question $k:\n";
		foreach my $v ( sort { $pointers{$k}{$a} <=> $pointers{$k}{$b} }
			keys %{$pointers{ $k }} )
		{
			# print "\t$v: ", $pointers{ $k }{ $v }, "\n";
			push @breakpoints, $pointers{ $k }{ $v };
		}
	}
	push @breakpoints, $last_line;
	return @breakpoints;
}

sub successor($)
{
	my $n = shift @_;
	# find next number in @breakpoints array after $n
	#  returns undef if $n not found or is last item
	my $len = scalar @breakpoints;
	for ( my $i=0; $i<$len-1; $i++ ) {
		return $breakpoints[$i+1] if ( $breakpoints[$i] == $n );
	}
	return undef;
}

sub trim
{
	$_[0] =~ s/^\s+//g; # remove leading whitespace
	$_[0] =~ s/\s+$//g; # remove trailing whitespace
	return $_[0];
}

sub nmatches($$)
{
	my ( $haystack, $needle) = @_;
	my $pos = -1;
	my $n = 0;
	while (($pos =index($haystack, $needle, $pos)) > -1) {
		$pos++;
		$n++;
	}
	return $n;
}

sub find_match_for($$$)
{
	# find position of matching brace for $open in $s
	my ( $open, $s, $i ) = @_;
	#  precondition: $i is position of $open in $s
	#  returns -1 if not found

	my $close = ( $open eq '{' ) ? '}' :
		( $open eq '(' ) ? ')' :
		( $open eq '[' ) ? ']' : '^';
	my @stack = ();	
	my $pos = -1;

	for ( my $x=$i; $x<length($s); $x++ )
	{
		if ( substr($s,$x,1) eq $open ) {
			push @stack, $x;
		} elsif ( substr($s,$x,1) eq $close ) {
			last if ( (scalar @stack) == 0 ); # mismatched braces
			pop @stack;
			return $x if ( (scalar @stack) == 0 );
		} # else just ignore this char
	}

	return $pos;
}

sub find_end_of_string($$)
{
	# find position of close quote in $s
	my ( $s, $i ) = @_;
	#  precondition: $i is position of open quote in $s
	#  returns -1 if not found

	# first handle any quoted backslashes
	$s =~ s/\\\\/\$\$/g;	# replaces literal '\\' with '$$'
	# so we can handle any quoted double quotes
	$s =~ s/\\"/\$\$/g;		# replaces literal '\"' with '$$'

	# now, the next quotation mark we find should be it
	return index($s,'"',$i+1);
}

sub count_statements($)
{
	# counts the number of "statements" in $s.  Technically only counts
	#   the number of semicolons in $s, excluding those inside comments,
	#   those inside strings, those inside the "condition" of a for loop,
	#   and any character literals.  This should be close enough, though,
	#   to determine if a given pair of "{}" are optional, which is the
	#   whole idea.
	my $s = shift @_;
	my $i = -1;
	my ( $n, $j );

	# blank out potentially confusing character literals
	$s =~ s/'.'/' '/g;

	# blank out strings
	while ( $i < length($s) ) {
		$i = index($s,'"',$i);
		last if ( $i == -1 );
		$j = find_end_of_string($s,$i);
		last if ( $j == -1 );
		$n = $j - $i;
		substr($s,$i+1,$n) = ' ' x $n;
		$i = $j+1;
	}

	# remove C++-style comments
	$s =~ s#//.*$##g;

	# remove C-style comments
	$s =~ s#/\*.*\*/##ge;

	# blank out "condition" of for loops
	$s =~ s/(\W)for\s+\(/$1for(/g;
	$s =~ s/^for\s+\(/for(/g;
	$i = -1;
	while ( $i < length($s) ) {
		$i = index($s,'for(',$i);
		last if ( $i == -1 );
		$i += 3; # skip over "for" to the paren
		$j = find_match_for('(',$s,$i);
		last if ( $j == -1 );
		$n = $j - $i - 1;
		substr($s,$i+1,$n) = ' ' x $n;
		$i = $j+1;
	}

	# finally, all non-statement commas should be gone.  Just count 'em
	return nmatches($s,';');
}

1;   # don't forget to return a true value from the file
