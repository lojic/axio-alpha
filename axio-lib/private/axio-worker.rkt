#lang racket/base

(require "./axio-config.rkt")

(require racket/contract)

(provide (contract-out
          [ axio-worker-thread (-> procedure? any) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (axio-worker-thread thunk)
  (parameterize ([ current-custodian axio-worker-custodian ])
    (thread thunk)))
