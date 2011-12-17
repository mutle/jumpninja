#!/bin/bash

dst=~/Programming/github/mutle.github.com/ld22
cp -R *.{js,html,png} $dst/
cd $dst
git add .
git commit -a -v
git push origin master
