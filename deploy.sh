#!/bin/bash

time_left=`curl 'http://www.ludumdare.com/compo/' 2>&1 | grep fergcorp_countdownTimer_event_time | head -n 1 | sed 's/^.*in \(.*seconds\).*/\1/'`

dst=~/Programming/github/mutle.github.com/ld22
cp -R *.{js,png} $dst/

title="\\<p\\>This is a work in progress, uploaded ${time_left} before the deadline.\\<\\/p\\>"

cat index.html | sed "s/\[TITLE\]/${title}/" > $dst/index.html
cd $dst

git add .
git commit -a -v
git push origin master
