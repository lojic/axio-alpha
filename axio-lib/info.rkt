#lang info
(define collection "axio")
(define deps '("db-lib"
               "net-cookies-lib"
               "net-lib"
               "web-server-lib"
               "gregor"
               "threading"
               "base"))
(define build-deps '("rackunit-lib"))
(define pkg-desc "Axio Web Framework Implementation")
(define version "0.0")
(define pkg-authors '(badkins))
(define license '(Apache-2.0 OR MIT))
