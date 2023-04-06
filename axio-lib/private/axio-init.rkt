#lang racket/base

(require "./axio-database.rkt"
         "./axio-config.rkt"
         "./axio-init-structs.rkt"
         "./axio-logger.rkt")

(require db
         racket/contract)

(provide (contract-out
          [ axio-init
            (->* (axio-config?)
                 (#:db-config   (or/c axio-db-config?   #f)
                  #:smtp-config (or/c axio-smtp-config? #f)
                  #:log-level   symbol?)
                 axio-context?) ]))

;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

(define (axio-init config
                   #:db-config   [ db-config #f ]
                   #:smtp-config [ smtp-config #f ]
                   #:log-level   [ log-level 'warning ])
  (axio-init-config config
                    #:db-config db-config
                    #:smtp-config smtp-config)
                    
  (axio-init-logger log-level)

  (build-axio-context (axio-init-db)))

;; --------------------------------------------------------------------------------------------
;; Private Implementation
;; --------------------------------------------------------------------------------------------

;; (axio-init-db) -> axio-db-context?
(define (axio-init-db)
  (virtual-connection
   (connection-pool (λ () (db-connect (get-axio-db-config)))
                    #:max-connections 30
                    #:max-idle-connections 4)))
