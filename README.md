# DB-state-watcher
Database state watcher

In this project I tried to get in my hand a tool, a mean, 
with help of this I'll be able to autimaticly recognise unusual and, at hte same time - bad state of watched-database;

The main idea was that: I know a usual (acceptable) and unusual (bad, not acceptable) state of the database - as marked array of awr-data.
It's array in file patternset.dat

This file, and data in there, I'd prepared by my hand before, as a result of the database incidents;
Rows in the file, which are related to some db-incidents, that is: which are related to unusual and bad db-state, I marked by value "1" in field "flag"
Other rows: have value "0" in that filed - which means: normal, usual state of the db;

There is another shell-script: "get_state_vector.sh" which gets current-state vector of the database;
So then it's just comparision of this vector with vectors (lines) in the array from the file "patternset.dat";
The nearest vector from the "patternset.dat" and it's flag gives information: to what state (usual and acceptable, or unusual and bad) should be attributed the db by is't current-state vector;
This is similar to the work of the kNN-algorithm.

The above comparison: is done by script classifier.py
But, here I do some additional calculation in the classifier.py
If current-state vector has nearest row (it's also vector), from "patternset.dat" data, which belongs to 0-marked class (normal state of the db) then I try to see: how close or far are these two vectors apart
I'm trying to compare the distance between these two vectors (current-state vector and the nearest row), 
with the distance between neighbors (also from 0-class) of the found nearest row.

In general, the tool works quite accurately. 
In technical terms, this is the crontab task:
*/5 * * * * <some directory>/watcher/watcher.sh 1><some directory>/watcher/run.log 2>&1

But I am not satisfied with the cost of the work of this tool:
1) I have to generate large enough array of hand-marked data (warm_cache.sh make_training_set.sh)
2) I have to keep up to date information in those array by constantly adding to this array new data on the bad-state of the DB, after newly occurring incidents

So I abandoned this project
