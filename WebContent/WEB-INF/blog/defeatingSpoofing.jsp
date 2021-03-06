<%@page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%-- These comments are to prevent excess whitespace in the output.
--%><%@page session="true"%><%--
--%><%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%><%--
--%><%@taglib prefix="common" tagdir="/WEB-INF/tags"%><%--
--%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Browserprint - Blog - Detecting and defeating browser spoofing</title>
<link type="text/css" href="../style.css" rel="stylesheet">
<style type="text/css">
th, td {
   	border-bottom: 1px solid #ddd;
   	border-right: 1px solid #ddd;
}
</style>
</head>
<body>
<common:header/>
<div id="content">
	<h2><a href="defeatingSpoofing">Detecting and defeating browser spoofing</a></h2>
	<h4>Posted: 2017-05-03<br/>
	By <a href="mailto:${initParam['devEmail']}?subject=Blog%20-%20Defeating%20spoofing">Lachlan Kang</a></h4>
	<p>
		Today we'll be discussing how Browserprint uses machine learning and your fingerprint to guess what browser family your browser is from, and what operating system you're using.
		The motivation for guessing these properties is to see if we can defeat fingerprint spoofing, particularly user-agent string spoofing, as this is simplest and most common form of spoofing.
		Because of this we ignored user-agent string when guessing browser families and operating systems, except when otherwise specified.
		We find that our method of browser guessing provides accuracy much better than random guessing.
		In fact we'll show that we can detect the true browser and operating system of a browser that is spoofing these things around 76% of the time,
		 and that we can guess the operating system and browser family of browsers in general approximately 90% of the time, all with a final training set of less than 1000 fingerprints (imagine what could be done with 10,000).
		Skip to <a href="#tab1">Table 1</a> and <a href="#tab2">Table 2</a> if you just want to see the raw results.
	</p>
	<p>
		The chance of a random guess being correct in our dataset around 43% when guessing browser, and 42% when guessing operating system, so these are the numbers to beat;
		 the reason these numbers are so high is because some browsers and operating systems appear far more in our dataset.
		We calculated these random guess accuracies by doing simulated random guessing 10,000,000 times and keeping a tally of how often guesses were correct.
		To simulate random guessing we essentially did two simulated spins of a roulette wheel, where each slice of the wheel represented a browser family or operating system and the slice's size was based on how many times they occurred;
		 if the two spins landed on the same slice then the guess was correct, otherwise it was wrong.
		To address possible anomalous results we repeated the simulated random guessing several times with different random number generator seeds to ensure that the results were consistent.
		Please note that this is just the chance of random guessing within our dataset,
		 other datasets may have different distributions of browsers and operating systems, leading to different random guess accuracy.
	</p>
	<h3>Methodology</h3>
	<p>
		To do the guessing we used machine learning; we started by converting the fingerprint into an optimal format, a numeric vector.
		This was not entirely necessary, we could have done learning on the raw strings, however doing it this way enabled us to consider fonts and accept headers individually (instead as a big blob of all fonts or headers),
		 and compare similarity of values instead of just matching or not matching (i.e. comparing weights of HTTP accept headers [See <a href="#fig1">Figure 1</a> for an example of this]). 
		A small handful of tests, such as the HTML5 canvas and the audio fingerprinting results were no included due to the fact that these are too complex to be useful for this and don't convert as easily to numbers.
		Other tests were excluded, such as whether ads are blocked, because their value depends on whether certain browser extensions are installed, like script blockers, which are operating system and browser independent,
		 and even more were excluded, such as time zone, because they're almost certainly browser and operating system independent<sup><a href="#footnote1">1</a></sup>.
	</p>
	<p>
		Most fingerprint features were simple to convert to numbers, for instance boolean values like those found in the supercookies test can be represented as a 1 or -1 (or 0 if scripts are disabled).
		Fonts converted easily into a bit array, where there's one bit per possible font and that bit represents the font's presence or absence.
		Accept headers similarly converted easily into an array, in this case of floating point numbers, one per possible header.
		A typical accept language header could be <tt>en-AU,en;q=0.7</tt>, where the <tt>q</tt> and number proceeding it is called the value's <i>relative quality factor</i>;
		 a higher relative quality factor for a language means that the client prefers that language more;
		 in the example accept language headers Australian English (<tt>en-AU</tt>) is most preferred (no quality is specified so it defaults to 1), and non-specific English (<tt>en</tt>) is second preference with a quality of 0.7.
		The accept header array's values are 0, if the header isn't present, and 1 + the relative quality factor if it is present.
		This means we not only guess based on whether headers are present, but also how preferred they are;
		 the reason we add 1 to the quality factor is so that all quality factors will be closer to every other possible quality factor than they are to 0, the number representing absence of the header.
	</p>
	<p>
		In our first effort we made use of all ~20,000 fingerprints in the dataset, getting browser family and OS from the user-agent string, labouring under the assumption that quantity was more important than quality (this was wrong).
		In an effort to keep this training and testing data clean, fingerprints from Tor users were of course excluded, as the Tor Browser Bundle is known to perform spoofing of both operating system and browser.
		We also excluded fingerprints from the operating system guessing training and testing data when the user-agent string matched that of IceCat;
		 the reason being that IceCat spoofs operating system details to appear as if it's running on a windows machine,
		 and that these fingerprints are numerous (it's tied with the Tor Browser Bundle as my favourite browser so I've submitted hundreds of fingerprints using it while testing Browserprint).
		When you submit your fingerprint on Browserprint there is an optional questionnaire where you can tell us useful information such as what family of browsers yours comes from and what operating system you're using.
		In our initial dataset where we were training using browser family and OS taken from the user-agent string.
		Fingerprints were excluded from the training set when the client indicated in the optional questionnaire that their browser was spoofing something.
		Fingerprints were excluded from training and testing when they didn't appear enough times to give us a decent training set; for instance Chrome OS only appeared 88 times in fingerprints, so these fingerprints were excluded from operating system guess training,
		 and the browser known as SeaMonkey only appeared in 11 fingerprints, so these fingerprints were excluded from browser guess training.
		The browser families we accepted were Opera, Firefox, Chrome, Safari, Edge, Internet Explorer, and the operating systems we accepted were Android, IOS, Linux, Mac operating systems, and Windows.
		In our dataset 844 users specified what browser they were using, 66 of those fingerprints had user-agent strings that didn't match the user-specified value meaning they were definitely spoofing browser family.
		Additionally 944 users specified what operating system they were using, from those 127 had user-agent string that didn't match the user-specified value meaning they were definitely spoofing OS.
		These provide small but valuable testing sets, and, despite what we originally thought, powerful training sets too.
		Additionally, since this data is not based on user-agent string, we don't need to exclude fingerprints from browsers that perform spoofing.
	</p>
	<p>
		To actually perform the machine learning we used software called Weka [<a href="#ref1">1</a>] which is developed by the machine learning group at the University of Waikato, New Zealand.
		Weka has a very convenient GUI that makes trying out new algorithms and getting accuracy measurements extremely easy, but the code on Browserprint that actually does the predictions is backed by the Weka API.
		We exhaustively searched through most learning algorithms, using 66% of data for training and the rest for testing, to find the one that both trains and performs prediction in a reasonable amount of time, and has the most accuracy.
		This was the RandomForest algorithm;
		 the RandomTree algorithm also performed comparatively well but with significantly less training time.
	</p>
	<p>
		A random forest algorithm works by choosing a number of random samples (with replacement) from the training data, then using each sample training a decision tree, in our case using the random tree algorithm.
		A decision tree in this context is a binary tree of yes or no questions (See <a href="#fig1">Figure 1</a>);
		 to use a decision tree you start at the top of the tree, answering each question until you work your way down to a leaf node, that leaf node representing the result.
		The result of the random forest algorithm is the class that appears most often in the outputs of the random trees.
	</p>
	<div>
		<a name="fig1"></a>
		<img src="../images/blog/decisionTree.png" alt="A very basic decision tree for guessing browser families based on an accept-language HTTP header."/>
	</div>
	<p>
		<b>Figure 1.</b> A simplified decision tree for guessing what a browser's real browser family actually is.
		You start at the top and work your way down until you hit a leaf, the leaf is the decision tree's guess.
		A more complex decision tree with many more levels, that considers nothing but the <tt>en</tt> accept-language accept header, can amazingly get an 88% guess accuracy when trying to guess the browser family in a fingerprint's user-agent string.
	</p>
	<h3>Results</h3>
	<p>
		Our first attempt at training involved using the whole database of fingerprints (minus the exclusions above), the results for that were as follows.
	</p>
	<p>
		Using the results of the RandomForest algorithm and the central limit theorem we know with 99% confidence that our browser guesses will match user-agent string 93% of the time give or take as much as 0.76%,
		 and our guess will match the user-agent string's operating system between 89% of the time give or take as much as 2.6%.
		Guessing to match what's in the user-agent string of course doesn't take into account the fact that user-agent strings might be spoofed, however, this gives a high level approximation to its accuracy, since spoofing is uncommon;
		 that being said it's not the only measure of accuracy we looked at or will discuss.
	</p>
	<p>
		Using only the accept-language <tt>en</tt> accept header we can get 88% accuracy guessing browser on the dataset as a whole (when trying to match user-agent string).
		This drops to 39% (slightly below random guess levels) when we consider only fingerprints that we are sure are spoofing, suggesting that people who spoof generally spoof more than just user-agent string.
	</p>
	<p>
		In addition to those results we found that when we trained using all the data we found that 96% of browser guesses were correct for fingerprints where the user had specified in the
		 optional questionnaire what their browser was, including fingerprints where they also said they were spoofing something,
		 and 91% when we only consider fingerprints which the user told us have something spoofed and also where the browser was specified.
		When we consider only fingerprints where the user specified browser doesn't match the user-agent string (where we know for sure either the browser is being spoofed or the user lied about what their browser is)
		 we can detect the spoofing 69% of the time (guess doesn't match user-agent string), and correctly guess the browser with an accuracy of 66%;
		 this is much better than random guessing (which has 43% accuracy) but far from perfect;
		 additionally the sample size in this case was only 66 fingerprints so true accuracy may vary.
	</p>
	<p>
		For OS guessing we found that our guess matched the user-specified operating system 85% of the time,
		 however, disappointingly (despite being more effective than randomly guessing), only 56% of the time for browsers (other than the Tor Browser Bundle) doing some sort of spoofing.
		When we considered only fingerprints where the user specified operating system didn't match the user-agent string we were able to detect spoofing (user-agent string didn't match our guess) 40% of the time,
		 and guess the OS correctly 33% of the time;
		 this is disappointing since it seems OS guessing using machine learning is 9% less accurate than randomly guessing OS (which has an accuracy of 42%);
		 the sample however was only 127 fingerprints so true accuracy may vary.
	</p>
	<p>
		In our second attempt at training we decided to try out training using only fingerprints where the user had specified their browser or OS.
		Initially we thought this was a bad idea because the dataset was so small (less than 1000 fingerprints), but we actually got much better results.
	</p>
	<p>	
		Doing leave-one-out cross-validation (LOOCV) on the 884 fingerprints where the user specified what their real browser is, and using RandomTree instead of RandomForest to avoid extremely long calculation times, we have an accuracy of 91% when guessing browser and trying to match user-specified browser.
		Using Wilson score intervals we can calculate that, with 99% confidence, this method will guess real browser correctly between 88% and 93% of the time.
		To get an approximation of how accurate our technique is when spoofing is occurring we used a modified version of LOOCV, where we train using the set of fingerprints where the user specified what their real browser is, minus one fingerprint where we know spoofing is occurring (user-specified browser didn't match user-agent browser).
		That excluded fingerprint is then used as the test set, and the final accuracy is the average correct guess rate when doing this for every spoofed fingerprint.
		This gave an accuracy of 77% for correctly guessing browser family when spoofing is definitely occurring.
		This is 11% greater accuracy than we got previously, and almost double the accuracy of random guessing.
		Again using Wilson score intervals we can calculate that, with 99% confidence, this method is between 62% and 88% accurate, a larger range of possible accuracies than before since the test set was much smaller.
		See <a href="#tab1">Table 1</a> for a summary of these results.
	</p>
	<div>
	<table>
		<a name="tab1"></a>
		<tr>
			<td></td>
			<th>Training with all data. Browser from user-agent string</th>
			<th>Training with data where the user specified their browser. Browser from what the user specified.</th>
		</tr>
		<tr>
			<th>Testing with all fingerprints, trying to match UA</th>
			<td>93%&dagger;</td>
			<td>88%</td>
		</tr>
		<tr>
			<th>Testing with fingerprints with user-specified browser*</th>
			<td>96%</td>
			<td>91%</td>
		</tr>
		<tr>
			<th>Testing with fingerprints with browser spoofing*&Dagger;</th>
			<td>66%</td>
			<td>77%</td>
		</tr>
	</table>
	&dagger; Data was split, 66% for training, 33% for testing.<br>
	* Training and testing using LOOCV.<br>
	&Dagger; Spoofing means fingerprints whose user-agent browser doesn't match user-specified browser.
	</div>
	<p>
		<b>Table 1.</b> Accuracy of guessing browser correctly using a variety of training and testing sets. 
	</p>
	<p>
		Doing LOOCV on the 944 fingerprints where the user specified what their real OS is, and using RandomTree instead of RandomForest to avoid extremely long calculation times, we have an accuracy of 90% when guessing OS and trying to match user-specified OS.
		Using Wilson score intervals we can calculate that, with 99% confidence, this method will guess real OS correctly between 87% and 92% of the time.
		To get an approximation of how accurate our technique is when spoofing is occurring we again used the modified version of LOOCV, but this time examining OS instead of browser.
		This gave an accuracy of 75% for correctly guessing operating system when spoofing is definitely occurring.
		This is over double the 33% accuracy we got previously, and almost double the accuracy of random guessing.
		Again using Wilson score intervals we can calculate that, with 99% confidence, this method is between 65% and 83% accurate, again, a larger range of possible accuracies than before since the test set was much smaller.
		<%--Additionally, using the set of fingerprints where the user-specified their OS as training data, and the entire dataset as testing data, trying to guess the OS in the fingerprint's user-agent string we get an accuracy of 84%.
		Using Wilson score intervals we can calculate that, with 99% confidence, our guess will match user-agent string OS between 83% and 85% of the time.--%>
		See <a href="#tab2">Table 2</a> for a summary of these results.
	</p>
	<div>
	<table>
		<a name="tab2"></a>
		<tr>
			<td></td>
			<th>Training with all data. OS from user-agent string</th>
			<th>Training with data where the user specified their OS. OS from what the user specified.</th>
		</tr>
		<tr>
			<th>Testing with all fingerprints, trying to match UA</th>
			<td>89%&dagger;</td>
			<td>84%</td>
		</tr>
		<tr>
			<th>Testing with fingerprints with user-specified OS*</th>
			<td>85%</td>
			<td>90%</td>
		</tr>
		<tr>
			<th>Testing with fingerprints with OS spoofing*&Dagger;</th>
			<td>33%</td>
			<td>75%</td>
		</tr>
	</table>
	&dagger; Data was split, 66% for training, 33% for testing.<br>
	* Training and testing using LOOCV.<br>
	&Dagger; Spoofing means fingerprints whose user-agent OS doesn't match user-specified OS.
	</div>
	<p>
		<b>Table 2.</b> Accuracy of guessing OS correctly using a variety of training and testing sets. 
	</p>
	<p>
		These drastic improvements in guessing what spoofed browsers and operating systems are is likely due to much greater purity in the training set, which is evidently extremely important for defeating spoofing, even if that means we have a lot less training data.
		These results are very encouraging, and present the question: how much would accuracy increase if that training set of approximately 1000 fingerprints was increased to 10,000 or even 100,000 fingerprints?
	</p>
	<h3>Conclusion</h3>
	<p>
		In conclusion, using machine learning it is very possible to defeat fingerprint spoofing and detect the true browser and operating system of a user.
		To do this successfully purity of training data is of the utmost of importance.
		You don't need a large training set (although I'm quite sure more data would result in greater accuracy) to get good results, a set of 1000 fingerprints can potentially get you up to 92% accuracy with spoofed fingerprints.
		Defeating spoofing 100% of the time is likely impossible without collecting every fingerprint from every user in the world and them filling out the questionnaire accurately every time,
		 but I'd be willing to bet that we can do it with 95% or even greater accuracy if we increase the training data by an order of magnitude.
	</p>
	<p>
		Future work could test the effectiveness of this technique against the Tor Browser Bundle, which is state of the art in spoofing and fingerprint defences.
		Sadly we do not have enough data to measure its effectiveness against the Tor Browser Bundle, as only 13 Tor users specified their OS, and 12 of those were from Linux machines (probably submitted by me);
		 predictably, when we used those fingerprints as a test set, 12 out of 13 OS guesses were ``Linux'', and the two non-Linux fingerprints were both guessed incorrectly,
		 this is probably due to severe lack of training data and lack of OS diversity in the data we do have.
	</p>
	<p>
		Other future work could involve guessing specific versions of browsers and OS, although getting the user to report their browser or OS version (which most people don't know off the top of their head) poses a problem;
		 potentially we could get around it by getting the version from the user-agent string, when the user-agent string matches the user-reported browser or OS family,
		 however this means we won't have any spoofed fingerprints in our training set, which is almost certainly detrimental to defeating spoofing;
		 another possibility is to create a browser extension that extracts all the information we want from the user's browser, however, convincing people to install a browser extension will likely be difficult.
	</p>
	<p>
		When we were selecting the machine learning algorithm to use we did so without much patience, terminating the algorithm before it could complete if it took longer than about half an hour to train and run;
		 in the future we could revisit this and see if any of the algorithms we terminated prematurely have superior performance.
	</p>
	<p>
		We could also look more closely at what features (and combinations of features) provide the most information and why.
		We can do feature selection for OS guessing to get the most useful 14 features, and we still get 90% accuracy when trying to guess user-specified OS; what is so revealing about these features and how can we stop them from being so revealing?
		Are there any features that are dead give-aways for spoofing?
		These are so questions we'd like to answer if we get more data, and they're questions that need to be answered if we're to develop more robust spoofing.
	</p>
	<p>
		We will likely repeat this experiment if we're able to get a large number of fingerprints where the user filled out the questionnaire, so please submit as many fingerprints as you can!
		Seeing if we can defeat the Tor Browser Bundle is a particularly exciting prospect!
	</p>
	<h3>Footnotes</h3>
	<ol>
		<li>
			<p>
				<a name="footnote1"></a>
				Technically time zone could be used in spoofing detection, since browsers like the Tor Browser Bundle set the time zone to UTC, however,
				 the bulk of the values will be useless and confusing, so we consider this feature too noisy to be useful.
				Perhaps it could be used if there was more training data, so the chance of over-fitting was lower.
			</p>
		</li>
	</ol>
	<h3>References</h3>
	<ol>
		<li><a name="ref1"></a>Machine Learning Group at the University of Waikato: Weka 3 - Data Mining with Open Source Machine Learning Software in Java. <a href="http://www.cs.waikato.ac.nz/ml/weka/">http://www.cs.waikato.ac.nz/ml/weka/</a> (2017). Accessed 2017-04-26</li>
	</ol>
</div>
<common:footer/>
</body>
</html>