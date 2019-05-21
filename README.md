Simulating NFL Play-Calling Strategies
--------------------------------------
In this post I’ll use simulation to test out different play-calling
strategies. Certain decisions are already clear like not running against
a stacked box–the EPA (expected points added) difference compared to
passing here is so high that teams should reduce the amount they run.
But in a situation like first down and 10, a long pass might have the
highest EPA there, but maybe there is value in taking a low risk, low
value play that will sustain a drive. I ran drive simulations to test
out these different strategies, and then I could see if the high EPA
and/or YPA play is the best choice. I got a lot of this code from [this
post](https://statsbylopez.netlify.com/post/resampling-nfl-drives/)
which was very helpful, and I made changes like creating game states and
some other things.

Part 1: Methodology: Simulating Drives
--------------------------------------

The data I am using is PBP data from 2011-2018, filtered to when the
game was within 1-score, &gt;=2 minutes before halftime and &gt;=5
minutes before the end of the game. I define game state below based on
down, yards-to-go, and yards-from-own-goal. Below are some of the
states:

<table class="table table-striped table-hover table-condensed table-responsive" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
State.ID
</th>
<th style="text-align:right;">
down
</th>
<th style="text-align:left;">
ydstogo.bin
</th>
<th style="text-align:left;">
yfog.bin
</th>
<th style="text-align:right;">
freq
</th>
<th style="text-align:right;">
percent.pass
</th>
<th style="text-align:right;">
percent.run
</th>
<th style="text-align:right;">
percent.punt
</th>
<th style="text-align:right;">
percent.field\_goal
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
5472
</td>
<td style="text-align:right;">
0.470
</td>
<td style="text-align:right;">
0.530
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
1090
</td>
<td style="text-align:right;">
0.544
</td>
<td style="text-align:right;">
0.456
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
292
</td>
<td style="text-align:right;">
0.935
</td>
<td style="text-align:right;">
0.065
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
136
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0.007
</td>
<td style="text-align:right;">
0.993
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
1-2
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
145
</td>
<td style="text-align:right;">
0.283
</td>
<td style="text-align:right;">
0.717
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
1-2
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
214
</td>
<td style="text-align:right;">
0.444
</td>
<td style="text-align:right;">
0.556
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
8
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
1-2
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
111
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0.027
</td>
<td style="text-align:right;">
0.973
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
9
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
3-6
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
39
</td>
<td style="text-align:right;">
0.333
</td>
<td style="text-align:right;">
0.667
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
3-6
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
1031
</td>
<td style="text-align:right;">
0.458
</td>
<td style="text-align:right;">
0.542
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
11
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
3-6
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
726
</td>
<td style="text-align:right;">
0.905
</td>
<td style="text-align:right;">
0.095
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
</tbody>
</table>
There are around 300 total states. Next, like in the post I linked
above, I simulate a drive by sampling from the data, sampling the play
result based on the state I am currently in. The drive stops when
there’s a touchdown, turnover,turnover-on-downs, field goal,field goal
miss, or safety. Below is an example of a simulated drive starting from
the 25:

<table class="table table-striped table-hover table-condensed table-responsive" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
down.original
</th>
<th style="text-align:right;">
yards.to.go
</th>
<th style="text-align:right;">
yards.from.own.goal
</th>
<th style="text-align:right;">
State.ID
</th>
<th style="text-align:left;">
desc
</th>
<th style="text-align:right;">
yards\_gained
</th>
<th style="text-align:right;">
new.down
</th>
<th style="text-align:right;">
new.distance
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
25
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;width: 30em; ">
(7:39) (Shotgun) J.Mixon up the middle to CIN 24 for 3 yards (J.Bosa).
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
7
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
28
</td>
<td style="text-align:right;">
358
</td>
<td style="text-align:left;width: 30em; ">
(2:57) (Shotgun) J.Ajayi right tackle to MIA 33 for 3 yards (C.Dunlap).
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
4
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
31
</td>
<td style="text-align:right;">
31
</td>
<td style="text-align:left;width: 30em; ">
(1:23) (Shotgun) E.Manning pass short middle to B.Pascoe to NYG 35 for 4
yards (J.Sanford).
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
10
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
35
</td>
<td style="text-align:right;">
21
</td>
<td style="text-align:left;width: 30em; ">
(:47) (Shotgun) R.Jennings up the middle to NYG 35 for 2 yards (A.Jones;
T.Smith).
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
8
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:right;">
37
</td>
<td style="text-align:right;">
58
</td>
<td style="text-align:left;width: 30em; ">
(14:21) (Shotgun) M.Vick pass incomplete short left to O.Schmitt
\[B.Poppinga\].
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
8
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
8
</td>
<td style="text-align:right;">
37
</td>
<td style="text-align:right;">
59
</td>
<td style="text-align:left;width: 30em; ">
(7:25) (Shotgun) M.Sanchez pass short left to L.Dunbar ran ob at DAL 48
for 9 yards.
</td>
<td style="text-align:right;">
9
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
10
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
10
</td>
<td style="text-align:right;">
46
</td>
<td style="text-align:right;">
241
</td>
<td style="text-align:left;width: 30em; ">
(12:28) S.Jackson left guard to CHI 49 for 3 yards (K.Greene).
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
7
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
7
</td>
<td style="text-align:right;">
49
</td>
<td style="text-align:right;">
258
</td>
<td style="text-align:left;width: 30em; ">
(4:27) (Shotgun) T.Brady pass deep middle to R.Gronkowski for 53 yards,
TOUCHDOWN. Caught at BUF 27.
</td>
<td style="text-align:right;">
53
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
</tr>
</tbody>
</table>
I repeat this to get 10,000 simulated drives starting from the 25 yard
line. I can now look at how these results line up to drives in the
actual data:

![](README_files/figure-markdown_strict/unnamed-chunk-4-1.png)

It lines up pretty well, the difference could be due to the fact that
the actual data includes penalties and my simulation doesn’t. Even if
there are differences, I’m mainly focusing on how strategies will
increase from my simulated baseline. Now that I have the baseline, I can
define any custom strategy I want and see how it changes the results.
For example, instead of the default state here:

<table class="table table-striped table-hover table-condensed table-responsive" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
State.ID
</th>
<th style="text-align:right;">
down
</th>
<th style="text-align:left;">
ydstogo.bin
</th>
<th style="text-align:left;">
yfog.bin
</th>
<th style="text-align:right;">
freq
</th>
<th style="text-align:right;">
percent.pass
</th>
<th style="text-align:right;">
percent.run
</th>
<th style="text-align:right;">
percent.punt
</th>
<th style="text-align:right;">
percent.field\_goal
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
5472
</td>
<td style="text-align:right;">
0.470
</td>
<td style="text-align:right;">
0.530
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
1090
</td>
<td style="text-align:right;">
0.544
</td>
<td style="text-align:right;">
0.456
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
292
</td>
<td style="text-align:right;">
0.935
</td>
<td style="text-align:right;">
0.065
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
136
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0.007
</td>
<td style="text-align:right;">
0.993
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
1-2
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
145
</td>
<td style="text-align:right;">
0.283
</td>
<td style="text-align:right;">
0.717
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
</tbody>
</table>
I can increase passes +10% on 1st-3rd downs:

<table class="table table-striped table-hover table-condensed table-responsive" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
State.ID
</th>
<th style="text-align:right;">
down
</th>
<th style="text-align:left;">
ydstogo.bin
</th>
<th style="text-align:left;">
yfog.bin
</th>
<th style="text-align:right;">
freq
</th>
<th style="text-align:right;">
percent.pass
</th>
<th style="text-align:right;">
percent.run
</th>
<th style="text-align:right;">
percent.punt
</th>
<th style="text-align:right;">
percent.field\_goal
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
5472
</td>
<td style="text-align:right;">
0.570
</td>
<td style="text-align:right;">
0.430
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
1090
</td>
<td style="text-align:right;">
0.644
</td>
<td style="text-align:right;">
0.356
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
292
</td>
<td style="text-align:right;">
1.000
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
136
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0.007
</td>
<td style="text-align:right;">
0.993
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
1-2
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
145
</td>
<td style="text-align:right;">
0.383
</td>
<td style="text-align:right;">
0.617
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
</tbody>
</table>
For example in state 1, I select a pass 57% of the time instead of 47%
of the time.. pretty simple. In R, I just do a weighted sample now. I
then rerun the 10K simulations for the new strategy.

Part 2: Methodology: Long and Short Passes
------------------------------------------

Before I test out different strategies, I wanted to account for one more
thing. I wanted to seperate short passes from long passes so that in a
strategy I can specify long or short pass. I define short as &lt;10
air-yard pass, and long as &gt;=10 air-yard pass. There’s evidence that
deep passes are where the real value is at, for example
[here](http://archive.advancedfootballanalytics.com/2010/09/deep-vs-short-passes.html)
so I wanted to include this.

The main problem here though which was mentioned in that link is that
sacks happen before a pass is attempted, so you don’t know whether it
should be attributed to short or long. I do have some way to handle this
though. First of all, if a state has 90% long passes and 10% short, then
sacks in that state should probably mostly be attributed as long pass
attempts. In addition, there is probably a different sack-rate for long
and short attempts. To calculate this, I aggregate long-passes,
short-passes, and sacks by state, then estimate how much a change in the
number of long or short passes in a state will increase the sack rate:

    ## 
    ## Call:
    ## lm(formula = percent.sack ~ scale(percent.short.pass) + scale(percent.long.pass) + 
    ##     as.factor(down), data = stateDF)
    ## 
    ## Residuals:
    ##       Min        1Q    Median        3Q       Max 
    ## -0.098511 -0.004485 -0.000258  0.005180  0.093534 
    ## 
    ## Coefficients:
    ##                           Estimate Std. Error t value             Pr(>|t|)
    ## (Intercept)               0.019224   0.002231   8.615 0.000000000000000257
    ## scale(percent.short.pass) 0.009591   0.001629   5.887 0.000000009372432572
    ## scale(percent.long.pass)  0.014963   0.001374  10.889 < 0.0000000000000002
    ## as.factor(down)2          0.002847   0.002904   0.980                0.328
    ## as.factor(down)3          0.031719   0.003361   9.437 < 0.0000000000000002
    ## as.factor(down)4          0.009418   0.003852   2.445                0.015
    ##                              
    ## (Intercept)               ***
    ## scale(percent.short.pass) ***
    ## scale(percent.long.pass)  ***
    ## as.factor(down)2             
    ## as.factor(down)3          ***
    ## as.factor(down)4          *  
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## Residual standard error: 0.01791 on 344 degrees of freedom
    ## Multiple R-squared:  0.7382, Adjusted R-squared:  0.7344 
    ## F-statistic:   194 on 5 and 344 DF,  p-value: < 0.00000000000000022

Based on this above model, I’m going to assume long passes have a sack
rate of 2x that of short passes. So for example, if a state had 30
short, 30 long and 12 sacks, I say 4 were short, 8 were long attempts.
This is just a way for me to attribute sacks, I think it is somewhat
reasonable. The 2x might be wrong but it is just a parameter that I can
experiment with to see how it affects the results. After attributing the
sacks I end up with this:

<table class="table table-striped table-hover table-condensed table-responsive" style="margin-left: auto; margin-right: auto;">
<thead>
<tr>
<th style="text-align:right;">
State.ID
</th>
<th style="text-align:right;">
down
</th>
<th style="text-align:left;">
ydstogo.bin
</th>
<th style="text-align:left;">
yfog.bin
</th>
<th style="text-align:right;">
freq
</th>
<th style="text-align:right;">
percent.short.pass
</th>
<th style="text-align:right;">
percent.long.pass
</th>
<th style="text-align:right;">
percent.run
</th>
<th style="text-align:right;">
percent.punt
</th>
<th style="text-align:right;">
percent.field\_goal
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
5472
</td>
<td style="text-align:right;">
0.306
</td>
<td style="text-align:right;">
0.163
</td>
<td style="text-align:right;">
0.530
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
1090
</td>
<td style="text-align:right;">
0.374
</td>
<td style="text-align:right;">
0.171
</td>
<td style="text-align:right;">
0.456
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
292
</td>
<td style="text-align:right;">
0.422
</td>
<td style="text-align:right;">
0.513
</td>
<td style="text-align:right;">
0.065
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
10-11
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
136
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0.007
</td>
<td style="text-align:right;">
0.993
</td>
<td style="text-align:right;">
0
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
1-2
</td>
<td style="text-align:left;">
(20,25\]
</td>
<td style="text-align:right;">
145
</td>
<td style="text-align:right;">
0.223
</td>
<td style="text-align:right;">
0.060
</td>
<td style="text-align:right;">
0.717
</td>
<td style="text-align:right;">
0.000
</td>
<td style="text-align:right;">
0
</td>
</tr>
</tbody>
</table>
I’m finally ready to test out several different strategies of increasing
long and/or short passes. Below I show the drive results of different
strategy parameters.

Part 3: Analyzing the Results
-----------------------------

![](README_files/figure-markdown_strict/unnamed-chunk-10-1.png)

Above I display the results from different parameters, ex:
x10longpass\_down1-2 means add 10% to long pass percentage on every
1-2nd down state. As you can see from the chart, the parameters that do
the best are long-pass. Adding +10% to first and second down increases
TD-rate and decreases punts. There’s countless strategies to try so I
just showed a few to keep it simple. This isn’t an exact science, and
I’ve noticed that the results vary even with 10K simulations. I’ll look
into different metrics and quantifying the error. The main takeaway is
that long passes definitely sem to increase TD’s and decrease punts from
the baseline “default\_part2”.

The last thing I’d like to look at is how these results are different to
just using EPA and/or YPA. From my simulated data which includes the
estimated sack-rate, I look at EPA and YPA below:

![](README_files/figure-markdown_strict/unnamed-chunk-11-1.png)![](README_files/figure-markdown_strict/unnamed-chunk-11-2.png)

My results line up well with EPA chart shown on the top right. On 1st
and second down you can see how long passes seem to have high expected
value, which is supported in my simulations. On third down, the effect
isn’t there as much, which I saw in my simulation as there was not
change when I added long passes to 3rd down. While YPA would suggest
long passes is best in all states, looking at EPA seems to provide
better guidance.

Part 4: Conclusion
------------------

In this post I showed my simulation method for testing different play
calling strategies. Long passes, despite their higher variance, seem to
improve the result of drives and lead to both more touchdowns and less
punts. Overall, my results align with “Expected Points Added” values,
which is cool because it confirms that EPA is a good guideline for play
selection, and it also suggests that my system isn’t completely off. I
was hoping to find a totally contrarian result here but it seems for now
that EPA does a good job of improving a drive. There are definitely some
shortcomings, for example, a team might be basing it’s play on what the
defense is giving, and that trying to increase deep passing by 10% will
greatly reduce it’s efficiency. For that reason I tried to keep the
changes small. I’d like to keep testing this to try out different
parameters such as different strategies or adding medium passes. Thanks
for reading.

[code](github.com/dlm1223/nfl-simulation)
