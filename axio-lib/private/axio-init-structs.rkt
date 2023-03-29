#lang racket/base

(require db
         racket/contract)

(provide (contract-out
          [ build-axio-context
            (-> connection? axio-context?) ])
         (struct-out axio-context))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(struct axio-context (db-conn) #:transparent)

(define (build-axio-context db-conn)
  (axio-context db-conn))
