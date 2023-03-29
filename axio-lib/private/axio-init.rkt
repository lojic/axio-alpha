#lang racket/base

(require "./axio-database.rkt"
         "./axio-config.rkt"
         "./axio-init-structs.rkt"
         "./axio-logger.rkt")

(require db
         racket/contract)

(provide (contract-out
          [ axio-init
            (->* () (#:log-level symbol?) axio-context?) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (axio-init #:log-level [ log-level 'warning ])
  (axio-init-logger log-level)

  (build-axio-context (axio-init-db)))

;; --------------------------------------------------------------------------------------------
;; Private Implementation
;; --------------------------------------------------------------------------------------------

;; (axio-init-db) -> axio-db-context?
(define (axio-init-db)
  (virtual-connection
   (connection-pool (λ () (db-connect a-axio-db-config))
                    #:max-connections 30
                    #:max-idle-connections 4)))
