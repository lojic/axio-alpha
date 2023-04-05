#lang racket/base

(require racket/contract)

(provide (contract-out
          [ axio-init-config
            (->* (axio-config?)
                 (#:db-config   (or/c axio-db-config?   #f)
                  #:smtp-config (or/c axio-smtp-config? #f))
                 any) ]
          [ get-axio-config           (-> axio-config?)      ]
          [ get-axio-db-config        (-> axio-db-config?)   ]
          [ get-axio-smtp-config      (-> axio-smtp-config?) ]
          [ get-axio-worker-custodian (-> custodian?)        ])
         (struct-out axio-config)
         (struct-out axio-db-config)
         (struct-out axio-smtp-config))

(struct axio-config (app-secret port-base params) #:transparent)

(struct axio-db-config (server username password database) #:transparent)

(struct axio-smtp-config (server port username password) #:transparent)

(define a-axio-config      #f)
(define a-axio-db-config   #f)
(define a-axio-smtp-config #f)

;; Create a custodian outside the scope of the web server to allow
;; worker threads to continue after the web server request has
;; completed.
(define axio-worker-custodian (make-custodian))

(define (axio-init-config config
                          #:db-config   [ db-config #f ]
                          #:smtp-config [ smtp-config #f ])
  (set! a-axio-config config)
  (set! a-axio-db-config db-config)
  (set! a-axio-smtp-config smtp-config))

(define (get-axio-config)           a-axio-config)
(define (get-axio-db-config)        a-axio-db-config)
(define (get-axio-smtp-config)      a-axio-smtp-config)
(define (get-axio-worker-custodian) axio-worker-custodian)
