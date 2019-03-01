#!/bin/bash

function test1() { if [ ]; then return 0; else return 0; fi }

function test2() { if [ ]; then return; else return; fi }

function test3() { if [ ]; then return; fi; return; }

test1 && echo "TEST-1"
test2 && echo "TEST-2"
test3 && echo "TEST-3"
