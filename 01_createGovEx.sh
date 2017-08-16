#!/bin/bash

createdb govex

psql govex -c 'CREATE EXTENSION postgis;'
