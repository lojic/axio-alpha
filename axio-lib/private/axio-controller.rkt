#lang racket/base

(require "./axio-session.rkt"
         "./axio-web-ctx.rkt")

(require racket/contract
         web-server/http
         web-server/http/bindings
         web-server/http/redirect)

(provide (contract-out
          [ axio-get-ip-address
            (-> request? string?) ]
          [ axio-redirect
            (->* (webctx? string?)
                 (redirection-status?
                  #:headers list?)
                 response?) ]))
;; --------------------------------------------------------------------------------------------
;; Public Interface
;; --------------------------------------------------------------------------------------------

;; Find the X-Forwarded-For nginx header, and if found, return the IP
;; address. It appears Racket's request-headers downcases the header
;; and converts it to a symbol.
(define (axio-get-ip-address req)
  (let ([ pair (assoc 'x-forwarded-for (request-headers req)) ])
    (if pair
        (cdr pair)
        "")))

(define (axio-redirect ctx
                       uri
                       [ status see-other ]
                       #:headers [ headers (list) ])

  (let* ([ headers (cons (cookie->header (create-session-cookie (webctx-session ctx)))
                         headers)  ])
    (redirect-to uri status #:headers headers)))
