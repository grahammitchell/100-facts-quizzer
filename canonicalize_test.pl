#!/usr/bin/perl -w

use My_Utils::Quizzer;

print canonicalize('( a >= 10 && b <= -12 )' ), "\n";
print canonicalize('(a>=10&&b<=-12)' ), "\n";

exit(0);

@a = ( '( a < 10 && b >= 12 )' );

foreach $a ( @a )
{
	$b = $a;
	$b =~ s/\s+//g;
	@s = space_combo($b);
	foreach $s ( @s )
	{
		if ( check_answers( $a, $s ) ) {
			$equiv{$a}{$s} = 1;
		} else {
			$diff{$a}{$s} = 1;
		}
	}
}

print "Equivalent expressions:\n";
foreach $a ( @a )
{
	print "To '$a':\n";
	foreach $s ( keys %{$equiv{$a}} )
	{
		print "\t'$s'\n";
	}
}
print "==============================================================\n";
print "Non-equivalent expressions:\n";
foreach $a ( @a )
{
	print "To '$a':\n";
	foreach $s ( keys %{$diff{$a}} )
	{
		print "\t'$s'\n";
	}
}

exit(0);


sub space_combo
{
	my $s = shift @_;

	my $n = length($s) + 1;
	my @chars = split('',$s);
	my ( $j, $k, $r, @results );
	foreach $i ( 0 .. ((2**$n)-1) )
	{
		$j = 1;
		$k = 0;
		$r = '';
		while ( $j < 2**$n )
		{
			$r .= (( $i & $j ) ? ' ' : '');
			$r .= $chars[$k] if ( defined $chars[$k] );
			$j*=2;
			$k++;
		}
		push @results, $r;
	}
	return @results;
}
