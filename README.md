# 100 Facts Quizzer

A Perl module(!) that I wrote in 2004 to give students randomized quizzes over
the web on Java syntax. Questions are based on flexible templates written in
a custom domain-specific language (DSL).

Note that this is eight years before CodeCademy got millions of dollars in
funding for doing the same thing.

Here's an example question template:

```
<QUESTION>
	$x=$choose(i,j,k,x,y,z,a,b,c,foo,bar,qwerty)
	$val=$irand(-20,20)
	$rel=$choose(<,>,<=,>=,==,!=)
	$desc=$choose_same(less than, greater than, less than or equal to, \
		greater than or equal to, equal to, not equal to)
	$desc2=$choose_same(under, over, at most, at least, the same as, \
		not the same as)
<DESCRIPTION>
	<P>Write a boolean expression using one variable.  The question will
	be of the form "...write an expression which is true when &lt;var&gt;
	is &lt;relation&gt; &lt;value&gt; and false otherwise."</P>

	<P>All variables will be integers.</P>

	<P>Variants:</P>
	<OL>
		<LI>Phrased with the words "less than", "greater than", "less than or
		equal to", "greater than or equal to", "equal to", or "not equal to".
		<LI>Phrased with more obscure words that mean the same thing:
		<TABLE CLASS=CENTERED BORDER>
		<TR><TD>"under"           <TD>&nbsp;instead of&nbsp; <TD>"less than"
		<TR><TD>"over"            <TD>&nbsp;instead of&nbsp; <TD>"greater than"
		<TR><TD>"at most"         <TD>&nbsp;instead of&nbsp; <TD>"less than or equal to"
		<TR><TD>"at least"        <TD>&nbsp;instead of&nbsp; <TD>"greater than or equal to"
		<TR><TD>"the same as"     <TD>&nbsp;instead of&nbsp; <TD>"equal to"
		<TR><TD>"not the same as" <TD>&nbsp;instead of&nbsp; <TD>"not equal to"
		</TABLE>
	</OL>

	<P>Examples:</P>

<PRE CLASS=CODE>
( qwerty <= -18 ) <B CLASS=c>// "...true when qwerty is at most -18 and false otherwise"</B>
( bar != 10 )     <B CLASS=c>// "...true when bar is not equal to 10 and false otherwise"</B>
</PRE>

	<P>Note that responses without the surrounding parentheses will be counted
	wrong.</P>
</DESCRIPTION>
<VERSION>
	<P>Write a boolean expression that is true when the variable
	<CODE>$x</CODE> is $desc $val and false otherwise.</P>
</VERSION>
<ANSWER>
	( $x $rel $val )
</ANSWER>
<VERSION>
	<P>Write a boolean expression that is true when the variable
	<CODE>$x</CODE> is $desc2 $val and false otherwise.</P>
</VERSION>
<ANSWER>
	( $x $rel $val )
</ANSWER>
</QUESTION>
```

Stuff inside the `<DESCRIPTION>` tags is HTML and shown to the students when
they're looking at the Study Guide. There's a preamble which randomly chooses
some identifiers and stores them into variables.

Then several `<VERSION>` blocks follow, each containing a different formulation
of the same essential question. Both the question and its answer get to use
the variables from the preamble.

The module canonicalizes their response to ignore syntactically-insignificant
whitespace and such like.

