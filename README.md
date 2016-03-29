FRC Match Stats
===
This is a quick little project to display the statistics of matches for FRC. A sample output looks something like what's below:
```
Highest Score:
	Rocket City Regional
	Semi Finals 1 Match 2
		Red:  118 16 3490	-- 214
		Blue: 2815 456 6158	-- 86

Highest Score (Minus Penalty Bonus):
	Sacramento Regional
	Semi Finals 1 Match 1
		Red:  1678 971 5274	-- 205
		Blue: 701 3669 5924	-- 86

Highest Penalty:
	MAR District - Seneca Event
	Quarter Finals 1 Match 2
		Red:  365 2590 1626	-- 15
		Blue: 5457 2600 5938	-- 50

Highest Teleoperated Score:
	Rocket City Regional
	Finals 1 Match 2
		Red:  118 16 3490	-- 164
		Blue: 364 4188 801	-- 103

Highest Autonomous Score:
	Rocket City Regional
	Qualifications Match 68
		Red:  6158 1466 3490	-- 14
		Blue: 34 118 624	-- 50

Highest Winning Margin:
	PNW District - Wilsonville Event
	Semi Finals 1 Match 2
		Red:  4488 1425 3711	-- 155
		Blue: 5468 1540 1510	-- 0
		Winning Margin: 155.0

Highest Winning Margin (only matches without a red card):
	Greater Toronto East Regional 
	Quarter Finals 1 Match 1
		Red:  118 2056 2634	-- 165
		Blue: 5031 4783 4343	-- 24
		Winning Margin: 141.0
```

Other files are also generated, including a full analysis of each match (a .json file containing data about the match including who's playing, where the match was and more score breakdowns), and a SQL
database containing data about all the matches.

## Usage
First, make sure you have the ruby gems installed:
```
gem install json sqlite3
```

Next, populate the database. You can do this whenever you want to update the database you're pulling match data from:
```
ruby populate.rb
```
Or, specify an event (or a few)
```
ruby populate.rb 2016ausy 2016alhu
```

By default, if the matches already have data in the database, they will be skipped. You can force them to be refetched by passing the `--force` flag.

  
  
Now we can begin the analysis.
```
ruby analyse.rb
```
Or, specify an event (or a few)
```
ruby analyse.rb 2016ausy 2016alhu
```
Or, specify a Team (or a few)
```
ruby analyse.rb 4788 5333 5663
```
Or, specify a combination!
```
ruby analyse.rb 5333 2016alhu
```

This will also output a few files, including `analysis.json` which contains more match data about each category, 
and `analysis.txt` which is a file output of the text seen in the console.