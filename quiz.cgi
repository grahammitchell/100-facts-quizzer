#!/usr/bin/perl -w

use strict;
use My_Utils::Quizzer;
use CGI;

my $query = new CGI;
my $seed = 0;
my $quizfile = 'java1.qdb';
my $url = $query->url(-relative=>1);

print <<'EOF'
Content-type: text/html

<HTML>
<HEAD>
	<STYLE TYPE="text/css">
	INPUT {
		font-family: monospace;
	}
	TABLE H1 {
		font-size: 48pt;
		font-weight: normal;
		padding-right: 30px;
	}
	TD.Y { background-color: #aaffaa; }
	TD.N { background-color: #ffaaaa; }
	PRE.USER SPAN { background-color: #cccccc; }
	TD.Y { background-color: #aaffaa; }
	TD.N { background-color: #ffaaaa; }
	</STYLE>
</HEAD>
<BODY>

<H1>Java Skills Quiz</H1>

EOF
;

if ( $query->param('grade') )
{
 	# time to grade
	my ( $q, $v, $c, $user_ans, $db_ans );
	$seed = $query->param('seed');
	load_quiz($quizfile,$seed);
	print "<FORM METHOD=GET ACTION=\"$url\">\n";
	print "<TABLE WIDTH=600>\n";
	foreach my $p ( $query->param )
	{
		next if ( $p !~ m/^Q/ );
		$p =~ m/^Q(\d+)_(\d+)$/;
		$q = $1;
		$v = $2;
		$user_ans = $query->param($p);
		$db_ans = get_answer($q,$v);
		$c = check_answers( $user_ans, $db_ans ) ? 'Y' : 'N';
		print "<TR><TD COLSPAN=2><HR>\n";
		print "<TR><TD ROWSPAN=2 CLASS=$c VALIGN=top><H1>$q</H1>";
		print "<TD>", get_question($q,$v), "\n";
		print "<TR><TD>";
		if ( $c eq 'Y' ) {
			print "<PRE CLASS=USER><SPAN>$user_ans</SPAN></PRE>\n";
			print "<P>&nbsp;&nbsp;&nbsp;&nbsp;Correct!</P>\n\n";
		} else {
			print "<TABLE WIDTH=100%>\n<TR><TD CLASS=N>You put:<TD>&nbsp;";
			print "<TD CLASS=Y>Correct answer:\n";
			print "\t<TR><TD CLASS=N>";
			print "<PRE>$user_ans</PRE>\n";
			print "\t\t<TD><TD CLASS=Y>";
			print "<PRE>$db_ans</PRE>\n";
			print "</TABLE>\n";
		}
	}

	print <<'EOF'
<TR><TD COLSPAN=2><HR>
<TR><TD COLSPAN=2 ALIGN=center><INPUT TYPE=submit VALUE="Again!">
EOF
;


}
else
{
	load_quiz($quizfile);
	my @which_questions = choose_questions();
	$seed = get_seed();

	print <<"EOF"
<FORM METHOD=POST ACTION="$url">
<INPUT TYPE=hidden NAME=grade VALUE=1>
<INPUT TYPE=hidden NAME=seed VALUE=$seed>
<TABLE WIDTH=600>
EOF
;
	foreach my $q ( @which_questions )
	{
		my $v = get_random_version($q);
		print "<TR><TD COLSPAN=2><HR>\n";
		print "<TR><TD ROWSPAN=2 VALIGN=top><H1>$q</H1>\n";
		print "<TD>", get_question($q,$v), "\n";
		my $n = get_answer_length($q,$v);
		my $a = get_answer($q,$v);
		print "<TR><TD>";
		if ( $n > 1 ) {
			print "<TEXTAREA NAME=Q$q\_$v COLS=60 ROWS=", $n, ">";
			print "</TEXTAREA>\n";
		} else {
			print "<TT><INPUT TYPE=text NAME=Q$q\_$v SIZE=60 VALUE=\"\"></TT>\n";
		}
		print "<PRE>\n\n</PRE>\n\n";
	}

	print <<'EOF'
<TR><TD COLSPAN=2><HR>
<TR><TD COLSPAN=2 ALIGN=center><INPUT TYPE=submit VALUE="Grade 'Em">
EOF
;

}

print <<'EOF'
</TABLE>
</FORM>
</BODY>
</HTML>
EOF
;


exit(0);

