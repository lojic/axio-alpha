#lang info
(define collection "axio")
(define deps '("git://github.com/lojic/axio-alpha?path=axio-lib"
               "base"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/axio.scrbl" ())))
(define pkg-desc "Axio Web Framework")
(define version "0.0")
(define pkg-authors '(badkins))
(define license '(Apache-2.0 OR MIT))
