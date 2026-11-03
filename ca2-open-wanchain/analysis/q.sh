#!/bin/bash
q(){ curl -sS -m 90 -X POST "https://api.koios.rest/api/v1/$1" -H 'Content-Type: application/json' -d "$2"; }
